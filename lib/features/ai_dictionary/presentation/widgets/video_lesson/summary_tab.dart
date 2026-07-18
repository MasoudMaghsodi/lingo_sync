import 'package:flutter/material.dart';
import 'package:lingo_sync/core/localization/app_localizations.dart';

/// The "Summary & Notes" tab of `VideoLessonPage`: the AI-generated
/// summary plus the user's own personal note for this video. Purely
/// presentational — all state (the note's text, loading/saving flags) and
/// the save action live in the parent page, since the note needs to
/// survive tab switches and share its loading state with the save button.
class VideoSummaryTab extends StatelessWidget {
  final String summary;
  final TextEditingController noteController;
  final bool isLoadingNote;
  final bool isSavingNote;
  final VoidCallback onSaveNote;
  final bool isPersian;

  const VideoSummaryTab({
    super.key,
    required this.summary,
    required this.noteController,
    required this.isLoadingNote,
    required this.isSavingNote,
    required this.onSaveNote,
    required this.isPersian,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.getString('smart_summary_title', isPersian),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
            child: Text(
              summary,
              style: const TextStyle(
                fontSize: 16,
                height: 2.0,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Icon(Icons.edit_note_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.getString('personal_notes_title', isPersian),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isLoadingNote)
            const Center(child: CircularProgressIndicator())
          else
            Container(
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
              child: TextField(
                controller: noteController,
                maxLines: 8,
                style: const TextStyle(fontSize: 16, height: 1.8),
                decoration: InputDecoration(
                  hintText: AppLocalizations.getString('note_hint', isPersian),
                  hintStyle: TextStyle(
                    color: Colors.grey.withValues(alpha: 0.5),
                  ),
                  contentPadding: const EdgeInsets.all(24),
                  border: InputBorder.none,
                ),
              ),
            ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: isSavingNote ? null : onSaveNote,
            icon: const Icon(Icons.save_rounded),
            label: isSavingNote
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : Text(
                    AppLocalizations.getString('save_note_button', isPersian),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
