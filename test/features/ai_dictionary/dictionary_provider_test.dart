import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_sync/core/exceptions/app_exceptions.dart';
import 'package:lingo_sync/core/result/result.dart';
import 'package:lingo_sync/features/ai_dictionary/data/models/word_analysis_model.dart';
import 'package:lingo_sync/features/ai_dictionary/data/repositories/word_repository.dart';
import 'package:lingo_sync/features/ai_dictionary/presentation/providers/dictionary_provider.dart';
import 'package:mocktail/mocktail.dart';

// 🚀 ساخت یک دیتابیس تقلبی (Mock)
class MockWordRepository extends Mock implements WordRepository {}

void main() {
  late MockWordRepository mockRepository;

  setUp(() {
    mockRepository = MockWordRepository();
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [wordRepositoryProvider.overrideWithValue(mockRepository)],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('DictionaryProvider', () {
    test('analyzeWord updates state to data on success', () async {
      final container = makeContainer();
      final mockWord = WordAnalysis(
        word: 'test',
        partOfSpeech: 'noun',
        englishMeaning: 'a procedure',
        persianMeaning: 'آزمون',
        examples: [],
        synonymsByLevel: {},
        antonyms: [],
        collocations: [],
      );

      when(
        () => mockRepository.fetchWordAnalysis('test'),
      ).thenAnswer((_) async => Result.success(mockWord));

      final provider = dictionaryProvider.notifier;

      // حالت اولیه باید null باشد
      expect(container.read(dictionaryProvider).value, isNull);

      // اجرای متد
      await container.read(provider).analyzeWord('test');

      // بررسی آپدیت شدن State با دیتای موفق
      expect(container.read(dictionaryProvider).value, equals(mockWord));
      verify(() => mockRepository.fetchWordAnalysis('test')).called(1);
    });

    test('analyzeWord updates state to error on failure', () async {
      final container = makeContainer();
      const mockException = NetworkException('No internet');

      when(
        () => mockRepository.fetchWordAnalysis('fail'),
      ).thenAnswer((_) async => Result.failure(mockException));

      await container.read(dictionaryProvider.notifier).analyzeWord('fail');

      // بررسی هندل شدن ارور در استیتِ ریورپاد
      expect(container.read(dictionaryProvider).hasError, isTrue);
      expect(container.read(dictionaryProvider).error, isA<NetworkException>());
    });
  });
}
