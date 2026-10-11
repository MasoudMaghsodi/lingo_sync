class WordDetail {
  final String word;
  final String persian;

  const WordDetail({required this.word, required this.persian});
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

  const WordAnalysis({
    required this.word,
    required this.partOfSpeech,
    required this.englishMeaning,
    required this.persianMeaning,
    required this.examples,
    required this.synonymsByLevel,
    required this.antonyms,
    required this.collocations,
  });
}
