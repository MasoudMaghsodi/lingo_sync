import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_sync/core/utils/map_utils.dart';
import 'package:lingo_sync/features/ai_dictionary/data/models/flashcard_entry_dto.dart';
import 'package:lingo_sync/features/ai_dictionary/data/models/video_analysis_dto.dart';
import 'package:lingo_sync/features/ai_dictionary/data/models/word_analysis_dto.dart';

void main() {
  group('MapUtils & Type Safety Tests', () {
    test('safeMap recursively converts untyped Map<dynamic, dynamic>', () {
      final dynamic untyped = <dynamic, dynamic>{
        'level1': <dynamic, dynamic>{
          'level2': <dynamic, dynamic>{'key': 'value'},
          'list': [
            <dynamic, dynamic>{'item': 123},
          ],
        },
      };

      final safe = safeMap(untyped);
      expect(safe, isA<Map<String, dynamic>>());
      expect(safe['level1'], isA<Map<String, dynamic>>());
      expect(safe['level1']['level2'], isA<Map<String, dynamic>>());
      expect(safe['level1']['level2']['key'], 'value');
      expect(safe['level1']['list'][0], isA<Map<String, dynamic>>());
      expect(safe['level1']['list'][0]['item'], 123);
    });

    test('FlashcardEntryDto.fromRow parses untyped Hive map safely without TypeError', () {
      final dynamic rawHiveRow = <dynamic, dynamic>{
        'id': 101,
        'user_id': 'user_123',
        'folder_name': 'General',
        'repetition': 3,
        'interval': 6,
        'ease_factor': 2.5,
        'next_review_date': '2026-10-30T10:00:00Z',
        'global_dictionary': <dynamic, dynamic>{
          'word': 'serendipity',
          'ai_analysis': <dynamic, dynamic>{
            'word': 'serendipity',
            'part_of_speech': 'noun',
            'english_meaning': 'Finding good things without looking for them.',
            'persian_meaning': 'خوش‌اقبالی غیرمنتظره',
            'examples': ['It was pure serendipity.'],
            'synonyms_by_level': <dynamic, dynamic>{
              'C1': <dynamic, dynamic>{'word': 'fluke', 'persian': 'شانس'},
            },
            'antonyms': [
              <dynamic, dynamic>{'word': 'misfortune', 'persian': 'بدبیاری'},
            ],
            'collocations': [
              <dynamic, dynamic>{'word': 'pure serendipity', 'persian': 'شانس محض'},
            ],
          },
        },
      };

      final flashcard = FlashcardEntryDto.fromRow(rawHiveRow);
      expect(flashcard.id, 101);
      expect(flashcard.word, 'serendipity');
      expect(flashcard.persianMeaning, 'خوش‌اقبالی غیرمنتظره');
      expect(flashcard.synonymsByLevel.containsKey('C1'), isTrue);
      expect(flashcard.synonymsByLevel['C1']?.word, 'fluke');

      final wordAnalysis = WordAnalysisDto.fromJson(rawHiveRow['global_dictionary']['ai_analysis']);
      expect(wordAnalysis.antonyms.first.word, 'misfortune');
      expect(wordAnalysis.collocations.first.word, 'pure serendipity');
    });

    test('VideoAnalysisDto parses full_transcript correctly for English tab', () {
      final dynamic rawJson = <dynamic, dynamic>{
        'video_id': 'q8tCETQ89X8',
        'summary': 'Summary of lesson',
        'full_transcript_translation': 'ترجمه فارسی کل متن',
        'full_transcript': 'This is the complete English transcript of the video.',
        'grammar_points': [
          <dynamic, dynamic>{
            'structure_name': 'Present Perfect',
            'persian_explanation': 'توضیح حال کامل',
            'example_from_transcript': 'I have lived here for 5 years.',
          },
        ],
        'vocabulary': [
          <dynamic, dynamic>{
            'word': 'crucial',
            'part_of_speech': 'adjective',
            'english_meaning': 'Extremely important',
            'persian_meaning': 'بسیار حیاتی',
          },
        ],
      };

      final analysis = VideoAnalysisDto.fromJson(rawJson);
      expect(analysis.videoId, 'q8tCETQ89X8');
      expect(analysis.englishTranscript, 'This is the complete English transcript of the video.');
      expect(analysis.fullTranscriptTranslation, 'ترجمه فارسی کل متن');
      expect(analysis.grammarPoints.length, 1);
      expect(analysis.vocabulary.first.word, 'crucial');
    });
  });
}
