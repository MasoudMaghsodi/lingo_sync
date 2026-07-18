import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_sync/features/ai_dictionary/data/models/word_analysis_model.dart';

void main() {
  group('WordDetail', () {
    test('fromJson/toJson round-trips correctly', () {
      final detail = WordDetail.fromJson({
        'word': 'happy',
        'persian': 'خوشحال',
      });
      expect(detail.word, 'happy');
      expect(detail.persian, 'خوشحال');
      expect(detail.toJson(), {'word': 'happy', 'persian': 'خوشحال'});
    });
  });

  group('WordAnalysis', () {
    final sampleJson = {
      'word': 'resilient',
      'part_of_speech': 'adjective',
      'english_meaning': 'able to recover quickly',
      'persian_meaning': 'انعطاف‌پذیر',
      'examples': ['She is a resilient person.'],
      'synonyms_by_level': {
        'A1': {'word': 'strong', 'persian': 'قوی'},
        'B2': {'word': 'tough', 'persian': 'سخت‌جان'},
      },
      'antonyms': [
        {'word': 'fragile', 'persian': 'شکننده'},
      ],
      'collocations': [
        {'word': 'resilient economy', 'persian': 'اقتصاد مقاوم'},
      ],
    };

    test('fromJson parses every field, including nested maps/lists', () {
      final word = WordAnalysis.fromJson(sampleJson);

      expect(word.word, 'resilient');
      expect(word.partOfSpeech, 'adjective');
      expect(word.examples, ['She is a resilient person.']);
      expect(word.synonymsByLevel['A1']?.word, 'strong');
      expect(word.synonymsByLevel['B2']?.persian, 'سخت‌جان');
      expect(word.antonyms.single.word, 'fragile');
      expect(word.collocations.single.persian, 'اقتصاد مقاوم');
    });

    test('fromJson tolerates missing optional fields', () {
      final word = WordAnalysis.fromJson({'word': 'ok'});

      expect(word.word, 'ok');
      expect(word.partOfSpeech, '');
      expect(word.examples, isEmpty);
      expect(word.synonymsByLevel, isEmpty);
      expect(word.antonyms, isEmpty);
      expect(word.collocations, isEmpty);
    });

    test('fromJson skips empty synonym entries for a level', () {
      final word = WordAnalysis.fromJson({
        'word': 'test',
        'synonyms_by_level': {
          'A1': <String, dynamic>{},
          'B1': {'word': 'exam', 'persian': 'آزمون'},
        },
      });

      expect(word.synonymsByLevel.containsKey('A1'), isFalse);
      expect(word.synonymsByLevel['B1']?.word, 'exam');
    });

    test('toJson output can be fed back into fromJson unchanged', () {
      final original = WordAnalysis.fromJson(sampleJson);
      final roundTripped = WordAnalysis.fromJson(original.toJson());

      expect(roundTripped.word, original.word);
      expect(roundTripped.synonymsByLevel.keys, original.synonymsByLevel.keys);
      expect(
        roundTripped.antonyms.map((e) => e.word),
        original.antonyms.map((e) => e.word),
      );
    });
  });
}
