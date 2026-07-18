import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingo_sync/core/constants/app_constants.dart';
import 'package:lingo_sync/core/localization/app_localizations.dart';
import 'package:lingo_sync/core/services/tts_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/providers/settings_provider.dart';
import '../../data/models/video_analysis_model.dart';

/// Local-only grouping used purely for display in this page — unlike the
/// shared [VideoAnalysis] model (which represents a single freshly
/// processed video for [VideoLessonPage]), this carries the `title` and
/// `day_number` columns the vault needs to show which lesson a video
/// belongs to, without changing the shape other pages rely on.
class _GrammarVideoGroup {
  final String videoId;
  final String? title;
  final int? dayNumber;
  final List<GrammarPoint> grammarPoints;

  _GrammarVideoGroup({
    required this.videoId,
    required this.title,
    required this.dayNumber,
    required this.grammarPoints,
  });
}

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

  List<_GrammarVideoGroup> _videoGroups = [];
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
      // دریافت تمام ویدیوهای پردازش شده، همراه با عنوان و روز مربوطه —
      // ordered by day_number so the vault reads like a lesson-by-lesson
      // index instead of an unordered dump.
      final response = await _supabase
          .from('video_analysis')
          .select('video_id, title, day_number, grammar_points')
          .order('day_number', ascending: true);

      if (mounted) {
        setState(() {
          _videoGroups = (response as List).map((data) {
            return _GrammarVideoGroup(
              videoId: data['video_id'],
              title: data['title'] as String?,
              dayNumber: data['day_number'] as int?,
              grammarPoints: (data['grammar_points'] as List)
                  .map((e) => GrammarPoint.fromJson(e))
                  .toList(),
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
          : _videoGroups.isEmpty
          ? Center(
              child: Text(
                AppLocalizations.getString('no_grammar_points', isPersian),
                style: const TextStyle(color: Colors.grey),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadAllGrammars,
              child: ListView.builder(
                padding: const EdgeInsets.all(AppConstants.standardPadding),
                itemCount: _videoGroups.length,
                itemBuilder: (context, index) {
                  final video = _videoGroups[index];
                  // اگر ویدیویی نکته گرامری نداشت، نشان داده نشود
                  if (video.grammarPoints.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final dayLabel = video.dayNumber != null
                      ? '${AppLocalizations.getString('day', isPersian)} ${video.dayNumber}'
                      : null;
                  final title = video.title?.trim().isNotEmpty == true
                      ? video.title!
                      : 'Video ${video.videoId.substring(0, video.videoId.length.clamp(0, 6))}...';

                  return Card(
                    margin: const EdgeInsets.only(
                      bottom: AppConstants.standardPadding,
                    ),
                    child: ExpansionTile(
                      initiallyExpanded: index == 0, // اولین مورد باز باشد
                      leading: Icon(
                        Icons.smart_display_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      title: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        [
                          ?dayLabel,
                          '${video.grammarPoints.length} '
                              '${AppLocalizations.getString('grammar_points_suffix', isPersian)}',
                        ].join(' • '),
                      ),
                      childrenPadding: const EdgeInsets.all(
                        AppConstants.standardPadding,
                      ),
                      children: video.grammarPoints.map((grammar) {
                        return Container(
                          margin: const EdgeInsets.only(
                            bottom: AppConstants.standardPadding,
                          ),
                          padding: const EdgeInsets.all(
                            AppConstants.standardPadding,
                          ),
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
