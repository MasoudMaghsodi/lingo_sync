import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/logging/app_logger.dart';
import '../models/subscription_tier.dart';

class PaymentResult {
  final bool success;
  final String? transactionId;
  final String message;
  final String? errorMessage;

  const PaymentResult({
    required this.success,
    this.transactionId,
    required this.message,
    this.errorMessage,
  });

  factory PaymentResult.success({
    String? transactionId,
    required String message,
  }) => PaymentResult(
    success: true,
    transactionId: transactionId,
    message: message,
  );

  factory PaymentResult.failure({required String errorMessage}) =>
      PaymentResult(
        success: false,
        message: 'پرداخت ناموفق بود',
        errorMessage: errorMessage,
      );
}

/// Abstract contract for payment gateways (Bazaar, Myket, Zarinpal, In-App Purchase).
abstract interface class IPaymentProvider {
  String get providerName;
  Future<bool> initialize();
  Future<PaymentResult> purchaseTier(String userId, SubscriptionTier tier);
}

/// Mock / Test provider used in development or until live bank gateway is connected.
class MockPaymentProvider implements IPaymentProvider {
  @override
  String get providerName => 'mock';

  @override
  Future<bool> initialize() async => true;

  @override
  Future<PaymentResult> purchaseTier(
    String userId,
    SubscriptionTier tier,
  ) async {
    // Simulates successful transaction
    await Future.delayed(const Duration(milliseconds: 600));
    final txId = 'mock_tx_${DateTime.now().millisecondsSinceEpoch}';
    return PaymentResult.success(
      transactionId: txId,
      message: 'اشتراک ${tier.titleFa} با موفقیت فعال شد (محیط آزمایشی)',
    );
  }
}

/// Repository responsible for user subscription status and payment flows.
class SubscriptionRepository {
  final SupabaseClient _supabase;
  final IPaymentProvider _paymentProvider;

  SubscriptionRepository({
    SupabaseClient? supabase,
    IPaymentProvider? paymentProvider,
  }) : _supabase = supabase ?? Supabase.instance.client,
       _paymentProvider = paymentProvider ?? MockPaymentProvider();

  Future<UserSubscription> getUserSubscription(String userId) async {
    try {
      final res = await _supabase
          .from('user_subscriptions')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (res != null) {
        return UserSubscription.fromJson(res);
      }
    } catch (e) {
      logger.warning(
        'Failed to query user_subscriptions from Supabase: $e',
        context: 'SubscriptionRepository',
      );
    }

    // Default to Free Tier
    return UserSubscription(userId: userId, tier: SubscriptionTier.free);
  }

  Future<PaymentResult> purchase(SubscriptionTier tier) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return PaymentResult.failure(errorMessage: 'کاربر احراز هویت نشده است.');
    }

    final result = await _paymentProvider.purchaseTier(userId, tier);
    if (result.success) {
      // Record subscription in database
      try {
        final expires = DateTime.now().add(const Duration(days: 30));
        await _supabase.from('user_subscriptions').upsert({
          'user_id': userId,
          'tier': tier.id,
          'status': 'active',
          'provider': _paymentProvider.providerName,
          'transaction_id': result.transactionId,
          'expires_at': expires.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        logger.warning(
          'Failed to record subscription to Supabase: $e',
          context: 'SubscriptionRepository',
        );
      }
    }

    return result;
  }
}
