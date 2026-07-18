import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:lingo_sync/core/config/app_config.dart';
import 'package:lingo_sync/core/localization/app_localizations.dart';
import 'package:lingo_sync/core/services/tts_service.dart';
import 'package:lingo_sync/features/ai_dictionary/presentation/providers/dictionary_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/providers/settings_provider.dart';
import '../../data/models/video_analysis_model.dart';
import '../../data/models/word_analysis_model.dart';
import '../widgets/video_lesson/ai_chat_sheet.dart';
import '../widgets/video_lesson/grammar_tab.dart';
import '../widgets/video_lesson/summary_tab.dart';
import '../widgets/video_lesson/transcript_tab.dart';
import '../widgets/video_lesson/vocabulary_tab.dart';

/// Orchestrates the video lesson screen: owns all page-level state (the
/// personal note, the AI Q&A session) and wires it into four independent
/// tab widgets plus the AI chat sheet, each living in its own file under
/// `widgets/video_lesson/`. This class stays focused on state and
/// coordination, not layout.
class VideoLessonPage extends ConsumerStatefulWidget {
  final VideoAnalysis videoData;
  const VideoLessonPage({super.key, required this.videoData});

  @override
  ConsumerState<VideoLessonPage> createState() => _VideoLessonPageState();
}

class _VideoLessonPageState extends ConsumerState<VideoLessonPage> {
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _aiQuestionController = TextEditingController();

  // Cached in initState — Riverpod disallows ref.read/ref.watch inside
  // dispose() because the widget is already unmounting.
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
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final response = await Supabase.instance.client
          .from('user_notes')
          .select('content')
          .eq('user_id', userId)
          .eq('reference_id', widget.videoData.videoId)
          .maybeSingle();
      if (response != null && mounted) {
        setState(() => _noteController.text = response['content'] ?? '');
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingNote = false);
    }
  }

  Future<void> _saveNote() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final isPersian = ref.read(isPersianProvider);
    setState(() => _isSavingNote = true);
    try {
      await Supabase.instance.client.from('user_notes').upsert({
        'user_id': userId,
        'reference_id': widget.videoData.videoId,
        'note_type': 'video',
        'content': _noteController.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.getString('note_saved', isPersian)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.getString('note_save_error', isPersian),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingNote = false);
    }
  }

  Future<bool> _canAskAi() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamps = prefs.getStringList('ai_ask_timestamps') ?? [];
    final now = DateTime.now();
    final recentRequests = timestamps
        .where((ts) => now.difference(DateTime.parse(ts)).inHours < 1)
        .toList();
    if (recentRequests.length >= 2) return false;
    recentRequests.add(now.toIso8601String());
    await prefs.setStringList('ai_ask_timestamps', recentRequests);
    return true;
  }

  Future<void> _askAi() async {
    final question = _aiQuestionController.text.trim();
    if (question.isEmpty) return;
    final isPersian = ref.read(isPersianProvider);
    if (!await _canAskAi()) {
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
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.aiServerBaseUrl}/ask_video_ai'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'videoId': widget.videoData.videoId,
          'question': question,
        }),
      );
      if (response.statusCode == 200 && mounted) {
        setState(() => _aiResponse = jsonDecode(response.body)['answer']);
      } else {
        throw Exception('Server Error');
      }
    } catch (e) {
      if (mounted) {
        final prefix = AppLocalizations.getString(
          'ai_connection_error',
          isPersian,
        );
        setState(() => _aiResponse = '$prefix: $e');
      }
    } finally {
      if (mounted) setState(() => _isAskingAi = false);
    }
  }

  /// Saves a grammar point as a personal flashcard. Routes through the
  /// same [dictionaryProvider] path used for saving dictionary words
  /// (`folder: 'Grammar'`), instead of doing its own raw `flashcards`
  /// insert — this is what keeps every flashcard row in one consistent
  /// shape (`word_id` pointing at `global_dictionary`) instead of two
  /// divergent ones.
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
            backgroundColor: Colors.red,
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
        // A StatefulBuilder is required here (not just the outer page's
        // setState) because this sheet is its own route/overlay — the
        // page's setState does not rebuild content already shown in a
        // modal bottom sheet. setSheetState forces this sheet specifically
        // to redraw when _askAi's loading/response state, or the
        // play/stop icon, changes.
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
    // Uses the cached _tts field, NOT ref.read — see the note on that
    // field for why calling ref inside dispose() crashes.
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
