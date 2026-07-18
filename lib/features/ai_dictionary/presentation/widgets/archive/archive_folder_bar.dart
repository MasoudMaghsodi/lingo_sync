import 'package:flutter/material.dart';

/// Horizontal scrollable row of folder chips at the top of
/// `AllFlashcardsPage` (below the filters panel). Long-pressing a
/// user-created folder opens its management options (rename/delete) —
/// system folders ('All', 'General', 'Grammar') silently ignore
/// long-press, exactly as before.
class ArchiveFolderBar extends StatelessWidget {
  final List<String> folders; // Already includes 'All' as the first entry.
  final String currentFolder;
  final ValueChanged<String> onFolderSelected;
  final ValueChanged<String> onFolderLongPress;

  const ArchiveFolderBar({
    super.key,
    required this.folders,
    required this.currentFolder,
    required this.onFolderSelected,
    required this.onFolderLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 50,
      color: theme.colorScheme.surface,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: folders.map((folder) {
          final isSelected = currentFolder == folder;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onLongPress: () => onFolderLongPress(folder),
              child: ChoiceChip(
                label: Text(folder),
                selected: isSelected,
                onSelected: (_) => onFolderSelected(folder),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
