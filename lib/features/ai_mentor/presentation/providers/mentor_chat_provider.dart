import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../ai_dictionary/data/services/ai_server_client.dart';

class MentorChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const MentorChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, String> toHistoryMap() => {
    'role': isUser ? 'user' : 'model',
    'content': text,
  };
}

class CouncilResult {
  final String consensus;
  final String grammar;
  final String pragmatic;

  const CouncilResult({
    required this.consensus,
    required this.grammar,
    required this.pragmatic,
  });
}

class MentorChatState {
  final List<MentorChatMessage> messages;
  final bool isLoading;
  final String? errorMessage;
  final CouncilResult? councilResult;
  final bool isLoadingCouncil;
  final String? councilError;

  const MentorChatState({
    this.messages = const [],
    this.isLoading = false,
    this.errorMessage,
    this.councilResult,
    this.isLoadingCouncil = false,
    this.councilError,
  });

  MentorChatState copyWith({
    List<MentorChatMessage>? messages,
    bool? isLoading,
    String? errorMessage,
    CouncilResult? councilResult,
    bool? isLoadingCouncil,
    String? councilError,
  }) {
    return MentorChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      councilResult: councilResult ?? this.councilResult,
      isLoadingCouncil: isLoadingCouncil ?? this.isLoadingCouncil,
      councilError: councilError,
    );
  }
}

class MentorChatNotifier extends Notifier<MentorChatState> {
  @override
  MentorChatState build() {
    return MentorChatState(
      messages: [
        MentorChatMessage(
          id: 'welcome',
          text:
              'سلام قهرمان! من منتور و مربی آموزشی اختصاصی تو هستم. '
              'به پیشرفتت، تسک‌های امروز و لایتنرت دسترسی دارم. '
              'چه سوالی داری؟ می‌تونی از پیشنهادهای پایین هم استفاده کنی!',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ],
    );
  }

  AiServerClient get _aiClient => ref.read(aiServerClientProvider);

  Future<void> sendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty) return;

    final userMsg = MentorChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: query,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final currentMessages = List<MentorChatMessage>.from(state.messages)
      ..add(userMsg);
    state = state.copyWith(messages: currentMessages, isLoading: true);

    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      final history = currentMessages
          .map((m) => m.toHistoryMap())
          .take(10)
          .toList();

      final response = await _aiClient.postJson('/mentor_chat', {
        'message': query,
        'history': history,
        'userId': currentUserId,
      }, timeout: const Duration(seconds: 35));

      final data = jsonDecode(response.body);
      final replyText = data['reply'] as String? ?? 'پاسخی از مربی دریافت نشد.';

      final aiMsg = MentorChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: replyText,
        isUser: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: List<MentorChatMessage>.from(state.messages)..add(aiMsg),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'خطا در برقراری ارتباط با مربی: $e',
      );
    }
  }

  Future<void> askCouncil(String question, {String context = ''}) async {
    final query = question.trim();
    if (query.isEmpty) return;

    state = state.copyWith(isLoadingCouncil: true);

    try {
      final response = await _aiClient.postJson('/multi_agent_consensus', {
        'question': query,
        'context': context,
      }, timeout: const Duration(seconds: 60));

      final data = jsonDecode(response.body);
      final consensus = data['consensus'] as String? ?? '';
      final perspectives = data['perspectives'] as Map<String, dynamic>? ?? {};
      final grammar = perspectives['grammar'] as String? ?? '';
      final pragmatic = perspectives['pragmatic'] as String? ?? '';

      state = state.copyWith(
        isLoadingCouncil: false,
        councilResult: CouncilResult(
          consensus: consensus,
          grammar: grammar,
          pragmatic: pragmatic,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingCouncil: false,
        councilError: 'خطا در جمع‌بندی شورای اساتید: $e',
      );
    }
  }

  void clearChat() {
    state = const MentorChatState();
  }
}

final mentorChatProvider =
    NotifierProvider<MentorChatNotifier, MentorChatState>(
      MentorChatNotifier.new,
    );
