import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/models/learner_error_entry.dart';

abstract interface class IErrorGenomeRepository {
  Future<List<LearnerErrorEntry>> fetchUserErrors(String userId);
  Future<List<LearnerErrorEntry>> analyzeText({
    required String text,
    String? userId,
    String source = 'text',
  });
}

class ErrorGenomeRepository implements IErrorGenomeRepository {
  final SupabaseClient _supabase;
  final http.Client _httpClient;

  ErrorGenomeRepository({SupabaseClient? supabase, http.Client? httpClient})
    : _supabase = supabase ?? Supabase.instance.client,
      _httpClient = httpClient ?? http.Client();

  @override
  Future<List<LearnerErrorEntry>> fetchUserErrors(String userId) async {
    try {
      final response = await _supabase
          .from('user_error_genome')
          .select()
          .eq('user_id', userId)
          .order('last_seen_at');

      final list = (response as List)
          .map((row) => LearnerErrorEntry.fromJson(row as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e) {
      logger.warning(
        'Failed to fetch user error genome from Supabase: $e',
        context: 'ErrorGenomeRepository',
      );
      return [];
    }
  }

  @override
  Future<List<LearnerErrorEntry>> analyzeText({
    required String text,
    String? userId,
    String source = 'text',
  }) async {
    if (text.trim().isEmpty) return [];

    try {
      final token = _supabase.auth.currentSession?.accessToken;
      final uri = Uri.parse(
        '${AppConfig.aiServerBaseUrl}/api/analyze_learner_errors',
      );

      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      } else {
        headers['x-secret-key'] = AppConfig.proxySecretKey;
      }

      final response = await _httpClient.post(
        uri,
        headers: headers,
        body: jsonEncode({
          'text': text,
          'userId': userId ?? _supabase.auth.currentUser?.id,
          'source': source,
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final rawErrors = body['errors'] as List? ?? [];
        return rawErrors
            .map((e) => LearnerErrorEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        logger.warning(
          'analyze_learner_errors returned status ${response.statusCode}',
          context: 'ErrorGenomeRepository',
        );
        return [];
      }
    } catch (e) {
      logger.warning(
        'Failed to analyze learner errors: $e',
        context: 'ErrorGenomeRepository',
      );
      return [];
    }
  }
}
