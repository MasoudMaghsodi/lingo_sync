import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/services/tts_service.dart';
import '../../data/models/video_analysis_model.dart';
import '../../data/models/word_analysis_model.dart';
import '../../data/repositories/video_analysis_repository.dart';
import '../providers/dictionary_provider.dart';
import '../widgets/video_lesson/ai_chat_sheet.dart';
import '../widgets/video_lesson/grammar_tab.dart';
import '../widgets/video_lesson/summary_tab.dart';
import '../widgets/video_lesson/transcript_tab.dart';
import '../widgets/video_lesson/vocabulary_tab.dart';

class VideoLessonPage extends ConsumerStatefulWidget {
  final VideoAnalysis videoData;
  const VideoLessonPage({super.key, required this.videoData});

  @override
  ConsumerState<VideoLessonPage> createState() => _VideoLessonPageState();
}

class _VideoLessonPageState extends ConsumerState<VideoLessonPage> {
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _aiQuestionController = TextEditingController();

  late final TtsService _tts;

  bool _isLoadingNote = true;
  bool _isSavingNote = false;
  bool _isAskingAi = false;
  String? _aiResponse;
  bool _isSpeakingAi = false;

  @override
  void initState() {
    super.initState();
    _tts = ref.read(ttsServiceProvider);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeakingAi = false);
    });
    _loadNote();
  }

  Future<void> _speak(String text) => _tts.speak(text);

  Future<void> _toggleAiSpeech() async {
    final text = _aiResponse;
    if (text == null) return;
    if (_isSpeakingAi) {
      await _tts.stop();
      setState(() => _isSpeakingAi = false);
    } else {
      setState(() => _isSpeakingAi = true);
      await _tts.speak(text);
    }
  }

  Future<void> _loadNote() async {
    // 🚀 ارتباط با دیتابیس کاملاً به ریپازیتوری محول شد
    final repository = ref.read(videoAnalysisRepositoryProvider);
    final result = await repository.loadUserNote(widget.videoData.videoId);

    if (mounted) {
      result.when(
        success: (note) {
          setState(() {
            _noteController.text = note ?? '';
            _isLoadingNote = false;
          });
        },
        failure: (_) => setState(() => _isLoadingNote = false),
      );
    }
  }

  Future<void> _saveNote() async {
    final isPersian = ref.read(isPersianProvider);
    setState(() => _isSavingNote = true);

    // 🚀 ذخیره‌سازی از طریق ریپازیتوری با پشتیبانی از هندلینگ خطای استاندارد
    final repository = ref.read(videoAnalysisRepositoryProvider);
    final result = await repository.saveUserNote(
      widget.videoData.videoId,
      _noteController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSavingNote = false);

      result.when(
        success: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.getString('note_saved', isPersian),
              ),
              backgroundColor: Colors.green,
            ),
          );
        },
        failure: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.getString('note_save_error', isPersian),
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        },
      );
    }
  }

  bool _canAskAi() {
    // 🚀 حل مشکل ناهمگام با استفاده از پرووایدرِ سینک شده در فازهای قبل
    final prefs = ref.read(sharedPreferencesProvider);
    final timestamps = prefs.getStringList('ai_ask_timestamps') ?? [];
    final now = DateTime.now();

    final recentRequests = timestamps
        .where((ts) => now.difference(DateTime.parse(ts)).inHours < 1)
        .toList();

    if (recentRequests.length >= 2) return false;

    recentRequests.add(now.toIso8601String());
    prefs.setStringList(
      'ai_ask_timestamps',
      recentRequests,
    ); // به صورت همزمان آپدیت می‌شود
    return true;
  }

  Future<void> _askAi() async {
    final question = _aiQuestionController.text.trim();
    if (question.isEmpty) return;

    final isPersian = ref.read(isPersianProvider);

    if (!_canAskAi()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.getString('ai_question_limit', isPersian),
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      _isAskingAi = true;
      _aiResponse = null;
    });

    // 🚀 ارسال ریکوئست از طریق کلاینت استاندارد (بدون http هاردکد شده)
    final repository = ref.read(videoAnalysisRepositoryProvider);
    final result = await repository.askVideoAi(
      widget.videoData.videoId,
      question,
    );

    if (mounted) {
      setState(() => _isAskingAi = false);

      result.when(
        success: (answer) => setState(() => _aiResponse = answer),
        failure: (error) {
          final prefix = AppLocalizations.getString(
            'ai_connection_error',
            isPersian,
          );
          // نمایش پیام خطای استاندارد به کاربر
          setState(() => _aiResponse = '$prefix\n${error.message}');
        },
      );
    }
  }

  Future<void> _saveGrammarToAnki(GrammarPoint grammar) async {
    final isPersian = ref.read(isPersianProvider);
    final tempWord = WordAnalysis(
      word: grammar.structureName,
      partOfSpeech: 'Grammar',
      englishMeaning: grammar.exampleFromTranscript,
      persianMeaning: grammar.persianExplanation,
      examples: [grammar.exampleFromTranscript],
      synonymsByLevel: {},
      antonyms: [],
      collocations: [],
    );
    try {
      await ref
          .read(dictionaryProvider.notifier)
          .saveWordToFlashcards(tempWord, folder: 'Grammar');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.getString('grammar_added', isPersian),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.getString('save_error', isPersian)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _openAiChatSheet() {
    final isPersian = ref.read(isPersianProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return AiChatSheetContent(
              questionController: _aiQuestionController,
              isAsking: _isAskingAi,
              response: _aiResponse,
              isSpeakingResponse: _isSpeakingAi,
              isPersian: isPersian,
              onAsk: () async {
                setSheetState(() => _isAskingAi = true);
                await _askAi();
                setSheetState(() => _isAskingAi = false);
              },
              onToggleSpeech: () async {
                await _toggleAiSpeech();
                setSheetState(() {});
              },
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _tts.stop();
    _tts.clearCompletionHandler();
    _noteController.dispose();
    _aiQuestionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPersian = ref.watch(isPersianProvider);
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            AppLocalizations.getString('video_lesson_title', isPersian),
          ),
          bottom: TabBar(
            isScrollable: true,
            labelColor: theme.colorScheme.primary,
            indicatorColor: theme.colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(
                icon: const Icon(Icons.article_outlined),
                text: AppLocalizations.getString(
                  'tab_summary_notes',
                  isPersian,
                ),
              ),
              Tab(
                icon: const Icon(Icons.subtitles_outlined),
                text: AppLocalizations.getString('tab_transcript', isPersian),
              ),
              Tab(
                icon: const Icon(Icons.child_care_rounded),
                text: AppLocalizations.getString('tab_grammar', isPersian),
              ),
              Tab(
                icon: const Icon(Icons.school_outlined),
                text: AppLocalizations.getString('tab_vocabulary', isPersian),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openAiChatSheet,
          backgroundColor: theme.colorScheme.primary,
          icon: const Icon(Icons.psychology, color: Colors.white),
          label: Text(
            AppLocalizations.getString('chat_with_ai', isPersian),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: TabBarView(
          children: [
            VideoSummaryTab(
              summary: widget.videoData.summary,
              noteController: _noteController,
              isLoadingNote: _isLoadingNote,
              isSavingNote: _isSavingNote,
              onSaveNote: _saveNote,
              isPersian: isPersian,
            ),
            VideoTranscriptTab(
              transcript: widget.videoData.fullTranscriptTranslation,
            ),
            VideoGrammarTab(
              grammarPoints: widget.videoData.grammarPoints,
              isPersian: isPersian,
              onSpeak: _speak,
              onSaveToAnki: _saveGrammarToAnki,
            ),
            VideoVocabularyTab(
              vocabulary: widget.videoData.vocabulary,
              isPersian: isPersian,
              onSpeak: _speak,
            ),
          ],
        ),
      ),
    );
  }
}
