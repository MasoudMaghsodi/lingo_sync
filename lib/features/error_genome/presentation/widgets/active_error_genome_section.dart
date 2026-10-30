import 'package:flutter/material.dart';
import 'package:lingo_sync/core/widgets/three_dimensional_parallax_card.dart';
import 'package:lingo_sync/features/error_genome/domain/models/learner_error_entry.dart';

/// 3D Visualized Error Genome Section for Home Screen (G1).
/// Displays top 3 remediating errors with dynamic progress bars.
class ActiveErrorGenomeSection extends StatelessWidget {
  final List<LearnerErrorEntry> activeErrors;
  final bool isPersian;

  const ActiveErrorGenomeSection({
    super.key,
    this.activeErrors = const [],
    this.isPersian = true,
  });

  static final List<LearnerErrorEntry> _defaultCandidates = [
    const LearnerErrorEntry(
      id: 'mock_err_1',
      category: 'حرف اضافه (Preposition)',
      verbatimQuote: 'interested at',
      correctedVersion: 'interested in',
      explanationFa:
          'در انگلیسی حرف اضافه وابسته به interested منحصراً in است نه at.',
      confidence: 0.95,
      remediationStage: 3,
    ),
    const LearnerErrorEntry(
      id: 'mock_err_2',
      category: 'گرته‌برداری مستقیم (False Cognate)',
      verbatimQuote: 'depends to',
      correctedVersion: 'depends on',
      explanationFa:
          'به دلیل ساختار زبان فارسی (بستگی داشتن به) معمولاً to استفاده می‌شود، ولی در انگلیسی depend on صحیح است.',
      confidence: 0.92,
      remediationStage: 2,
    ),
    const LearnerErrorEntry(
      id: 'mock_err_3',
      category: 'ساختار فعل (Verb Collocation)',
      verbatimQuote: 'marry with',
      correctedVersion: 'marry / get married to',
      explanationFa:
          'در انگلیسی marry مستقیماً مفعول می‌گیرد و حرف اضافه with اشتباه است.',
      confidence: 0.88,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final displayList = activeErrors.isNotEmpty
        ? activeErrors.take(3).toList()
        : _defaultCandidates;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Title Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.biotech_rounded,
                  color: Colors.amber,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isPersian
                      ? '۳ خطایی که در حال اصلاح آنها هستم'
                      : '3 Errors I am Remediating',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isPersian ? 'ژنوم خطا' : 'Genome',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 3D Parallax Error Cards
          ...displayList.map((err) {
            final progress = (err.remediationStage / 4.0).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ThreeDimensionalParallaxCard(
                borderRadius: BorderRadius.circular(16),
                glowColor: Colors.deepPurple,
                maxTiltAngle: 0.08,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF181B26) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.grey.withValues(alpha: 0.2),
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
                                err.verbatimQuote,
                                style: const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: Colors.redAccent,
                                  decorationThickness: 2,
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                err.correctedVersion,
                                style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            isPersian
                                ? '${err.remediationStage} از ۴ استفاده'
                                : '${err.remediationStage}/4 uses',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 5,
                          backgroundColor: Colors.grey.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progress >= 0.75
                                ? Colors.greenAccent
                                : Colors.amberAccent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        err.explanationFa,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? Colors.grey.shade300
                              : Colors.grey.shade700,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
