import 'package:flutter/material.dart';
import 'package:lingo_sync/core/constants/app_constants.dart';
import 'package:lingo_sync/core/localization/app_localizations.dart';
import '../../../data/models/video_analysis_model.dart';

/// The "Kid-Friendly Grammar" tab of `VideoLessonPage`: one expandable
/// card per grammar point extracted from the video.
class VideoGrammarTab extends StatelessWidget {
  final List<GrammarPoint> grammarPoints;
  final bool isPersian;
  final Future<void> Function(String text) onSpeak;
  final Future<void> Function(GrammarPoint grammar) onSaveToAnki;

  const VideoGrammarTab({
    super.key,
    required this.grammarPoints,
    required this.isPersian,
    required this.onSpeak,
    required this.onSaveToAnki,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: grammarPoints.length,
      itemBuilder: (context, index) => _GrammarPointCard(
        grammar: grammarPoints[index],
        theme: theme,
        isPersian: isPersian,
        onSpeak: onSpeak,
        onSaveToAnki: onSaveToAnki,
      ),
    );
  }
}

class _GrammarPointCard extends StatelessWidget {
  final GrammarPoint grammar;
  final ThemeData theme;
  final bool isPersian;
  final Future<void> Function(String text) onSpeak;
  final Future<void> Function(GrammarPoint grammar) onSaveToAnki;

  const _GrammarPointCard({
    required this.grammar,
    required this.theme,
    required this.isPersian,
    required this.onSpeak,
    required this.onSaveToAnki,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    grammar.structureName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                // 🚀 دکمه ذخیره گرامر کاملاً مشخص شد
                ElevatedButton.icon(
                  onPressed: () => onSaveToAnki(grammar),
                  icon: const Icon(Icons.bookmark_add_rounded, size: 18),
                  label: Text(
                    AppLocalizations.getString('add_to_anki', isPersian),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary.withValues(
                      alpha: 0.1,
                    ),
                    foregroundColor: theme.colorScheme.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(),
            ),
            Text(
              '${AppLocalizations.getString('childlike_explanation_prefix', isPersian)}\n${grammar.persianExplanation}',
              style: const TextStyle(fontSize: 16, height: 1.8),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(
                  AppConstants.standardBorderRadius,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.getString('example_in_video', isPersian),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          grammar.exampleFromTranscript,
                          style: const TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.volume_up_rounded,
                          color: theme.colorScheme.primary,
                        ),
                        onPressed: () => onSpeak(grammar.exampleFromTranscript),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
