import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/models/exam_attempt_model.dart';

abstract interface class IExamTwinRepository {
  Future<ExamEvaluation?> evaluateSpeaking({
    required String transcript,
    String examType = 'ielts_speaking',
    int partNumber = 1,
    int durationSeconds = 60,
    String? userId,
  });
}

class ExamTwinRepository implements IExamTwinRepository {
  final SupabaseClient _supabase;
  final http.Client _httpClient;

  ExamTwinRepository({SupabaseClient? supabase, http.Client? httpClient})
    : _supabase = supabase ?? Supabase.instance.client,
      _httpClient = httpClient ?? http.Client();

  @override
  Future<ExamEvaluation?> evaluateSpeaking({
    required String transcript,
    String examType = 'ielts_speaking',
    int partNumber = 1,
    int durationSeconds = 60,
    String? userId,
  }) async {
    if (transcript.trim().isEmpty) return null;

    try {
      final token = _supabase.auth.currentSession?.accessToken;
      final uri = Uri.parse(
        '${AppConfig.aiServerBaseUrl}/api/evaluate_exam_speaking',
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
          'transcript': transcript,
          'examType': examType,
          'partNumber': partNumber,
          'durationSeconds': durationSeconds,
          'userId': userId ?? _supabase.auth.currentUser?.id,
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final evalJson = body['evaluation'] as Map<String, dynamic>?;
        if (evalJson != null) {
          return ExamEvaluation.fromJson(evalJson);
        }
      } else {
        logger.warning(
          'evaluate_exam_speaking returned status ${response.statusCode}',
          context: 'ExamTwinRepository',
        );
      }
    } catch (e) {
      logger.warning(
        'Failed to evaluate speaking in Exam Twin: $e',
        context: 'ExamTwinRepository',
      );
    }
    return null;
  }
}
