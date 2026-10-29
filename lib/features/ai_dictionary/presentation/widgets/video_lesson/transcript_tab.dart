import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingo_sync/core/constants/app_constants.dart';
import '../../providers/dictionary_provider.dart';

/// The "Transcript" tab of `VideoLessonPage`.
/// Features:
/// - EN/FA language toggle
/// - Custom Context Menu to add selected words directly to Anki with full AI analysis
class VideoTranscriptTab extends ConsumerStatefulWidget {
  final String persianTranscript;
  final String englishTranscript;

  const VideoTranscriptTab({
    super.key,
    required this.persianTranscript,
    this.englishTranscript = '',
  });

  @override
  ConsumerState<VideoTranscriptTab> createState() => _VideoTranscriptTabState();
}

class _VideoTranscriptTabState extends ConsumerState<VideoTranscriptTab> {
  bool _showEnglish = false;

  void _onSelectionAdd(SelectedContent? selection) {
    if (selection == null || selection.plainText.trim().isEmpty) return;

    HapticFeedback.selectionClick();
    ref
        .read(dictionaryProvider.notifier)
        .analyzeAndSaveFromSelection(selection.plainText);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentText = _showEnglish
        ? (widget.englishTranscript.trim().isNotEmpty
            ? widget.englishTranscript
            : 'English transcript is not available for this lesson.\nمتن اصلی انگلیسی برای این ویدیو ثبت نشده است.')
        : widget.persianTranscript;
    final textDirection = _showEnglish ? TextDirection.ltr : TextDirection.rtl;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(UIConstants.largePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Language Switcher
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'فارسی',
                style: TextStyle(
                  fontWeight: !_showEnglish
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: !_showEnglish
                      ? theme.colorScheme.primary
                      : Colors.grey,
                ),
              ),
              Switch(
                value: _showEnglish,
                activeThumbColor: theme.colorScheme.primary,
                onChanged: (value) => setState(() => _showEnglish = value),
              ),
              Text(
                'English',
                style: TextStyle(
                  fontWeight: _showEnglish
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: _showEnglish ? theme.colorScheme.primary : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: UIConstants.smallPadding),

          // Transcript Content with Custom Context Menu
          Container(
            padding: const EdgeInsets.all(UIConstants.largePadding),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(
                UIConstants.largeBorderRadius,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Directionality(
              textDirection: textDirection,
              child: SelectableText(
                currentText,
                style: const TextStyle(fontSize: 16, height: 2.0),
                contextMenuBuilder:
                    (
                      BuildContext context,
                      EditableTextState editableTextState,
                    ) {
                      final List<ContextMenuButtonItem> buttonItems =
                          editableTextState.contextMenuButtonItems;

                      // افزودن دکمه شخصی‌سازی شده به منوی انتخاب متن
                      buttonItems.insert(
                        0,
                        ContextMenuButtonItem(
                          label: 'افزودن به جعبه لایتنر',
                          onPressed: () {
                            final selectedText = editableTextState
                                .textEditingValue
                                .selection
                                .textInside(
                                  editableTextState.textEditingValue.text,
                                );
                            _onSelectionAdd(SelectedContent(selectedText));
                            editableTextState.hideToolbar();
                          },
                        ),
                      );

                      return AdaptiveTextSelectionToolbar.buttonItems(
                        anchors: editableTextState.contextMenuAnchors,
                        buttonItems: buttonItems,
                      );
                    },
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

/// Helper class to match selection format
class SelectedContent {
  final String plainText;
  SelectedContent(this.plainText);
}
