/// Model representing an Exam Twin (IELTS/TOEFL) Speaking evaluation.
class ExamEvaluation {
  final double overallBand;
  final String confidenceMargin;
  final Map<String, CriterionScore> criteria;
  final String feedbackFa;
  final List<String> strengthsFa;
  final List<String> weaknessesFa;
  final String disclaimerFa;

  const ExamEvaluation({
    required this.overallBand,
    required this.confidenceMargin,
    required this.criteria,
    required this.feedbackFa,
    required this.strengthsFa,
    required this.weaknessesFa,
    required this.disclaimerFa,
  });

  factory ExamEvaluation.fromJson(Map<String, dynamic> json) {
    final rawCrit = json['criteria'] as Map<String, dynamic>? ?? {};
    final critMap = <String, CriterionScore>{};

    for (final entry in rawCrit.entries) {
      if (entry.value is Map) {
        critMap[entry.key] =
            CriterionScore.fromJson(entry.value as Map<String, dynamic>);
      }
    }

    return ExamEvaluation(
      overallBand: (json['overallBand'] as num?)?.toDouble() ?? 6.0,
      confidenceMargin: json['confidenceMargin']?.toString() ?? '±0.5',
      criteria: critMap,
      feedbackFa: json['feedbackFa']?.toString() ?? '',
      strengthsFa: (json['strengthsFa'] as List?)?.map((e) => '$e').toList() ?? [],
      weaknessesFa:
          (json['weaknessesFa'] as List?)?.map((e) => '$e').toList() ?? [],
      disclaimerFa: json['disclaimerFa']?.toString() ??
          'این نمره یک تخمین آموزشی داخلی بر پایه هوش مصنوعی است و جایگزین کارنامه رسمی آزمون نمی‌باشد.',
    );
  }

  Map<String, dynamic> toJson() => {
        'overallBand': overallBand,
        'confidenceMargin': confidenceMargin,
        'criteria': criteria.map((k, v) => MapEntry(k, v.toJson())),
        'feedbackFa': feedbackFa,
        'strengthsFa': strengthsFa,
        'weaknessesFa': weaknessesFa,
        'disclaimerFa': disclaimerFa,
      };
}

class CriterionScore {
  final double band;
  final String quote;
  final String commentFa;

  const CriterionScore({
    required this.band,
    required this.quote,
    required this.commentFa,
  });

  factory CriterionScore.fromJson(Map<String, dynamic> json) {
    return CriterionScore(
      band: (json['band'] as num?)?.toDouble() ?? 6.0,
      quote: json['quote']?.toString() ?? '',
      commentFa: json['commentFa']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'band': band,
        'quote': quote,
        'commentFa': commentFa,
      };
}
