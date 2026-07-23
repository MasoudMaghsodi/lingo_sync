import 'package:flutter/material.dart';
import 'package:lingo_sync/core/localization/app_localizations.dart';
import '../../../data/models/flashcard_entry.dart';

/// One expandable flashcard entry in `AllFlashcardsPage`'s archive list.
class ArchiveCardTile extends StatelessWidget {
  final FlashcardEntry entry;
  final bool isPersian;
  final Future<void> Function(String text) onSpeak;
  final void Function(FlashcardEntry entry) onMove;

  const ArchiveCardTile({
    super.key,
    required this.entry,
    required this.isPersian,
    required this.onSpeak,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          child: Text(
            entry.partOfSpeech.isNotEmpty
                ? entry.partOfSpeech.substring(0, 1).toUpperCase()
                : 'W',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          entry.word.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(
          '${AppLocalizations.getString('box', isPersian)} ${entry.repetition} • ${entry.folderName}',
        ),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isPersian ? entry.persianMeaning : entry.englishMeaning,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.drive_file_move_outline,
                      color: theme.colorScheme.secondary,
                    ),
                    tooltip: AppLocalizations.getString(
                      'move_tooltip',
                      isPersian,
                    ),
                    onPressed: () => onMove(entry),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.volume_up,
                      color: theme.colorScheme.primary,
                    ),
                    onPressed: () => onSpeak(entry.word),
                  ),
                ],
              ),
            ],
          ),
          const Divider(),
          Text(
            isPersian ? entry.englishMeaning : entry.persianMeaning,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          if (entry.examples.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Example: ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Expanded(
                  child: Text(
                    entry.examples.first,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: entry.synonymsByLevel.entries.map((e) {
              final levelColor = e.key.contains('A')
                  ? Colors.green
                  : (e.key.contains('B') ? Colors.blue : Colors.orange);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: levelColor.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${e.key}: ${e.value.word}',
                  style: TextStyle(
                    color: levelColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
