import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingo_sync/core/widgets/three_dimensional_parallax_card.dart';
import 'package:lingo_sync/features/subscription/domain/models/subscription_tier.dart';
import 'package:lingo_sync/features/subscription/domain/repositories/payment_provider.dart';

/// State-of-the-art 3D Subscription & Mock Checkout Sheet (T5).
/// Features 3D parallax tier cards, feature breakdown, and an end-to-end
/// simulated checkout flow with instant activation.
class SubscriptionCheckoutSheet extends StatefulWidget {
  final VoidCallback? onSubscriptionActivated;

  const SubscriptionCheckoutSheet({super.key, this.onSubscriptionActivated});

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onSubscriptionActivated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SubscriptionCheckoutSheet(
        onSubscriptionActivated: onSubscriptionActivated,
      ),
    );
  }

  @override
  State<SubscriptionCheckoutSheet> createState() =>
      _SubscriptionCheckoutSheetState();
}

class _SubscriptionCheckoutSheetState extends State<SubscriptionCheckoutSheet> {
  SubscriptionTier _selectedTier = SubscriptionTier.examPro;
  String _selectedGateway = 'bazaar'; // 'bazaar', 'zarinpal', 'test'
  bool _isProcessing = false;

  final IPaymentProvider _paymentProvider = MockPaymentProvider();

  Future<void> _handleCheckout() async {
    await HapticFeedback.heavyImpact();
    setState(() => _isProcessing = true);

    // Simulate network delay & bank handshake
    await Future.delayed(const Duration(milliseconds: 1200));

    final result = await _paymentProvider.purchaseTier(
      'test_user_id',
      _selectedTier,
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (result.success) {
      widget.onSubscriptionActivated?.call();
      _showSuccessDialog(result.message);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'خطا در انجام پرداخت'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF181B26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_rounded,
                color: Colors.greenAccent,
                size: 48,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'پرداخت موفق و فعال‌سازی آنی',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade400,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                  Navigator.pop(context); // Close sheet
                },
                child: const Text(
                  'ورود به امکانات ویژه',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF10131D) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 30,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          color: Colors.amber,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'پلن‌های اشتراک و شبیه‌ساز LingoSync',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'مکالمه زنده، شورای اساتید و آزمون آیلتس/تافل',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 3D Tier Selector
              _buildTierParallaxCard(
                tier: SubscriptionTier.examPro,
                badge: 'پیشنهاد ویژه آزمون (Elite)',
                accentColor: Colors.amberAccent,
                isRecommended: true,
              ),
              const SizedBox(height: 12),
              _buildTierParallaxCard(
                tier: SubscriptionTier.plus,
                badge: 'محبوب‌ترین (مکالمه عمومی)',
                accentColor: Colors.cyanAccent,
              ),
              const SizedBox(height: 12),
              _buildTierParallaxCard(
                tier: SubscriptionTier.sprintPass,
                badge: 'اسپرینت ۵۰ روزه فشرده',
                accentColor: Colors.purpleAccent,
              ),
              const SizedBox(height: 24),

              // Gateway Selector
              const Text(
                'روش پرداخت:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildGatewayOption(
                    id: 'bazaar',
                    title: 'کافه‌بازار',
                    icon: Icons.shop_two_rounded,
                  ),
                  const SizedBox(width: 8),
                  _buildGatewayOption(
                    id: 'zarinpal',
                    title: 'زرین‌پال (شتاب)',
                    icon: Icons.credit_card_rounded,
                  ),
                  const SizedBox(width: 8),
                  _buildGatewayOption(
                    id: 'test',
                    title: 'تستی (آزمایشی)',
                    icon: Icons.science_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Action CTA
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 6,
                  ),
                  onPressed: _isProcessing ? null : _handleCheckout,
                  child: _isProcessing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock_outline_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'پرداخت ${_formatPrice(_selectedTier.priceToman)} و فعال‌سازی آنی',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'تضمین بازگشت وجه تا ۷ روز در صورت عدم رضایت',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTierParallaxCard({
    required SubscriptionTier tier,
    required String badge,
    required Color accentColor,
    bool isRecommended = false,
  }) {
    final isSelected = _selectedTier == tier;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ThreeDimensionalParallaxCard(
      maxTiltAngle: 0.08,
      borderRadius: BorderRadius.circular(20),
      glowColor: isSelected ? accentColor : Colors.transparent,
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedTier = tier);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? (isSelected ? const Color(0xFF1A1F2C) : const Color(0xFF141722))
              : (isSelected ? Colors.blue.shade50 : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? accentColor
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      tier.titleFa,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? accentColor : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 10,
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  _formatPrice(tier.priceToman),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildFeatureBullet(
                  '🎙️ ${tier.voiceMinutesMonthly} دقیقه مکالمه لایو Gemini 3.8',
                ),
                const SizedBox(width: 14),
                _buildFeatureBullet(
                  '🧠 ${tier.councilDailyCalls} تحلیل روزانه شورا',
                ),
              ],
            ),
            if (tier.hasExamTwin) ...[
              const SizedBox(height: 6),
              _buildFeatureBullet('🎯 شبیه‌ساز رسمی ۴ معیار آیلتس (Exam Twin)'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureBullet(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11.5,
        color: Colors.grey.shade400,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildGatewayOption({
    required String id,
    required String title,
    required IconData icon,
  }) {
    final isSelected = _selectedGateway == id;
    final theme = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedGateway = id);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.15)
                : Colors.grey.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? theme.colorScheme.primary : Colors.grey,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPrice(int toman) {
    if (toman == 0) return 'رایگان';
    final formatted = toman.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '$formatted تومان / ماه';
  }
}
