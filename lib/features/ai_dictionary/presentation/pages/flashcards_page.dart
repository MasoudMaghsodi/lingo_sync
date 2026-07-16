import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/localization/app_localizations.dart';
import '../providers/flashcards_provider.dart';
import 'all_flashcards_page.dart';
import 'all_grammar_page.dart'; // 🚀 ایمپورت صفحه جدید گرامر

class FlashcardsPage extends ConsumerStatefulWidget {
  const FlashcardsPage({super.key});

  @override
  ConsumerState<FlashcardsPage> createState() => _FlashcardsPageState();
}

class _FlashcardsPageState extends ConsumerState<FlashcardsPage> {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.45);
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  void _handleReview(
    int flashcardId,
    bool remembered,
    Map<String, dynamic> currentData,
  ) {
    HapticFeedback.lightImpact();
    setState(() => _isFlipped = false);
    ref
        .read(flashcardsProvider.notifier)
        .reviewCard(flashcardId, remembered, currentData);
  }

  Future<void> _handleRefresh() async {
    ref.invalidate(flashcardsProvider);
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flashcardsState = ref.watch(flashcardsProvider);
    final theme = Theme.of(context);
    final isPersian = ref.watch(isPersianProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.getString('smart_anki', isPersian)),
        actions: [
          // 🚀 دکمه جدید گنجینه گرامر
          IconButton(
            icon: Icon(
              Icons.rule_folder_outlined,
              color: theme.colorScheme.primary,
            ),
            tooltip: AppLocalizations.getString(
              'grammar_vault_title',
              isPersian,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AllGrammarPage()),
              );
            },
          ),
          // دکمه آرشیو لغات
          IconButton(
            icon: Icon(
              Icons.inventory_2_outlined,
              color: theme.colorScheme.primary,
            ),
            tooltip: AppLocalizations.getString(
              'archive_all_tooltip',
              isPersian,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AllFlashcardsPage(),
                ),
              ).then((_) => _handleRefresh());
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          flashcardsState.when(
            loading: () => Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            ),
            error: (error, _) => Center(
              child: Text(
                AppLocalizations.getString(
                  'flashcards_loading_error',
                  isPersian,
                ),
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
            data: (flashcards) {
              if (flashcards.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _handleRefresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.3,
                      ),
                      Icon(
                        Icons.done_all_rounded,
                        size: 80,
                        color: Colors.green.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          AppLocalizations.getString(
                            'flashcards_all_done',
                            isPersian,
                          ),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final currentCard = flashcards.first;
              final globalDict = currentCard['global_dictionary'] ?? {};
              final aiAnalysis = globalDict['ai_analysis'] ?? {};
              final word =
                  aiAnalysis['word'] ?? globalDict['word'] ?? 'Unknown';

              return RefreshIndicator(
                onRefresh: _handleRefresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Text(
                              '${flashcards.length} '
                              '${AppLocalizations.getString('cards_left_suffix', isPersian)}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  if (!_isFlipped) {
                                    HapticFeedback.selectionClick();
                                    setState(() => _isFlipped = true);
                                  }
                                },
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 500),
                                  transitionBuilder:
                                      (
                                        Widget child,
                                        Animation<double> animation,
                                      ) {
                                        final rotateAnim =
                                            Tween(begin: pi, end: 0.0).animate(
                                              CurvedAnimation(
                                                parent: animation,
                                                curve: Curves.easeInOut,
                                              ),
                                            );
                                        return AnimatedBuilder(
                                          animation: rotateAnim,
                                          child: child,
                                          builder: (context, widget) {
                                            final isUnder =
                                                (ValueKey(_isFlipped) !=
                                                widget?.key);
                                            var tilt =
                                                ((animation.value - 0.5).abs() -
                                                    0.5) *
                                                0.003;
                                            tilt *= isUnder ? -1.0 : 1.0;
                                            final value = isUnder
                                                ? min(rotateAnim.value, pi / 2)
                                                : rotateAnim.value;
                                            return Transform(
                                              transform: Matrix4.rotationY(
                                                value,
                                              )..setEntry(3, 0, tilt),
                                              alignment: Alignment.center,
                                              child: widget,
                                            );
                                          },
                                        );
                                      },
                                  child: _isFlipped
                                      ? _buildCardBack(
                                          word,
                                          aiAnalysis,
                                          theme,
                                          isPersian,
                                          key: const ValueKey(true),
                                        )
                                      : _buildCardFront(
                                          word,
                                          theme,
                                          isPersian,
                                          key: const ValueKey(false),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            AnimatedOpacity(
                              opacity: _isFlipped ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: IgnorePointer(
                                ignoring: !_isFlipped,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red.shade50,
                                          foregroundColor: Colors.red,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          elevation: 0,
                                        ),
                                        onPressed: () => _handleReview(
                                          currentCard['id'],
                                          false,
                                          currentCard,
                                        ),
                                        icon: const Icon(Icons.close),
                                        label: Text(
                                          AppLocalizations.getString(
                                            'forgot',
                                            isPersian,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          elevation: 5,
                                          shadowColor: Colors.green.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                        onPressed: () => _handleReview(
                                          currentCard['id'],
                                          true,
                                          currentCard,
                                        ),
                                        icon: const Icon(Icons.check),
                                        label: Text(
                                          AppLocalizations.getString(
                                            'remembered',
                                            isPersian,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCardFront(
    String word,
    ThemeData theme,
    bool isPersian, {
    required Key key,
  }) {
    return Container(
      key: key,
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                word.toUpperCase(),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          IconButton(
            icon: const Icon(Icons.volume_up, size: 48, color: Colors.white70),
            onPressed: () => _speak(word),
          ),
          const SizedBox(height: 48),
          Text(
            AppLocalizations.getString('tap_to_reveal', isPersian),
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack(
    String word,
    Map<String, dynamic> aiAnalysis,
    ThemeData theme,
    bool isPersian, {
    required Key key,
  }) {
    final examples = aiAnalysis['examples'] as List<dynamic>? ?? [];

    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    word.toUpperCase(),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.volume_up, color: theme.colorScheme.primary),
                  onPressed: () => _speak(word),
                ),
              ],
            ),
            if (aiAnalysis['part_of_speech'] != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  aiAnalysis['part_of_speech'],
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            const Divider(height: 32),
            Text(
              isPersian
                  ? (aiAnalysis['persian_meaning'] ?? '')
                  : (aiAnalysis['english_meaning'] ?? ''),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              isPersian
                  ? (aiAnalysis['english_meaning'] ?? '')
                  : (aiAnalysis['persian_meaning'] ?? ''),
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            if (examples.isNotEmpty) ...[
              Text(
                AppLocalizations.getString('example', isPersian),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  examples.first.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
