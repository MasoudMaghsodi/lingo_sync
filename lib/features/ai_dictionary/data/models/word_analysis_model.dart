class WordDetail {
  final String word;
  final String persian;

  WordDetail({required this.word, required this.persian});

  factory WordDetail.fromJson(Map<String, dynamic> json) {
    return WordDetail(word: json['word'] ?? '', persian: json['persian'] ?? '');
  }

  Map<String, dynamic> toJson() => {'word': word, 'persian': persian};
}

class WordAnalysis {
  final String word;
  final String partOfSpeech;
  final String englishMeaning;
  final String persianMeaning;
  final List<String> examples;
  final Map<String, WordDetail> synonymsByLevel;
  final List<WordDetail> antonyms;
  final List<WordDetail> collocations;

  WordAnalysis({
    required this.word,
    required this.partOfSpeech,
    required this.englishMeaning,
    required this.persianMeaning,
    required this.examples,
    required this.synonymsByLevel,
    required this.antonyms,
    required this.collocations,
  });

  factory WordAnalysis.fromJson(Map<String, dynamic> json) {
    // پارس کردن مترادف‌ها با ساختار جدید
    final Map<String, dynamic> synJson = json['synonyms_by_level'] ?? {};
    final Map<String, WordDetail> parsedSynonyms = {};
    synJson.forEach((key, value) {
      if (value is Map<String, dynamic> && value.isNotEmpty) {
        parsedSynonyms[key] = WordDetail.fromJson(value);
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
              ?.map((e) => WordDetail.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      collocations:
          (json['collocations'] as List<dynamic>?)
              ?.map((e) => WordDetail.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'part_of_speech': partOfSpeech,
      'english_meaning': englishMeaning,
      'persian_meaning': persianMeaning,
      'examples': examples,
      'synonyms_by_level': synonymsByLevel.map(
        (k, v) => MapEntry(k, v.toJson()),
      ),
      'antonyms': antonyms.map((e) => e.toJson()).toList(),
      'collocations': collocations.map((e) => e.toJson()).toList(),
    };
  }
}
