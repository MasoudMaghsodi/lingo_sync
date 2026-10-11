import '../../domain/entities/word_analysis.dart';

class WordDetailDto {
  static WordDetail fromJson(Map<String, dynamic> json) {
    return WordDetail(word: json['word'] ?? '', persian: json['persian'] ?? '');
  }

  static Map<String, dynamic> toJson(WordDetail domain) {
    return {'word': domain.word, 'persian': domain.persian};
  }
}

class WordAnalysisDto {
  static WordAnalysis fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> synJson = json['synonyms_by_level'] ?? {};
    final Map<String, WordDetail> parsedSynonyms = {};

    synJson.forEach((key, value) {
      if (value is Map<String, dynamic> && value.isNotEmpty) {
        parsedSynonyms[key] = WordDetailDto.fromJson(value);
      }
    });

    return WordAnalysis(
      word: json['word'] ?? '',
      partOfSpeech: json['part_of_speech'] ?? '',
      englishMeaning: json['english_meaning'] ?? '',
      persianMeaning: json['persian_meaning'] ?? '',
      examples: List<String>.from(json['examples'] ?? []),
      synonymsByLevel: parsedSynonyms,
      antonyms:
          (json['antonyms'] as List<dynamic>?)
              ?.map((e) => WordDetailDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      collocations:
          (json['collocations'] as List<dynamic>?)
              ?.map((e) => WordDetailDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static Map<String, dynamic> toJson(WordAnalysis domain) {
    return {
      'word': domain.word,
      'part_of_speech': domain.partOfSpeech,
      'english_meaning': domain.englishMeaning,
      'persian_meaning': domain.persianMeaning,
      'examples': domain.examples,
      'synonyms_by_level': domain.synonymsByLevel.map(
        (k, v) => MapEntry(k, WordDetailDto.toJson(v)),
      ),
      'antonyms': domain.antonyms.map((e) => WordDetailDto.toJson(e)).toList(),
      'collocations': domain.collocations
          .map((e) => WordDetailDto.toJson(e))
          .toList(),
    };
  }
}
