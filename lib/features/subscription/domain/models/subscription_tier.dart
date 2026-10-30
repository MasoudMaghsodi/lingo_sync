/// Available subscription tiers in LingoSync v2.0 per Master Brief (§4.14).
enum SubscriptionTier {
  free,
  plus,
  examPro,
  sprintPass;

  String get id => switch (this) {
        SubscriptionTier.free => 'free',
        SubscriptionTier.plus => 'plus',
        SubscriptionTier.examPro => 'exam_pro',
        SubscriptionTier.sprintPass => 'sprint_pass',
      };

  String get titleFa => switch (this) {
        SubscriptionTier.free => 'رایگان (پایه)',
        SubscriptionTier.plus => 'پلاس (LingoSync Plus)',
        SubscriptionTier.examPro => 'پرو آزمون (Exam Pro)',
        SubscriptionTier.sprintPass => 'اسپرینت ۵۰ روزه آزمون (Sprint Pass)',
      };

  int get voiceMinutesMonthly => switch (this) {
        SubscriptionTier.free => 10,
        SubscriptionTier.plus => 150,
        SubscriptionTier.examPro => 400,
        SubscriptionTier.sprintPass => 200,
      };

  int get videoExtractionsWeekly => switch (this) {
        SubscriptionTier.free => 1,
        SubscriptionTier.plus => 10,
        SubscriptionTier.examPro => 999,
        SubscriptionTier.sprintPass => 25,
      };

  int get councilDailyCalls => switch (this) {
        SubscriptionTier.free => 1,
        SubscriptionTier.plus => 3,
        SubscriptionTier.examPro => 20,
        SubscriptionTier.sprintPass => 5,
      };

  bool get hasC1Studio => this != SubscriptionTier.free;

  bool get hasExamTwin =>
      this == SubscriptionTier.examPro || this == SubscriptionTier.sprintPass;

  int get priceToman => switch (this) {
        SubscriptionTier.free => 0,
        SubscriptionTier.plus => 490000,
        SubscriptionTier.examPro => 890000,
        SubscriptionTier.sprintPass => 650000,
      };

  static SubscriptionTier fromString(String? val) {
    return switch (val?.toLowerCase()) {
      'plus' => SubscriptionTier.plus,
      'exam_pro' => SubscriptionTier.examPro,
      'sprint_pass' => SubscriptionTier.sprintPass,
      _ => SubscriptionTier.free,
    };
  }
}

/// Represents the learner's active subscription status.
class UserSubscription {
  final String userId;
  final SubscriptionTier tier;
  final String status;
  final String provider;
  final DateTime? expiresAt;

  const UserSubscription({
    required this.userId,
    required this.tier,
    this.status = 'active',
    this.provider = 'mock',
    this.expiresAt,
  });

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  bool get isActive => status == 'active' && !isExpired;

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      userId: json['user_id']?.toString() ?? '',
      tier: SubscriptionTier.fromString(json['tier']?.toString()),
      status: json['status']?.toString() ?? 'active',
      provider: json['provider']?.toString() ?? 'mock',
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'tier': tier.id,
        'status': status,
        'provider': provider,
        'expires_at': expiresAt?.toIso8601String(),
      };
}
