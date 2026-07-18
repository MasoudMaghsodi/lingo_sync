import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingo_sync/core/localization/app_localizations.dart';
import '../../../data/models/word_analysis_model.dart';
import '../../providers/dictionary_provider.dart';

/// The "Vocabulary" tab of `VideoLessonPage`: one card per extracted
/// word, with CEFR-leveled synonyms.
class VideoVocabularyTab extends StatelessWidget {
  final List<WordAnalysis> vocabulary;
  final bool isPersian;
  final Future<void> Function(String text) onSpeak;

  const VideoVocabularyTab({
    super.key,
    required this.vocabulary,
    required this.isPersian,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: vocabulary.length,
      itemBuilder: (context, index) => _VocabularyCard(
        word: vocabulary[index],
        isPersian: isPersian,
        onSpeak: onSpeak,
      ),
    );
  }
}

/// A [ConsumerWidget] because saving a word (or one of its synonyms) to
/// flashcards goes straight through [dictionaryProvider] — no need to
/// bounce that back up through the parent page.
class _VocabularyCard extends ConsumerWidget {
  final WordAnalysis word;
  final bool isPersian;
  final Future<void> Function(String text) onSpeak;

  const _VocabularyCard({
    required this.word,
    required this.isPersian,
    required this.onSpeak,
  });

  Future<void> _saveWord(
    BuildContext context,
    WidgetRef ref,
    WordAnalysis wordData,
  ) async {
    try {
      await ref
          .read(dictionaryProvider.notifier)
          .saveWordToFlashcards(wordData);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.getString('added_to_flashcards', isPersian),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    word.word.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.volume_up_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      onPressed: () => onSpeak(word.word),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.bookmark_add_rounded,
                        color: Colors.green,
                      ),
                      tooltip: AppLocalizations.getString(
                        'add_to_leitner_tooltip',
                        isPersian,
                      ),
                      onPressed: () => _saveWord(context, ref, word),
                    ),
                  ],
                ),
              ],
            ),
            Text(
              word.englishMeaning,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              word.persianMeaning,
              style: const TextStyle(color: Colors.grey, fontSize: 15),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(),
            ),
            Text(
              AppLocalizations.getString('synonyms_level_hint', isPersian),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: word.synonymsByLevel.entries.map((entry) {
                Color levelColor = Colors.grey;
                if (entry.key.contains('A')) {
                  levelColor = Colors.green;
                } else if (entry.key.contains('B')) {
                  levelColor = Colors.blue;
                } else if (entry.key.contains('C')) {
                  levelColor = Colors.orange;
                }

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onLongPress: () {
                      final tempWord = WordAnalysis(
                        word: entry.value.word,
                        partOfSpeech: word.partOfSpeech,
                        englishMeaning: 'Synonym of ${word.word}',
                        persianMeaning: entry.value.persian,
                        examples: [],
                        synonymsByLevel: {},
                        antonyms: [],
                        collocations: [],
                      );
                      ref
                          .read(dictionaryProvider.notifier)
                          .saveWordToFlashcards(tempWord);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${entry.value.word} '
                            '${AppLocalizations.getString('word_added_to_leitner', isPersian)}',
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: levelColor.withValues(alpha: 0.1),
                        border: Border.all(
                          color: levelColor.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${entry.key}: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: levelColor,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '${entry.value.word} ',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => onSpeak(entry.value.word),
                            child: Icon(
                              Icons.volume_up_rounded,
                              size: 16,
                              color: levelColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
