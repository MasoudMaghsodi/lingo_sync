/// Represents a single recorded error in the learner's Personal Error Genome.
class LearnerErrorEntry {
  final String id;
  final String category;
  final String verbatimQuote;
  final String correctedVersion;
  final String explanationFa;
  final double confidence;
  final bool l1InterferenceFlag;
  final int remediationStage;
  final int occurrenceCount;
  final DateTime? lastSeenAt;

  const LearnerErrorEntry({
    required this.id,
    required this.category,
    required this.verbatimQuote,
    required this.correctedVersion,
    required this.explanationFa,
    required this.confidence,
    this.l1InterferenceFlag = true,
    this.remediationStage = 1,
    this.occurrenceCount = 1,
    this.lastSeenAt,
  });

  factory LearnerErrorEntry.fromJson(Map<String, dynamic> json) {
    return LearnerErrorEntry(
      id: json['id']?.toString() ?? '',
      category: json['category']?.toString() ?? 'general_grammar',
      verbatimQuote: json['verbatim_quote']?.toString() ?? '',
      correctedVersion: json['corrected_version']?.toString() ?? '',
      explanationFa: json['explanation_fa']?.toString() ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.7,
      l1InterferenceFlag: json['l1_interference_flag'] != false,
      remediationStage: (json['remediation_stage'] as num?)?.toInt() ?? 1,
      occurrenceCount: (json['occurrence_count'] as num?)?.toInt() ?? 1,
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.tryParse(json['last_seen_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'verbatim_quote': verbatimQuote,
    'corrected_version': correctedVersion,
    'explanation_fa': explanationFa,
    'confidence': confidence,
    'l1_interference_flag': l1InterferenceFlag,
    'remediation_stage': remediationStage,
    'occurrence_count': occurrenceCount,
    'last_seen_at': lastSeenAt?.toIso8601String(),
  };
}
