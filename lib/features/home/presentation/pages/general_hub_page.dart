import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingo_sync/core/layout/main_navigation.dart';
import 'package:lingo_sync/core/providers/settings_provider.dart';
import 'package:lingo_sync/core/widgets/three_dimensional_parallax_card.dart';
import 'package:lingo_sync/features/ai_dictionary/presentation/widgets/anki_import_sheet.dart';
import 'package:lingo_sync/features/ai_dictionary/presentation/widgets/curated_decks_sheet.dart';

class GeneralHubPage extends ConsumerStatefulWidget {
  const GeneralHubPage({super.key});

  @override
  ConsumerState<GeneralHubPage> createState() => _GeneralHubPageState();
}

class _GeneralHubPageState extends ConsumerState<GeneralHubPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCuratedDecks() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CuratedDecksSheet(),
    );
  }

  void _openAnkiImporter() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AnkiImportSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPersian = ref.watch(isPersianProvider);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 18, right: 18, top: 12, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Search Box
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF151926) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onSubmitted: (query) {
                if (query.trim().isNotEmpty) {
                  ref
                      .read(mainNavigationTabProvider.notifier)
                      .setTab(4); // Dictionary
                }
              },
              decoration: InputDecoration(
                hintText: isPersian
                    ? 'جستجوی هوشمند در واژه‌نامه انگلیسی...'
                    : 'Search English Dictionary & idioms...',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: theme.colorScheme.primary,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                  onPressed: () {
                    if (_searchController.text.trim().isNotEmpty) {
                      ref.read(mainNavigationTabProvider.notifier).setTab(4);
                    }
                  },
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 2. Section: Curated Vocabulary Decks (کتاب‌های مرجع لغات)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isPersian
                    ? 'مجموعه‌های مرجع واژگان'
                    : 'Curated Vocab Collections',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: _openCuratedDecks,
                child: Text(
                  isPersian ? 'مشاهده همه' : 'View All',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 3 Big 3D Curated Cards
          Row(
            children: [
              Expanded(
                child: _buildDeckCard(
                  title: isPersian ? '۵۰۰ واژه کالینز' : 'Collins 500',
                  subtitle: isPersian ? 'پرکاربردترین لغات' : 'Most Frequent',
                  badge: 'B1-B2',
                  icon: Icons.menu_book_rounded,
                  color: const Color(0xFF3B82F6),
                  isDark: isDark,
                  theme: theme,
                  onTap: _openCuratedDecks,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDeckCard(
                  title: isPersian ? '۱۱۰۰ واژه ضروری' : '1100 Words',
                  subtitle: isPersian ? 'تافل و آیلتس' : 'Academic Core',
                  badge: 'C1-C2',
                  icon: Icons.school_rounded,
                  color: const Color(0xFF8B5CF6),
                  isDark: isDark,
                  theme: theme,
                  onTap: _openCuratedDecks,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildDeckCard(
                  title: isPersian ? '۶۲۰ جمله کلیدی' : '620 Sentences',
                  subtitle: isPersian ? 'مکالمه نیتیو' : 'Native Fluency',
                  badge: 'Phrases',
                  icon: Icons.chat_bubble_outline_rounded,
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                  theme: theme,
                  onTap: _openCuratedDecks,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDeckCard(
                  title: isPersian ? 'ایمپورت انکی' : 'Anki Importer',
                  subtitle: isPersian ? 'AnkiWeb & CSV' : 'Custom Decks',
                  badge: 'Anki',
                  icon: Icons.cloud_download_rounded,
                  color: const Color(0xFFEC4899),
                  isDark: isDark,
                  theme: theme,
                  onTap: _openAnkiImporter,
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // 3. Section: Flashcards & YouTube Video Extractor
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isPersian ? 'ابزارهای یادگیری عمومی' : 'General Learning Tools',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // YouTube Extractor Card
          ThreeDimensionalParallaxCard(
            borderRadius: BorderRadius.circular(20),
            glowColor: Colors.redAccent.withValues(alpha: 0.2),
            onTap: () {
              HapticFeedback.lightImpact();
              ref
                  .read(mainNavigationTabProvider.notifier)
                  .setTab(4); // Video/Dict
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF151926) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.smart_display_rounded,
                      color: Colors.redAccent,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPersian
                              ? 'استخراج واژگان از ویدیوهای یوتیوب'
                              : 'YouTube Video Vocabulary Extractor',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isPersian
                              ? 'مشاهده زیرنویس دوزبانه و افزودن لغات به لایتنر'
                              : 'Bilingual transcript & 1-tap Leitner addition',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Leitner Deck Card
          ThreeDimensionalParallaxCard(
            borderRadius: BorderRadius.circular(20),
            glowColor: Colors.deepPurpleAccent.withValues(alpha: 0.2),
            onTap: () {
              HapticFeedback.lightImpact();
              ref
                  .read(mainNavigationTabProvider.notifier)
                  .setTab(3); // Flashcards
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF151926) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.deepPurpleAccent.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.deepPurpleAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.style_rounded,
                      color: Colors.deepPurpleAccent,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPersian
                              ? 'جعبه لایتنر هوشمند (SRS)'
                              : 'Spaced Repetition Leitner Box',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isPersian
                              ? 'مرور کارت‌ها بر اساس فواصل فراموشی ابینگهاوس'
                              : 'Scientific retention with Ebbinghaus intervals',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeckCard({
    required String title,
    required String subtitle,
    required String badge,
    required IconData icon,
    required Color color,
    required bool isDark,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    return ThreeDimensionalParallaxCard(
      borderRadius: BorderRadius.circular(20),
      glowColor: color.withValues(alpha: 0.25),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151926) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
