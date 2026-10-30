import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingo_sync/core/exceptions/app_exceptions.dart';
import 'package:lingo_sync/core/result/result.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../domain/entities/word_analysis.dart';
import '../../domain/repositories/i_word_repository.dart';
import '../repositories/word_repository_impl.dart';

class AnkiCardItem {
  final String word;
  final String meaning;
  final String example;
  final String phonetic;
  final String folder;

  const AnkiCardItem({
    required this.word,
    required this.meaning,
    this.example = '',
    this.phonetic = '',
    this.folder = 'Anki Import',
  });
}

class AnkiImportService {
  final IWordRepository _wordRepository;
  final SupabaseClient _supabase;

  AnkiImportService(this._wordRepository, this._supabase);

  /// Strips HTML tags commonly found in Anki fields (e.g. <br>, <div>, <span>)
  String _cleanHtml(String text) {
    return text
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  /// Parses TSV / CSV / Text representation of Anki flashcards
  List<AnkiCardItem> parseDelimitedText(
    String content, {
    String folder = 'Anki Import',
  }) {
    final lines = LineSplitter.split(content).toList();
    final items = <AnkiCardItem>[];

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) continue;

      List<String> parts;
      if (line.contains('\t')) {
        parts = line.split('\t');
      } else if (line.contains(';')) {
        parts = line.split(';');
      } else if (line.contains(' - ')) {
        parts = line.split(' - ');
      } else if (line.contains(',')) {
        parts = line.split(',');
      } else {
        continue;
      }

      if (parts.length < 2) continue;

      final word = _cleanHtml(parts[0]);
      final meaning = _cleanHtml(parts[1]);
      final example = parts.length > 2 ? _cleanHtml(parts[2]) : '';
      final phonetic = parts.length > 3 ? _cleanHtml(parts[3]) : '';

      if (word.isNotEmpty && meaning.isNotEmpty) {
        items.add(
          AnkiCardItem(
            word: word,
            meaning: meaning,
            example: example,
            phonetic: phonetic,
            folder: folder,
          ),
        );
      }
    }

    return items;
  }

  /// Loads bundled curated deck (Collins 500, 1100 Words, or 620 Sentences)
  Future<List<AnkiCardItem>> loadBundledDeck(
    String assetPath, {
    required String folder,
  }) async {
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final list = jsonDecode(jsonString) as List<dynamic>;

      return list.map((item) {
        final map = item as Map<String, dynamic>;
        final word = map['word'] as String? ?? map['sentence'] as String? ?? '';
        final meaning = map['translation'] as String? ?? '';
        final example =
            map['example'] as String? ?? map['category'] as String? ?? '';
        final phonetic = map['phonetic'] as String? ?? '';

        return AnkiCardItem(
          word: word,
          meaning: meaning,
          example: example,
          phonetic: phonetic,
          folder: folder,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Batch imports parsed Anki cards into the user's personal flashcards
  Future<Result<int>> importCards(List<AnkiCardItem> cards) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return Result<int>.failure(
        const AuthException(
          'User not authenticated',
          code: 'not_authenticated',
        ),
      );
    }

    if (cards.isEmpty) {
      return Result<int>.success(0);
    }

    int successCount = 0;

    for (final card in cards) {
      try {
        final wordAnalysis = WordAnalysis(
          word: card.word,
          partOfSpeech: 'expression',
          englishMeaning: card.meaning,
          persianMeaning: card.meaning,
          examples: card.example.isNotEmpty
              ? [card.example]
              : ['Vocabulary item from Anki collection.'],
          synonymsByLevel: const {},
          antonyms: const [],
          collocations: const [],
        );

        final res = await _wordRepository.saveToPersonalFlashcards(
          wordAnalysis,
          folder: card.folder,
        );

        if (res is Success) {
          successCount++;
        }
      } catch (_) {
        // Continue importing remaining cards
      }
    }

    return Result<int>.success(successCount);
  }
}

final ankiImportServiceProvider = Provider<AnkiImportService>((ref) {
  final repo = ref.watch(wordRepositoryProvider);
  return AnkiImportService(repo, Supabase.instance.client);
});
