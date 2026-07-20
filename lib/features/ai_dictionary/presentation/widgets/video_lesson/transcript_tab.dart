import 'package:flutter/material.dart';
import 'package:lingo_sync/core/widgets/persian_content_text.dart';

/// The "Transcript" tab of `VideoLessonPage`: the full, selectable,
/// always-Persian translated transcript. Scrolls via
/// [SingleChildScrollView] regardless of length — there is no fixed
/// height constraint anywhere in this widget, so arbitrarily long
/// translations remain fully scrollable and selectable.
class VideoTranscriptTab extends StatelessWidget {
  final String transcript;

  const VideoTranscriptTab({super.key, required this.transcript});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: PersianContentSelectableText(
              transcript,
              style: const TextStyle(fontSize: 16, height: 2.0),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
