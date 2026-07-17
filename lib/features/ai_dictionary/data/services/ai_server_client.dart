import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:lingo_sync/core/config/app_config.dart';
import 'package:lingo_sync/core/exceptions/app_exceptions.dart';

part 'ai_server_client.g.dart';

@riverpod
AiServerClient aiServerClient(Ref ref) => AiServerClient();

/// Thin, shared HTTP client for the AI Express backend (word analysis,
/// video analysis). Centralizes URL building, JSON encoding, and defensive
/// error parsing so [WordRepository] and [VideoAnalysisRepository] don't
/// each reimplement the same request/error-handling logic — this is what
/// used to live duplicated inside the old God-object `DictionaryRepository`.
class AiServerClient {
  String get _baseUrl => AppConfig.aiServerBaseUrl;

  /// Reads an `{"error": "..."}` shaped body defensively — the AI server's
  /// error responses are always JSON, but proxies/timeouts can return HTML
  /// or an empty body, and this must never crash on `jsonDecode` in that
  /// case.
  String _extractServerErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] != null) {
        return decoded['error'].toString();
      }
    } catch (_) {
      // Body wasn't valid JSON — fall through to a generic message.
    }
    return 'AI server returned an unreadable error response.';
  }

  /// POSTs [body] as JSON to `$baseUrl$endpoint`. Connectivity failures
  /// (timeouts, DNS, socket errors) throw a retryable [NetworkException] —
  /// this is what lets `ErrorHandlerService.executeWithRetry` decide
  /// whether to retry. Non-2xx responses throw an [ApiException] (a
  /// business error from the AI server, e.g. an invalid word) and are
  /// deliberately NOT retryable.
  Future<http.Response> postJson(
    String endpoint,
    Map<String, dynamic> body, {
    required Duration timeout,
  }) async {
    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('$_baseUrl$endpoint'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(timeout);
    } on TimeoutException {
      throw NetworkException(
        'Request to $endpoint timed out',
        isRetryable: true,
      );
    } catch (e) {
      throw NetworkException(
        'Failed to reach AI server at $endpoint: $e',
        isRetryable: true,
      );
    }

    if (response.statusCode != 200) {
      throw ApiException(
        _extractServerErrorMessage(response.body),
        endpoint: endpoint,
        statusCode: response.statusCode,
      );
    }

    return response;
  }
}
