import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingo_sync/core/localization/app_localizations.dart';
import '../../providers/dictionary_provider.dart';

class AiChatSheetContent extends ConsumerWidget {
  final TextEditingController questionController;
  final bool isAsking;
  final String? response;
  final bool isSpeakingResponse;
  final bool isPersian;
  final bool useCouncil;
  final ValueChanged<bool>? onToggleCouncil;
  final VoidCallback onAsk;
  final VoidCallback onToggleSpeech;

  const AiChatSheetContent({
    super.key,
    required this.questionController,
    required this.isAsking,
    required this.response,
    required this.isSpeakingResponse,
    required this.isPersian,
    this.useCouncil = false,
    this.onToggleCouncil,
    required this.onAsk,
    required this.onToggleSpeech,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                const SizedBox(height: 12),
                if (onToggleCouncil != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: useCouncil
                          ? theme.colorScheme.primary.withValues(alpha: 0.12)
                          : theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: useCouncil
                            ? theme.colorScheme.primary.withValues(alpha: 0.4)
                            : Colors.transparent,
                      ),
                    ),
                    child: SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: useCouncil,
                      onChanged: onToggleCouncil,
                      activeThumbColor: theme.colorScheme.primary,
                      title: Row(
                        children: [
                          Icon(
                            Icons.groups_rounded,
                            size: 18,
                            color: useCouncil
                                ? theme.colorScheme.primary
                                : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'مشاوره گروهی اساتید (Multi-Agent Council)',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: useCouncil
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: useCouncil
                                  ? theme.colorScheme.primary
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: isAsking ? null : onAsk,
                  child: isAsking
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : Text(
                          useCouncil
                              ? 'مشورت گروهی اساتید و دریافت پاسخ'
                              : AppLocalizations.getString(
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
                        // SelectableText با قابلیت افزودن مستقیم به لایتنر
                        Directionality(
                          textDirection:
                              TextDirection.rtl, // پاسخ AI همیشه فارسی است
                          child: SelectableText(
                            response!,
                            style: const TextStyle(fontSize: 15, height: 1.8),
                            cursorColor: theme.colorScheme.primary,
                            contextMenuBuilder:
                                (
                                  BuildContext context,
                                  EditableTextState editableTextState,
                                ) {
                                  final List<ContextMenuButtonItem>
                                  buttonItems =
                                      editableTextState.contextMenuButtonItems;

                                  buttonItems.insert(
                                    0,
                                    ContextMenuButtonItem(
                                      label: 'افزودن به لایتنر',
                                      onPressed: () {
                                        final selectedText = editableTextState
                                            .textEditingValue
                                            .selection
                                            .textInside(
                                              editableTextState
                                                  .textEditingValue
                                                  .text,
                                            );
                                        if (selectedText.trim().isNotEmpty) {
                                          HapticFeedback.selectionClick();
                                          ref
                                              .read(dictionaryProvider.notifier)
                                              .analyzeAndSaveFromSelection(
                                                selectedText,
                                              );
                                        }
                                        editableTextState.hideToolbar();
                                      },
                                    ),
                                  );

                                  return AdaptiveTextSelectionToolbar.buttonItems(
                                    anchors:
                                        editableTextState.contextMenuAnchors,
                                    buttonItems: buttonItems,
                                  );
                                },
                          ),
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
