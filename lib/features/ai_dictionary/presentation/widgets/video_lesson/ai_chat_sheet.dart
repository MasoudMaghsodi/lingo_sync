import 'package:flutter/material.dart';
import 'package:lingo_sync/core/localization/app_localizations.dart';

/// Pure UI for the "Ask the AI Mentor" bottom sheet content shown from
/// `VideoLessonPage`. All state (question text, loading flag, last
/// answer) lives in the parent page — this widget only renders what it's
/// given and reports user actions via callbacks.
class AiChatSheetContent extends StatelessWidget {
  final TextEditingController questionController;
  final bool isAsking;
  final String? response;
  final bool isSpeakingResponse;
  final bool isPersian;
  final VoidCallback onAsk;
  final VoidCallback onToggleSpeech;

  const AiChatSheetContent({
    super.key,
    required this.questionController,
    required this.isAsking,
    required this.response,
    required this.isSpeakingResponse,
    required this.isPersian,
    required this.onAsk,
    required this.onToggleSpeech,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.psychology,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.getString(
                        'ask_ai_mentor_title',
                        isPersian,
                      ),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.getString(
                    'ai_question_limit_notice',
                    isPersian,
                  ),
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: questionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.getString(
                      'ai_question_hint',
                      isPersian,
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: isAsking ? null : onAsk,
                  child: isAsking
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : Text(
                          AppLocalizations.getString(
                            'send_question',
                            isPersian,
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 16),
                if (response != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppLocalizations.getString(
                                'ai_answer_label',
                                isPersian,
                              ),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                isSpeakingResponse
                                    ? Icons.stop_circle_rounded
                                    : Icons.play_circle_fill_rounded,
                                color: theme.colorScheme.primary,
                              ),
                              onPressed: onToggleSpeech,
                            ),
                          ],
                        ),
                        const Divider(),
                        // 🚀 متن قابل انتخاب (کپی کردن و ترنسلیت)
                        SelectableText(
                          response!,
                          style: const TextStyle(fontSize: 15, height: 1.8),
                          cursorColor: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
