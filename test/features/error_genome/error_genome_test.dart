import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_sync/features/error_genome/domain/models/learner_error_entry.dart';

void main() {
  group('LearnerErrorEntry Tests', () {
    test('fromJson parses correctly with full fields', () {
      final json = {
        'id': 'err-123',
        'category': 'preposition_interference',
        'verbatim_quote': 'depends to',
        'corrected_version': 'depends on',
        'explanation_fa': 'استفاده از on به جای to',
        'confidence': 0.95,
        'l1_interference_flag': true,
        'remediation_stage': 2,
        'occurrence_count': 3,
        'last_seen_at': '2026-10-30T02:00:00Z',
      };

      final entry = LearnerErrorEntry.fromJson(json);

      expect(entry.id, equals('err-123'));
      expect(entry.category, equals('preposition_interference'));
      expect(entry.verbatimQuote, equals('depends to'));
      expect(entry.correctedVersion, equals('depends on'));
      expect(entry.confidence, equals(0.95));
      expect(entry.l1InterferenceFlag, isTrue);
      expect(entry.remediationStage, equals(2));
      expect(entry.occurrenceCount, equals(3));
      expect(entry.lastSeenAt, isNotNull);
    });

    test('toJson produces expected structure', () {
      const entry = LearnerErrorEntry(
        id: 'err-456',
        category: 'copula_redundancy',
        verbatimQuote: 'I am agree',
        correctedVersion: 'I agree',
        explanationFa: 'agree فعل است',
        confidence: 0.88,
      );

      final json = entry.toJson();

      expect(json['id'], equals('err-456'));
      expect(json['category'], equals('copula_redundancy'));
      expect(json['verbatim_quote'], equals('I am agree'));
      expect(json['corrected_version'], equals('I agree'));
      expect(json['confidence'], equals(0.88));
      expect(json['l1_interference_flag'], isTrue);
    });
  });
}
