import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_sync/features/subscription/domain/models/subscription_tier.dart';
import 'package:lingo_sync/features/subscription/domain/repositories/payment_provider.dart';

void main() {
  group('Subscription & Payment Tests', () {
    test('SubscriptionTier attributes match brief limits', () {
      expect(SubscriptionTier.free.voiceMinutesMonthly, equals(10));
      expect(SubscriptionTier.free.videoExtractionsWeekly, equals(1));
      expect(SubscriptionTier.free.councilDailyCalls, equals(1));
      expect(SubscriptionTier.free.hasC1Studio, isFalse);
      expect(SubscriptionTier.free.hasExamTwin, isFalse);

      expect(SubscriptionTier.plus.voiceMinutesMonthly, equals(150));
      expect(SubscriptionTier.plus.videoExtractionsWeekly, equals(10));
      expect(SubscriptionTier.plus.councilDailyCalls, equals(3));
      expect(SubscriptionTier.plus.hasC1Studio, isTrue);

      expect(SubscriptionTier.examPro.voiceMinutesMonthly, equals(400));
      expect(SubscriptionTier.examPro.hasExamTwin, isTrue);
      expect(SubscriptionTier.examPro.hasC1Studio, isTrue);
    });

    test('SubscriptionTier.fromString parses correctly', () {
      expect(SubscriptionTier.fromString('plus'), equals(SubscriptionTier.plus));
      expect(SubscriptionTier.fromString('EXAM_PRO'), equals(SubscriptionTier.examPro));
      expect(SubscriptionTier.fromString('sprint_pass'), equals(SubscriptionTier.sprintPass));
      expect(SubscriptionTier.fromString('invalid'), equals(SubscriptionTier.free));
      expect(SubscriptionTier.fromString(null), equals(SubscriptionTier.free));
    });

    test('MockPaymentProvider completes purchase successfully', () async {
      final provider = MockPaymentProvider();
      final initialized = await provider.initialize();
      expect(initialized, isTrue);

      final result = await provider.purchaseTier('user-123', SubscriptionTier.plus);
      expect(result.success, isTrue);
      expect(result.transactionId, isNotNull);
      expect(result.transactionId!.startsWith('mock_tx_'), isTrue);
    });

    test('UserSubscription active status check', () {
      final activeSub = UserSubscription(
        userId: 'u1',
        tier: SubscriptionTier.plus,
        expiresAt: DateTime.now().add(const Duration(days: 10)),
      );
      expect(activeSub.isActive, isTrue);
      expect(activeSub.isExpired, isFalse);

      final expiredSub = UserSubscription(
        userId: 'u2',
        tier: SubscriptionTier.plus,
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(expiredSub.isExpired, isTrue);
      expect(expiredSub.isActive, isFalse);
    });
  });
}
