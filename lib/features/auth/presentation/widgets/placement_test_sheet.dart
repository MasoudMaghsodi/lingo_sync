import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/settings_provider.dart';

/// مدل سوالات سریع تعیین سطح (۶۰ الی ۹۰ ثانیه)
class _PlacementQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String targetLevel;

  const _PlacementQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.targetLevel,
  });
}

final List<_PlacementQuestion> _kPlacementQuestions = [
  const _PlacementQuestion(
    question: 'Choose the correct sentence:',
    options: [
      'She do not like coffee.',
      'She does not like coffee.',
      'She is not like coffee.',
      'She not likes coffee.',
    ],
    correctIndex: 1,
    targetLevel: 'A2',
  ),
  const _PlacementQuestion(
    question: 'If I ______ enough money, I would travel around the world.',
    options: ['had', 'have', 'would have', 'will have'],
    correctIndex: 0,
    targetLevel: 'B1',
  ),
  const _PlacementQuestion(
    question: 'The new policy has sparked considerable ______ among employees.',
    options: ['controversy', 'convenience', 'confidence', 'circumstance'],
    correctIndex: 0,
    targetLevel: 'B2',
  ),
  const _PlacementQuestion(
    question: 'Rarely ______ such a mesmerizing performance on stage.',
    options: [
      'have I witnessed',
      'I have witnessed',
      'did I witnessed',
      'I witnessed',
    ],
    correctIndex: 0,
    targetLevel: 'C1',
  ),
];

class PlacementTestSheet extends ConsumerStatefulWidget {
  final ValueChanged<String> onLevelSelected;

  const PlacementTestSheet({super.key, required this.onLevelSelected});

  @override
  ConsumerState<PlacementTestSheet> createState() => _PlacementTestSheetState();
}

class _PlacementTestSheetState extends ConsumerState<PlacementTestSheet> {
  int _currentIndex = 0;
  int _score = 0;
  bool _isCompleted = false;
  String _calculatedLevel = 'A2';

  void _answerQuestion(int selectedIndex) {
    if (selectedIndex == _kPlacementQuestions[_currentIndex].correctIndex) {
      _score++;
    }

    if (_currentIndex + 1 < _kPlacementQuestions.length) {
      setState(() => _currentIndex++);
    } else {
      // محاسبه سطح CEFR
      String level;
      if (_score == 4) {
        level = 'C1';
      } else if (_score == 3) {
        level = 'B2';
      } else if (_score == 2) {
        level = 'B1';
      } else if (_score == 1) {
        level = 'A2';
      } else {
        level = 'A1';
      }

      setState(() {
        _calculatedLevel = level;
        _isCompleted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPersian = ref.watch(isPersianProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            if (!_isCompleted) ...[
              // Progress header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isPersian ? 'آزمون سریع تعیین سطح' : 'AI Placement Test',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_currentIndex + 1} / ${_kPlacementQuestions.length}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / _kPlacementQuestions.length,
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.15,
                  ),
                  color: theme.colorScheme.primary,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 24),

              // Question Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Text(
                  _kPlacementQuestions[_currentIndex].question,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                  textDirection: TextDirection.ltr,
                ),
              ),
              const SizedBox(height: 20),

              // Options
              ...List.generate(
                _kPlacementQuestions[_currentIndex].options.length,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.surface,
                      foregroundColor: theme.colorScheme.onSurface,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      alignment: Alignment.centerLeft,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    onPressed: () => _answerQuestion(i),
                    child: Text(
                      _kPlacementQuestions[_currentIndex].options[i],
                      style: const TextStyle(fontSize: 14),
                      textDirection: TextDirection.ltr,
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Test Completion & Level Result Screen
              Icon(
                Icons.workspace_premium_rounded,
                size: 72,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                isPersian ? 'سطح تخمینی شما:' : 'Your Estimated Level:',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    _calculatedLevel,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  isPersian
                      ? 'برنامه ۵۰ روزه ویژه سطح $_calculatedLevel برای شما آماده شد. برای دسترسی به ویدیوهای تحلیلی، فلش‌کارت‌های هوشمند و مربی صوتی زنده، ثبت‌نام کنید.'
                      : 'Your 50-day roadmap tailored for level $_calculatedLevel is ready. Create an account to start your daily sync mission!',
                  style: const TextStyle(fontSize: 13, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  widget.onLevelSelected(_calculatedLevel);
                },
                child: Text(
                  isPersian
                      ? 'ثبت‌نام و شروع دوره'
                      : 'Sign Up to Start Program',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
