import 'package:flutter/material.dart';

/// The "Transcript" tab of `VideoLessonPage`: the full, selectable
/// translated transcript. No state of its own.
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
            child: SelectableText(
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
