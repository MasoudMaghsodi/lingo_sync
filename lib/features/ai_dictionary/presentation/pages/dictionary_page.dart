import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lingo_sync/core/exceptions/app_exceptions.dart';
import 'package:lingo_sync/core/services/error_handler_service.dart';
// import '../../../../core/providers/pomodoro_provider.dart';
import '../providers/dictionary_provider.dart';
import '../../data/models/word_analysis_model.dart';
import 'video_lesson_page.dart';

class DictionaryPage extends ConsumerStatefulWidget {
  const DictionaryPage({super.key});

  @override
  ConsumerState<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends ConsumerState<DictionaryPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _ytController = TextEditingController();
  final FlutterTts _flutterTts = FlutterTts();

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
    if (text.trim().isNotEmpty) await _flutterTts.speak(text);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _ytController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  void _analyzeVideo() {
    final url = _ytController.text.trim();
    if (url.isEmpty) return;

    FocusScope.of(context).unfocus();
    ref.read(videoProcessingProvider.notifier).analyzeYoutubeVideo(url);
  }

  void _saveWordToAnki(WordAnalysis wordData) async {
    HapticFeedback.lightImpact();
    try {
      await ref
          .read(dictionaryProvider.notifier)
          .saveWordToFlashcards(wordData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('به جعبه لایتنر اضافه شد!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final message = e is AppException
            ? errorHandler.getUserMessage(e)
            : 'خطا در ذخیره';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchState = ref.watch(dictionaryProvider);
    final videoState = ref.watch(videoProcessingProvider);
    final isProcessingVideo = videoState.isLoading;

    ref.listen(videoProcessingProvider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        final error = next.error;
        final message = error is AppException
            ? errorHandler.getUserMessage(error)
            : 'خطا در پردازش ویدیو. دوباره تلاش کنید.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      } else if (next.hasValue && next.value != null && !next.isLoading) {
        _ytController.clear();
        final videoData = next.value!;
        ref.invalidate(videoProcessingProvider);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoLessonPage(videoData: videoData),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'AI Hub',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        // actions: [
        //   // 🚀 دکمه پومودورو در نوار بالایی برای فعال‌سازی راحت
        //   IconButton(
        //     icon: const Icon(Icons.timer_outlined),
        //     onPressed: () {
        //       ref.read(pomodoroProvider.notifier).setVisibility(true);
        //       ref.read(pomodoroProvider.notifier).toggleTimer();
        //     },
        //   ),
        // ],
      ),
      body: Stack(
        // 🚀 اضافه شدن Stack برای پومودورو
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.smart_display_rounded,
                              color: theme.colorScheme.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'درسنامه ویدیویی هوشمند',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _ytController,
                          decoration: InputDecoration(
                            hintText: 'لینک یوتیوب را وارد کنید...',
                            prefixIcon: const Icon(Icons.link),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isProcessingVideo ? null : _analyzeVideo,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: isProcessingVideo
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'استخراج خلاصه، گرامر و لغات',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  TextField(
                    controller: _searchController,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    decoration: InputDecoration(
                      hintText: 'جستجوی پیشرفته لغت...',
                      filled: true,
                      prefixIcon: Icon(
                        Icons.search,
                        color: theme.colorScheme.primary,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          Icons.send_rounded,
                          color: theme.colorScheme.primary,
                        ),
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          ref
                              .read(dictionaryProvider.notifier)
                              .analyzeWord(_searchController.text);
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    onSubmitted: (value) => ref
                        .read(dictionaryProvider.notifier)
                        .analyzeWord(value),
                  ),

                  const SizedBox(height: 24),
                  Expanded(
                    child: searchState.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, _) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            error is AppException
                                ? errorHandler.getUserMessage(error)
                                : 'خطا در دریافت اطلاعات لغت. دوباره تلاش کنید.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                      ),
                      data: (WordAnalysis? wordData) {
                        if (wordData == null) {
                          return const Center(
                            child: Text(
                              'کلمه‌ای را جستجو کنید تا جادوی هوش مصنوعی را ببینید.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }
                        return _buildWordResult(wordData, theme);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordResult(WordAnalysis wordData, ThemeData theme) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              wordData.word.toUpperCase(),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: theme.colorScheme.primary,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.volume_up_rounded,
                color: theme.colorScheme.primary,
                size: 30,
              ),
              onPressed: () => _speak(wordData.word),
            ),
          ],
        ),
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              wordData.partOfSpeech,
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.primary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => _saveWordToAnki(wordData),
          icon: const Icon(Icons.bookmark_add_rounded),
          label: const Text('افزودن به مرور (Anki)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
        const SizedBox(height: 32),
        _buildSectionTitle('معنی / Definition', theme),
        Text(
          wordData.englishMeaning,
          style: const TextStyle(
            fontSize: 18,
            height: 1.6,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          wordData.persianMeaning,
          style: const TextStyle(fontSize: 18, height: 1.6, color: Colors.grey),
        ),

        if (wordData.examples.isNotEmpty) ...[
          const SizedBox(height: 32),
          _buildSectionTitle('مثال‌ها / Examples', theme),
          ...wordData.examples.map(
            (ex) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Text(
                  ex,
                  style: const TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],

        if (wordData.synonymsByLevel.isNotEmpty) ...[
          const SizedBox(height: 32),
          _buildSectionTitle('مترادف‌ها (لانگ‌پرس = افزودن به انکی)', theme),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: wordData.synonymsByLevel.entries.map((entry) {
              return Material(
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onLongPress: () {
                    final tempWord = WordAnalysis(
                      word: entry.value.word,
                      partOfSpeech: wordData.partOfSpeech,
                      englishMeaning: 'Synonym of ${wordData.word}',
                      persianMeaning: entry.value.persian,
                      examples: [],
                      synonymsByLevel: {},
                      antonyms: [],
                      collocations: [],
                    );
                    _saveWordToAnki(tempWord);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.touch_app_rounded,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${entry.key}: ${entry.value.word}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            Icons.volume_up_rounded,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          onPressed: () => _speak(entry.value.word),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(width: 4, height: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
