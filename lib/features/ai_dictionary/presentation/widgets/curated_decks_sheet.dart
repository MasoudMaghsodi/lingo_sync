import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingo_sync/core/providers/settings_provider.dart';
import '../../data/services/anki_import_service.dart';
import '../providers/flashcards_provider.dart';

class CuratedDecksSheet extends ConsumerStatefulWidget {
  const CuratedDecksSheet({super.key});

  @override
  ConsumerState<CuratedDecksSheet> createState() => _CuratedDecksSheetState();
}

class _CuratedDecksSheetState extends ConsumerState<CuratedDecksSheet> {
  int _selectedDeckIndex = 0;
  bool _isLoading = false;
  List<AnkiCardItem> _deckCards = [];
  bool _isImporting = false;

  final List<Map<String, String>> _decks = [
    {
      'id': 'collins_500',
      'title': '۵۰۰ واژه حیاتی کالینز',
      'titleEn': '500 Essential Collins Words',
      'subtitle': 'پرتکرارترین واژگان آزمون‌های بین‌المللی',
      'count': '500 Words',
      'path': 'assets/data/vocab_collins_500.json',
      'color': '0xFF3B82F6', // Blue
      'badge': 'B1 - B2',
    },
    {
      'id': 'vocab_1100',
      'title': '۱۱۰۰ واژه ضروری',
      'titleEn': '1100 Words You Need to Know',
      'subtitle': 'کتاب مرجع تافل، آیلتس و GRE',
      'count': '1100 Words',
      'path': 'assets/data/vocab_1100.json',
      'color': '0xFF8B5CF6', // Purple
      'badge': 'C1 - C2',
    },
    {
      'id': 'sentences_620',
      'title': '۶۲۰ جمله طلایی مکالمه',
      'titleEn': '620 Key English Sentences',
      'subtitle': 'ساختارهای نیتیو برای اسپیکینگ روان',
      'count': '620 Sentences',
      'path': 'assets/data/sentences_620.json',
      'color': '0xFF10B981', // Emerald
      'badge': 'Fluent Speaking',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSelectedDeck();
  }

  Future<void> _loadSelectedDeck() async {
    setState(() => _isLoading = true);
    final deck = _decks[_selectedDeckIndex];
    final service = ref.read(ankiImportServiceProvider);
    final cards = await service.loadBundledDeck(
      deck['path']!,
      folder: deck['titleEn']!,
    );
    if (!mounted) return;
    setState(() {
      _deckCards = cards;
      _isLoading = false;
    });
  }

  Future<void> _importCurrentDeckToLeitner() async {
    if (_deckCards.isEmpty) return;

    setState(() => _isImporting = true);
    await HapticFeedback.mediumImpact();

    final service = ref.read(ankiImportServiceProvider);
    final res = await service.importCards(_deckCards);

    if (!mounted) return;
    setState(() => _isImporting = false);

    res.fold(
      onSuccess: (count) {
        ref.invalidate(flashcardsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 $count کارت با موفقیت به جعبه لایتنر اضافه شد!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      onFailure: (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در افزودن به لایتنر: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPersian = ref.watch(isPersianProvider);
    final isDark = theme.brightness == Brightness.dark;
    final currentDeckMeta = _decks[_selectedDeckIndex];
    final deckColor = Color(int.parse(currentDeckMeta['color']!));

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131722) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Top Drag handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPersian
                          ? 'مجموعه‌های مرجع واژگان'
                          : 'Curated Vocabulary Decks',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      isPersian
                          ? 'کالینز، ۱۱۰۰ واژه و ۶۲۰ جمله کاربردی'
                          : 'Collins 500, 1100 Words & 620 Sentences',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Deck Selector Horizontal Pills
          SizedBox(
            height: 52,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _decks.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final deck = _decks[index];
                final isSelected = _selectedDeckIndex == index;
                final color = Color(int.parse(deck['color']!));

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedDeckIndex = index);
                    _loadSelectedDeck();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.15)
                          : (isDark
                                ? const Color(0xFF1E2333)
                                : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? color : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isPersian ? deck['title']! : deck['titleEn']!,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? color
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Action Bar: Add all to Leitner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: deckColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: deckColor.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPersian
                              ? currentDeckMeta['subtitle']!
                              : currentDeckMeta['titleEn']!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: deckColor,
                          ),
                        ),
                        Text(
                          '${_deckCards.length} ${isPersian ? 'کارت آماده مطالعه' : 'cards ready'}',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: (_deckCards.isNotEmpty && !_isImporting)
                        ? _importCurrentDeckToLeitner
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: deckColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _isImporting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.playlist_add_rounded, size: 18),
                    label: Text(
                      isPersian ? 'افزودن به لایتنر' : 'Add to Leitner',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Cards List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _deckCards.length,
                    itemBuilder: (context, index) {
                      final card = _deckCards[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF191E2C)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.08,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: deckColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: deckColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        card.word,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      if (card.phonetic.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          card.phonetic,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: deckColor,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    card.meaning,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.85),
                                    ),
                                  ),
                                  if (card.example.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      card.example,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontStyle: FontStyle.italic,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.55),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
