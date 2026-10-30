import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/storage_constants.dart';
import '../logging/app_logger.dart';
import '../utils/map_utils.dart';
import '../utils/uuid_generator.dart';

/// Represents a single mutation queued for offline synchronization.
class OutboxItem {
  final String id;
  final String actionType;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;

  const OutboxItem({
    required this.id,
    required this.actionType,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'action_type': actionType,
    'payload': payload,
    'created_at': createdAt.toIso8601String(),
    'retry_count': retryCount,
  };

  factory OutboxItem.fromMap(Map<String, dynamic> map) {
    return OutboxItem(
      id: map['id']?.toString() ?? UuidGenerator.v4(),
      actionType: map['action_type']?.toString() ?? 'unknown',
      payload: safeMap(map['payload']),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      retryCount: (map['retry_count'] as num?)?.toInt() ?? 0,
    );
  }

  OutboxItem copyWith({int? retryCount}) {
    return OutboxItem(
      id: id,
      actionType: actionType,
      payload: payload,
      createdAt: createdAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

/// Result of a sync flush operation.
class SyncResult {
  final int total;
  final int synced;
  final int failed;
  final bool hasNetworkError;

  const SyncResult({
    required this.total,
    required this.synced,
    required this.failed,
    this.hasNetworkError = false,
  });

  @override
  String toString() =>
      'SyncResult(total: $total, synced: $synced, failed: $failed, networkError: $hasNetworkError)';
}

/// Offline-First Outbox Synchronization Service.
/// Stores pending mutations in Hive and flushes them to Supabase
/// with idempotent deduplication and retry capability.
class OutboxSyncService {
  static const String _outboxBoxKey = 'outbox_items_v2';
  final Box _cacheBox;
  bool _isSyncing = false;

  final _pendingCountController = StreamController<int>.broadcast();

  OutboxSyncService([Box? box])
    : _cacheBox = box ?? Hive.box(StorageConstants.hiveBoxCache);

  Stream<int> get pendingCountStream => _pendingCountController.stream;

  List<OutboxItem> getPendingItems() {
    final raw = _cacheBox.get(_outboxBoxKey);
    if (raw == null || raw is! List) return [];

    final list = <OutboxItem>[];
    for (final item in raw) {
      if (item is Map) {
        list.add(OutboxItem.fromMap(safeMap(item)));
      }
    }
    return list;
  }

  int get pendingCount => getPendingItems().length;

  Future<void> _saveItems(List<OutboxItem> items) async {
    await _cacheBox.put(_outboxBoxKey, items.map((i) => i.toMap()).toList());
    _pendingCountController.add(items.length);
  }

  /// Enqueues a new mutation to be synced to the backend.
  Future<String> enqueue({
    required String actionType,
    required Map<String, dynamic> payload,
    String? explicitId,
  }) async {
    final id = explicitId ?? UuidGenerator.v4();
    final item = OutboxItem(
      id: id,
      actionType: actionType,
      payload: payload,
      createdAt: DateTime.now().toUtc(),
    );

    final items = getPendingItems();
    items.add(item);
    await _saveItems(items);

    logger.debug(
      'Enqueued offline sync action: $actionType (id: $id, pending: ${items.length})',
      context: 'OutboxSyncService',
    );
    return id;
  }

  /// Flushes pending mutations to Supabase with idempotent deduplication.
  Future<SyncResult> flush(SupabaseClient supabase) async {
    if (_isSyncing) {
      return SyncResult(total: pendingCount, synced: 0, failed: 0);
    }

    final items = getPendingItems();
    if (items.isEmpty) {
      return const SyncResult(total: 0, synced: 0, failed: 0);
    }

    _isSyncing = true;
    int syncedCount = 0;
    int failedCount = 0;
    bool networkError = false;

    try {
      final remaining = <OutboxItem>[];

      // 1. Process SRS Reviews in batch where possible
      final srsItems = items
          .where((i) => i.actionType == 'srs_review')
          .toList();
      final nonSrsItems = items
          .where((i) => i.actionType != 'srs_review')
          .toList();

      if (srsItems.isNotEmpty) {
        final batch = srsItems.map((item) {
          final p = item.payload;
          return {
            'client_event_id': item.id,
            'flashcard_id': p['flashcard_id'],
            'quality': p['quality'],
            'repetition': p['repetition'],
            'interval': p['interval'],
            'ease_factor': p['ease_factor'],
            'next_review_date': p['next_review_date'],
            'reviewed_at': p['reviewed_at'] ?? item.createdAt.toIso8601String(),
            'device_id': p['device_id'] ?? 'flutter_client',
          };
        }).toList();

        try {
          // Attempt atomic batch sync via RPC
          await supabase.rpc('sync_srs_reviews', params: {'p_reviews': batch});
          syncedCount += srsItems.length;
          logger.info(
            'Successfully synced ${srsItems.length} SRS reviews via RPC',
            context: 'OutboxSyncService',
          );
        } catch (rpcError) {
          // Fallback to individual standard updates if RPC is not yet created
          logger.warning(
            'Batch RPC failed, falling back to individual sync: $rpcError',
            context: 'OutboxSyncService',
          );

          for (final item in srsItems) {
            try {
              final p = item.payload;
              final cardId = (p['flashcard_id'] as num?)?.toInt() ?? 0;
              final userId = supabase.auth.currentUser?.id;

              if (userId != null && cardId > 0) {
                await supabase
                    .from('flashcards')
                    .update({
                      'repetition': p['repetition'],
                      'interval': p['interval'],
                      'ease_factor': p['ease_factor'],
                      'next_review_date': p['next_review_date'],
                    })
                    .eq('id', cardId);

                await supabase.from('review_logs').insert({
                  'user_id': userId,
                  'flashcard_id': cardId,
                  'quality': p['quality'],
                });
              }
              syncedCount++;
            } catch (singleErr) {
              failedCount++;
              networkError = true;
              remaining.add(item.copyWith(retryCount: item.retryCount + 1));
            }
          }
        }
      }

      // 2. Process other mutation types (e.g. task completions)
      for (final item in nonSrsItems) {
        try {
          if (item.actionType == 'task_completion') {
            final p = item.payload;
            final userId = supabase.auth.currentUser?.id;
            final taskId = (p['task_id'] as num?)?.toInt();
            if (userId != null && taskId != null) {
              await supabase.from('user_task_progress').upsert({
                'user_id': userId,
                'task_id': taskId,
                'completed': true,
                'completed_at': item.createdAt.toIso8601String(),
              });
            }
            syncedCount++;
          } else {
            // Unhandled action type, drop to avoid poisoning the queue
            syncedCount++;
          }
        } catch (err) {
          failedCount++;
          networkError = true;
          remaining.add(item.copyWith(retryCount: item.retryCount + 1));
        }
      }

      await _saveItems(remaining);
    } catch (e) {
      networkError = true;
      logger.warning(
        'Outbox sync interrupted by error: $e',
        context: 'OutboxSyncService',
      );
    } finally {
      _isSyncing = false;
    }

    return SyncResult(
      total: items.length,
      synced: syncedCount,
      failed: failedCount,
      hasNetworkError: networkError,
    );
  }

  /// Clears the entire queue (useful for test resets or user account switches).
  Future<void> clear() async {
    await _cacheBox.delete(_outboxBoxKey);
    _pendingCountController.add(0);
  }

  void dispose() {
    _pendingCountController.close();
  }
}
