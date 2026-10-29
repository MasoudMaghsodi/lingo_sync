import '../../../../core/utils/map_utils.dart';
import '../../domain/entities/word_analysis.dart';

class WordDetailDto {
  static WordDetail fromJson(dynamic rawJson) {
    final json = safeMap(rawJson);
    return WordDetail(
      word: json['word']?.toString() ?? '',
      persian: json['persian']?.toString() ?? '',
    );
  }

  static Map<String, dynamic> toJson(WordDetail domain) {
    return {'word': domain.word, 'persian': domain.persian};
  }
}

class WordAnalysisDto {
  static WordAnalysis fromJson(dynamic rawJson) {
    final json = safeMap(rawJson);
    final synJson = safeMap(json['synonyms_by_level']);
    final Map<String, WordDetail> parsedSynonyms = {};

    synJson.forEach((key, value) {
      if (value is Map && value.isNotEmpty) {
        parsedSynonyms[key] = WordDetailDto.fromJson(safeMap(value));
      }
    });

    final antonymsList = json['antonyms'] is List ? (json['antonyms'] as List) : [];
    final collocationsList = json['collocations'] is List ? (json['collocations'] as List) : [];
    final examplesList = json['examples'] is List ? (json['examples'] as List) : [];

    return WordAnalysis(
      word: json['word']?.toString() ?? '',
      partOfSpeech: json['part_of_speech']?.toString() ?? '',
      englishMeaning: json['english_meaning']?.toString() ?? '',
      persianMeaning: json['persian_meaning']?.toString() ?? '',
      examples: examplesList.map((e) => e.toString()).toList(),
      synonymsByLevel: parsedSynonyms,
      antonyms: antonymsList
          .whereType<Map>()
          .map((e) => WordDetailDto.fromJson(safeMap(e)))
          .toList(),
      collocations: collocationsList
          .whereType<Map>()
          .map((e) => WordDetailDto.fromJson(safeMap(e)))
          .toList(),
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
