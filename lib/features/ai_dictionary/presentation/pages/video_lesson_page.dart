// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lingo_sync/features/ai_dictionary/presentation/providers/dictionary_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/video_analysis_model.dart';
import '../../data/models/word_analysis_model.dart';

class VideoLessonPage extends ConsumerStatefulWidget {
  final VideoAnalysis videoData;
  const VideoLessonPage({super.key, required this.videoData});

  @override
  ConsumerState<VideoLessonPage> createState() => _VideoLessonPageState();
}

class _VideoLessonPageState extends ConsumerState<VideoLessonPage> {
  final FlutterTts _flutterTts = FlutterTts();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _aiQuestionController = TextEditingController();
  bool _isLoadingNote = true;
  bool _isSavingNote = false;
  bool _isAskingAi = false;
  String? _aiResponse;
  bool _isSpeakingAi = false;

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadNote();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.45);

    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeakingAi = false);
    });
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<void> _toggleAiSpeech(String text) async {
    if (_isSpeakingAi) {
      await _flutterTts.stop();
      setState(() => _isSpeakingAi = false);
    } else {
      setState(() => _isSpeakingAi = true);
      await _flutterTts.speak(text);
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
          const SnackBar(
            content: Text('یادداشت ذخیره شد.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطا در ذخیره یادداشت'),
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
    if (!await _canAskAi()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('محدودیت ۲ سوال در ساعت!'),
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
        Uri.parse('http://194.246.82.160:3002/api/ask_video_ai'),
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
        setState(() => _aiResponse = 'خطا در ارتباط با هوش مصنوعی: $e');
      }
    } finally {
      if (mounted) setState(() => _isAskingAi = false);
    }
  }

  void _saveGrammarToAnki(GrammarPoint grammar) async {
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
      final user = Supabase.instance.client.auth.currentUser;
      await Supabase.instance.client.from('flashcards').insert({
        'user_id': user?.id,
        'folder_name': 'Grammar',
        'ai_analysis': tempWord.toJson(),
        'repetition': 0,
        'interval': 0,
        'ease_factor': 2.5,
        'next_review_date': DateTime.now().toUtc().toIso8601String(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('گرامر به لایتنر اضافه شد'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطا در ذخیره'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openAiChatSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final theme = Theme.of(context);
            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (_, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                      left: 24,
                      right: 24,
                      top: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.psychology,
                              color: theme.colorScheme.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'پرسش از منتور AI',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'محدودیت: ۲ پرسش در ساعت.\nفقط سوالات مرتبط با همین ویدیو!',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _aiQuestionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'منظور از این اصطلاح در ویدیو چه بود؟...',
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _isAskingAi
                              ? null
                              : () async {
                                  setSheetState(() => _isAskingAi = true);
                                  await _askAi();
                                  setSheetState(() => _isAskingAi = false);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isAskingAi
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'ارسال پرسش',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                        const SizedBox(height: 16),
                        if (_aiResponse != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.05,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'پاسخ هوش مصنوعی:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        _isSpeakingAi
                                            ? Icons.stop_circle_rounded
                                            : Icons.play_circle_fill_rounded,
                                        color: theme.colorScheme.primary,
                                      ),
                                      onPressed: () =>
                                          _toggleAiSpeech(_aiResponse!),
                                    ),
                                  ],
                                ),
                                const Divider(),
                                // 🚀 متن قابل انتخاب (کپی کردن و ترنسلیت)
                                SelectableText(
                                  _aiResponse!,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    height: 1.8,
                                  ),
                                  cursorColor: theme.colorScheme.primary,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _noteController.dispose();
    _aiQuestionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text(
            'درسنامه ویدیویی',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          bottom: TabBar(
            isScrollable: true,
            labelColor: theme.colorScheme.primary,
            indicatorColor: theme.colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(icon: Icon(Icons.article_outlined), text: 'خلاصه و یادداشت'),
              Tab(icon: Icon(Icons.subtitles_outlined), text: 'ترنسکریپت'),
              Tab(icon: Icon(Icons.child_care_rounded), text: 'گرامر کودکانه'),
              Tab(icon: Icon(Icons.school_outlined), text: 'لغات'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openAiChatSheet,
          backgroundColor: theme.colorScheme.primary,
          icon: const Icon(Icons.psychology, color: Colors.white),
          label: const Text(
            'گپ با AI',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: TabBarView(
          children: [
            _buildSummaryTab(theme),
            _buildTranscriptTab(theme),
            _buildGrammarTab(theme),
            _buildVocabularyTab(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryTab(ThemeData theme) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              const Text(
                'خلاصه هوشمند',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
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
            child: Text(
              widget.videoData.summary,
              style: const TextStyle(
                fontSize: 16,
                height: 2.0,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Icon(Icons.edit_note_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              const Text(
                'یادداشت شخصی شما',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingNote)
            const Center(child: CircularProgressIndicator())
          else
            Container(
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
              child: TextField(
                controller: _noteController,
                maxLines: 8,
                style: const TextStyle(fontSize: 16, height: 1.8),
                decoration: InputDecoration(
                  hintText:
                      'نکات مهم این ویدیو را اینجا بنویسید...\n\n- نکته اول\n- نکته دوم',
                  hintStyle: TextStyle(
                    color: Colors.grey.withValues(alpha: 0.5),
                  ),
                  contentPadding: const EdgeInsets.all(24),
                  border: InputBorder.none,
                ),
              ),
            ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isSavingNote ? null : _saveNote,
            icon: const Icon(Icons.save_rounded),
            label: _isSavingNote
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : const Text(
                    'ذخیره یادداشت در سرور',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildTranscriptTab(ThemeData theme) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
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
            child: SelectableText(
              widget.videoData.fullTranscriptTranslation,
              style: const TextStyle(fontSize: 16, height: 2.0),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildGrammarTab(ThemeData theme) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: widget.videoData.grammarPoints.length,
      itemBuilder: (context, index) {
        final grammar = widget.videoData.grammarPoints[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
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
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        grammar.structureName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    // 🚀 دکمه ذخیره گرامر کاملاً مشخص شد
                    ElevatedButton.icon(
                      onPressed: () => _saveGrammarToAnki(grammar),
                      icon: const Icon(Icons.bookmark_add_rounded, size: 18),
                      label: const Text('افزودن به انکی'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary.withValues(
                          alpha: 0.1,
                        ),
                        foregroundColor: theme.colorScheme.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Divider(),
                ),
                Text(
                  "👶 توضیحات کودکانه:\n${grammar.persianExplanation}",
                  style: const TextStyle(fontSize: 16, height: 1.8),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'مثال در ویدیو:',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              grammar.exampleFromTranscript,
                              style: const TextStyle(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                height: 1.5,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.volume_up_rounded,
                              color: theme.colorScheme.primary,
                            ),
                            onPressed: () =>
                                _speak(grammar.exampleFromTranscript),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVocabularyTab(ThemeData theme) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: widget.videoData.vocabulary.length,
      itemBuilder: (context, index) {
        final word = widget.videoData.vocabulary[index];
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
                          onPressed: () => _speak(word.word),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.bookmark_add_rounded,
                            color: Colors.green,
                          ),
                          tooltip: 'افزودن به جعبه لایتنر',
                          onPressed: () async {
                            try {
                              await ref
                                  .read(dictionaryProvider.notifier)
                                  .saveWordToFlashcards(word);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('به لایتنر اضافه شد!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (_) {}
                          },
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
                const Text(
                  'مترادف‌ها بر اساس سطح (لانگ‌پرس = افزودن):',
                  style: TextStyle(
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
                    } else if (entry.key.contains('B'))
                      levelColor = Colors.blue;
                    else if (entry.key.contains('C'))
                      levelColor = Colors.orange;

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
                                '${entry.value.word} به لایتنر اضافه شد',
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
                                onTap: () => _speak(entry.value.word),
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
      },
    );
  }
}
