import 'package:flutter/material.dart';
import 'package:lingo_sync/core/localization/app_localizations.dart';

/// The collapsible CEFR-level / part-of-speech filter panel shown at the
/// top of `AllFlashcardsPage`. Purely presentational — the currently
/// selected filters live in the parent page (since they drive the actual
/// list filtering there); this widget only renders the chips and reports
/// toggles/clears via callbacks.
class ArchiveFiltersPanel extends StatelessWidget {
  static const cefrLevels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
  static const partsOfSpeech = [
    'Noun',
    'Verb',
    'Adjective',
    'Adverb',
    'Grammar',
  ];

  final List<String> selectedCefrLevels;
  final List<String> selectedPartsOfSpeech;
  final bool isPersian;
  final void Function(String level, bool selected) onCefrToggled;
  final void Function(String pos, bool selected) onPosToggled;
  final VoidCallback onClearFilters;

  const ArchiveFiltersPanel({
    super.key,
    required this.selectedCefrLevels,
    required this.selectedPartsOfSpeech,
    required this.isPersian,
    required this.onCefrToggled,
    required this.onPosToggled,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExpansionTile(
      title: Text(
        AppLocalizations.getString('filters', isPersian),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
      leading: Icon(
        Icons.filter_alt_outlined,
        color: theme.colorScheme.primary,
      ),
      trailing: TextButton(
        onPressed: onClearFilters,
        child: Text(
          AppLocalizations.getString('clear_filters', isPersian),
          style: const TextStyle(color: Colors.redAccent),
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CEFR Levels:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: cefrLevels.map((level) {
                  final isSelected = selectedCefrLevels.contains(level);
                  return FilterChip(
                    label: Text(level),
                    selected: isSelected,
                    onSelected: (checked) => onCefrToggled(level, checked),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                '${AppLocalizations.getString('part_of_speech', isPersian)}:',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: partsOfSpeech.map((pos) {
                  final isSelected = selectedPartsOfSpeech.contains(pos);
                  return FilterChip(
                    label: Text(pos),
                    selected: isSelected,
                    onSelected: (checked) => onPosToggled(pos, checked),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
