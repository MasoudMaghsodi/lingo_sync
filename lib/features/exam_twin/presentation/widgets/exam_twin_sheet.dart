import 'package:flutter/material.dart';
import '../../data/exam_twin_repository_impl.dart';
import '../../domain/models/exam_attempt_model.dart';

class ExamTwinSheet extends StatefulWidget {
  final String? initialTopic;

  const ExamTwinSheet({super.key, this.initialTopic});

  static Future<void> show(BuildContext context, {String? initialTopic}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExamTwinSheet(initialTopic: initialTopic),
    );
  }

  @override
  State<ExamTwinSheet> createState() => _ExamTwinSheetState();
}

class _ExamTwinSheetState extends State<ExamTwinSheet> {
  final ExamTwinRepository _repository = ExamTwinRepository();
  late final TextEditingController _inputController;

  String _selectedExamType = 'ielts_speaking';
  final int _partNumber = 2;
  bool _isLoading = false;
  String? _error;
  ExamEvaluation? _evaluation;

  static const List<Map<String, dynamic>> _sampleTopics = [
    {
      'title': 'IELTS Part 2: A challenging skill',
      'prompt':
          'Describe a challenging skill that you learned successfully.\nYou should say:\n• What it is and how you learned it\n• Why it was difficult\n• And explain how you felt after mastering it.',
    },
    {
      'title': 'IELTS Part 1: Work & Study',
      'prompt':
          'Do you prefer working alone or with colleagues? Why?\nWhat is the most interesting part of your daily routine?',
    },
    {
      'title': 'TOEFL Speaking: City vs Countryside',
      'prompt':
          'Some people prefer living in a bustling metropolitan city, while others prefer living in a quiet rural area. Which do you prefer and why? Give specific reasons and details.',
    },
  ];

  late String _currentPrompt;

  @override
  void initState() {
    super.initState();
    _currentPrompt = widget.initialTopic ?? _sampleTopics.first['prompt'];
    _inputController = TextEditingController();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _submitEvaluation() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      setState(
        () => _error = 'لطفاً متن پاسخ یا متن پیاده‌شده صحبت خود را وارد کنید.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _evaluation = null;
    });

    final result = await _repository.evaluateSpeaking(
      transcript: text,
      examType: _selectedExamType,
      partNumber: _partNumber,
      durationSeconds: 90,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result != null) {
          _evaluation = result;
        } else {
          _error = 'ارزیابی آزمون با خطا مواجه شد. لطفاً دوباره تلاش کنید.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    return Container(
      height: mediaQuery.size.height * 0.90,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // Drag handle
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.school,
                      color: Colors.deepPurple,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'شبیه‌ساز رسمی آزمون (Exam Twin)',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.deepOrange.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'بتا',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepOrange,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'ارزیابی مکالمه بر اساس ۴ معیار استاندارد آیلتس و تافل',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 20),

            // Body
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Exam Type Selector
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('IELTS Speaking')),
                          selected: _selectedExamType == 'ielts_speaking',
                          onSelected: (val) {
                            if (val) {
                              setState(
                                () => _selectedExamType = 'ielts_speaking',
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('TOEFL Speaking')),
                          selected: _selectedExamType == 'toefl_speaking',
                          onSelected: (val) {
                            if (val) {
                              setState(
                                () => _selectedExamType = 'toefl_speaking',
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Prompt Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.psychology,
                              size: 18,
                              color: Colors.deepPurple,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'موضوع و سوال آزمون:',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            _currentPrompt,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.4,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Candidate Input
                  Text(
                    'پاسخ ثبت‌شده شما:',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: TextField(
                      controller: _inputController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText:
                            'Enter candidate spoken transcript or sample response here...',
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Submit Button
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _submitEvaluation,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.analytics),
                    label: Text(
                      _isLoading
                          ? 'در حال تحلیل استاندارد اگزمینر...'
                          : 'ارزیابی نمره آزمون',
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],

                  // Evaluation Result
                  if (_evaluation != null) ...[
                    const SizedBox(height: 24),
                    _buildEvaluationCard(theme, _evaluation!),
                  ],

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvaluationCard(ThemeData theme, ExamEvaluation eval) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Band Display
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.deepPurple, Colors.indigo],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      'Band ${eval.overallBand.toStringAsFixed(1)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${eval.confidenceMargin})',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'برآورد آزمون',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Criteria breakdown
          for (final entry in eval.criteria.entries) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.4,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _criterionTitle(entry.key),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'نمره: ${entry.value.band.toStringAsFixed(1)}',
                        style: const TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (entry.value.quote.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        '“${entry.value.quote}”',
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                  if (entry.value.commentFa.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      entry.value.commentFa,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Feedback
          if (eval.feedbackFa.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'جمع‌بندی اگزمینر:',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              eval.feedbackFa,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ],

          // Mandatory Disclaimer
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    eval.disclaimerFa,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _criterionTitle(String key) {
    switch (key) {
      case 'fluencyCoherence':
        return 'روانی و انسجام کلام (Fluency & Coherence)';
      case 'lexicalResource':
        return 'دایره و دقت واژگان (Lexical Resource)';
      case 'grammaticalRange':
        return 'تنوع و صحت گرامری (Grammatical Range)';
      case 'pronunciation':
        return 'تلفظ و ادای کلمات (Pronunciation)';
      default:
        return key;
    }
  }
}
