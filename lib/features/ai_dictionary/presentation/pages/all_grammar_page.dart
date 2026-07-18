import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lingo_sync/core/constants/app_constants.dart';
import 'package:lingo_sync/core/localization/app_localizations.dart';
import 'package:lingo_sync/core/services/tts_service.dart';
import '../../data/models/video_analysis_model.dart';
import '../../../../core/providers/settings_provider.dart';

class AllGrammarPage extends ConsumerStatefulWidget {
  const AllGrammarPage({super.key});

  @override
  ConsumerState<AllGrammarPage> createState() => _AllGrammarPageState();
}

class _AllGrammarPageState extends ConsumerState<AllGrammarPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Cached in initState — see the note in VideoLessonPage for why
  // ref.read must never be called inside dispose().
  late final TtsService _tts;

  List<VideoAnalysis> _videoAnalyses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tts = ref.read(ttsServiceProvider);
    _loadAllGrammars();
  }

  Future<void> _speak(String text) => _tts.speak(text);

  Future<void> _loadAllGrammars() async {
    try {
      // دریافت تمام ویدیوهای پردازش شده
      final response = await _supabase
          .from('video_analysis')
          .select('video_id, grammar_points');

      if (mounted) {
        setState(() {
          _videoAnalyses = (response as List).map((data) {
            return VideoAnalysis(
              videoId: data['video_id'],
              summary: '', // در این صفحه نیازی به خلاصه نداریم
              fullTranscriptTranslation: '',
              grammarPoints: (data['grammar_points'] as List)
                  .map((e) => GrammarPoint.fromJson(e))
                  .toList(),
              vocabulary: [], // نیازی به لغات نداریم
            );
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPersian = ref.watch(isPersianProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.getString('grammar_vault_title', isPersian),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _videoAnalyses.isEmpty
          ? Center(
              child: Text(
                AppLocalizations.getString('no_grammar_points', isPersian),
                style: const TextStyle(color: Colors.grey),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadAllGrammars,
              child: ListView.builder(
                padding: EdgeInsets.all(AppConstants.standardPadding),
                itemCount: _videoAnalyses.length,
                itemBuilder: (context, index) {
                  final video = _videoAnalyses[index];
                  // اگر ویدیویی نکته گرامری نداشت، نشان داده نشود
                  if (video.grammarPoints.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Card(
                    margin: EdgeInsets.only(
                      bottom: AppConstants.standardPadding,
                    ),
                    child: ExpansionTile(
                      initiallyExpanded: index == 0, // اولین مورد باز باشد
                      leading: Icon(
                        Icons.smart_display_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      title: Text(
                        'Lesson from Video: ${video.videoId.substring(0, 6)}...',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        '${video.grammarPoints.length} '
                        '${AppLocalizations.getString('grammar_points_suffix', isPersian)}',
                      ),
                      childrenPadding: EdgeInsets.all(
                        AppConstants.standardPadding,
                      ),
                      children: video.grammarPoints.map((grammar) {
                        return Container(
                          margin: EdgeInsets.only(
                            bottom: AppConstants.standardPadding,
                          ),
                          padding: EdgeInsets.all(AppConstants.standardPadding),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(
                              AppConstants.standardBorderRadius,
                            ),
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                grammar.structureName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const Divider(height: 24),
                              Text(
                                "👶 ${grammar.persianExplanation}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.6,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.standardBorderRadius,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        grammar.exampleFromTranscript,
                                        style: const TextStyle(
                                          fontStyle: FontStyle.italic,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.volume_up,
                                        color: theme.colorScheme.primary,
                                      ),
                                      onPressed: () =>
                                          _speak(grammar.exampleFromTranscript),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
