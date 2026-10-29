import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingo_sync/features/ai_mentor/presentation/widgets/ai_mentor_sheet.dart';

import '../../../../core/providers/settings_provider.dart';

class DailySyncMissionCard extends ConsumerWidget {
  final int completedMissionsCount;
  final VoidCallback onOpenVideo;
  final VoidCallback onOpenFlashcards;

  const DailySyncMissionCard({
    super.key,
    this.completedMissionsCount = 0,
    required this.onOpenVideo,
    required this.onOpenFlashcards,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isPersian = ref.watch(isPersianProvider);
    final isDark = theme.brightness == Brightness.dark;

    final progressFraction = (completedMissionsCount / 3.0).clamp(0.0, 1.0);
    final isAllDone = completedMissionsCount >= 3;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2230) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAllDone
              ? Colors.amber.withValues(alpha: 0.6)
              : theme.colorScheme.primary.withValues(alpha: 0.15),
          width: isAllDone ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isAllDone
                ? Colors.amber.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isAllDone
                      ? Colors.amber.withValues(alpha: 0.2)
                      : theme.colorScheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isAllDone
                      ? Icons.verified_rounded
                      : Icons.timer_outlined,
                  color: isAllDone ? Colors.amber : theme.colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPersian
                          ? 'ماموریت روزانه ۱۰ دقیقه‌ای (Daily Sync)'
                          : '10-Minute Daily Sync Mission',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAllDone
                          ? (isPersian ? 'آفرین! ۵۰ XP پاداش زنجیره دریافت شد' : 'Awesome! +50 XP bonus earned')
                          : (isPersian ? '$completedMissionsCount از ۳ تسک کلیدی انجام شده' : '$completedMissionsCount of 3 core tasks done'),
                      style: TextStyle(
                        fontSize: 12,
                        color: isAllDone ? Colors.amber : Colors.grey.shade500,
                        fontWeight: isAllDone ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              // Circular progress
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      value: progressFraction,
                      strokeWidth: 3.5,
                      backgroundColor: Colors.grey.withValues(alpha: 0.2),
                      color: isAllDone ? Colors.amber : theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    '$completedMissionsCount/3',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3 Mission Action Buttons
          Row(
            children: [
              Expanded(
                child: _MissionPill(
                  icon: Icons.play_circle_fill_rounded,
                  label: isPersian ? 'درس ویدیو\n(۵ دقیقه)' : 'Video Lesson\n(5 min)',
                  color: Colors.blueAccent,
                  onTap: onOpenVideo,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MissionPill(
                  icon: Icons.style_rounded,
                  label: isPersian ? 'مرور لایتنر\n(۳ دقیقه)' : 'Flashcards\n(3 min)',
                  color: Colors.purpleAccent,
                  onTap: onOpenFlashcards,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MissionPill(
                  icon: Icons.mic_rounded,
                  label: isPersian ? 'مکالمه مربی\n(۲ دقیقه)' : 'Voice Mentor\n(2 min)',
                  color: Colors.tealAccent,
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const AiMentorSheet(),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MissionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MissionPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
