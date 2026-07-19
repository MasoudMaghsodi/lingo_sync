import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingo_sync/core/constants/app_constants.dart';
import 'package:lingo_sync/core/localization/app_localizations.dart';
import 'package:lingo_sync/core/services/tts_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/providers/settings_provider.dart';
import '../../data/models/video_analysis_model.dart';

/// Local-only grouping used purely for display in this page — carries
/// whatever is needed to build a human title ("Grammar video, Day 3")
/// without changing the shared [VideoAnalysis] model other pages rely on.
class _GrammarVideoGroup {
  final String videoId;
  final String? title;
  final int? dayNumber;
  final String? taskType;
  final List<GrammarPoint> grammarPoints;

  _GrammarVideoGroup({
    required this.videoId,
    required this.title,
    required this.dayNumber,
    required this.taskType,
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

  /// Turns a raw `task_type` string (e.g. "Listening", "Grammar",
  /// "Read articles") into a short, human label. Falls back to the raw
  /// value itself for anything not explicitly mapped, so a new task type
  /// added to `daily_tasks` later never just disappears from the title.
  String _taskTypeLabel(String? taskType, bool isPersian) {
    if (taskType == null) return '';
    final key = taskType.toLowerCase();
    const enMap = {
      'listening': 'Listening',
      'vocabulary': 'Vocabulary',
      'speaking': 'Speaking',
      'reading': 'Reading',
      'grammar': 'Grammar',
      'writing': 'Writing',
      'podcast': 'Podcast',
      'shadowing': 'Shadowing',
      'dictation': 'Dictation',
    };
    const faMap = {
      'listening': 'لیسینینگ',
      'vocabulary': 'وکبیولری',
      'speaking': 'اسپیکینگ',
      'reading': 'ریدینگ',
      'grammar': 'گرامر',
      'writing': 'رایتینگ',
      'podcast': 'پادکست',
      'shadowing': 'شادوینگ',
      'dictation': 'دیکته',
    };
    final map = isPersian ? faMap : enMap;
    return map[key] ?? taskType;
  }

  String _buildTitle(_GrammarVideoGroup video, bool isPersian) {
    // If the AI actually generated a real title, prefer it.
    if (video.title != null && video.title!.trim().isNotEmpty) {
      return video.title!.trim();
    }

    // Otherwise build "Grammar video, Day N" / "ویدیو گرامر روز N" from
    // the linked daily task, when we have one.
    if (video.dayNumber != null) {
      final typeLabel = _taskTypeLabel(video.taskType, isPersian);
      if (isPersian) {
        return typeLabel.isNotEmpty
            ? 'ویدیو $typeLabel روز ${video.dayNumber}'
            : 'ویدیو روز ${video.dayNumber}';
      } else {
        return typeLabel.isNotEmpty
            ? '$typeLabel Video, Day ${video.dayNumber}'
            : 'Video, Day ${video.dayNumber}';
      }
    }

    // Truly no metadata at all (very old record, never linked to a task) —
    // fall back to a short slice of the video id, same as before.
    final shortId = video.videoId.substring(
      0,
      video.videoId.length.clamp(0, 6),
    );
    return 'Video $shortId...';
  }

  Future<void> _loadAllGrammars() async {
    try {
      final response = await _supabase
          .from('video_analysis')
          .select('video_id, title, day_number, task_id, grammar_points')
          .order('day_number', ascending: true);

      final rows = response as List;

      // Resolve task_type for every non-null task_id in one extra query,
      // instead of one query per video.
      final taskIds = rows
          .map((r) => r['task_id'])
          .whereType<int>()
          .toSet()
          .toList();

      final Map<int, String> taskTypesById = {};
      if (taskIds.isNotEmpty) {
        final tasksResponse = await _supabase
            .from('daily_tasks')
            .select('id, task_type')
            .inFilter('id', taskIds);
        for (final row in tasksResponse as List) {
          taskTypesById[row['id'] as int] = row['task_type'] as String;
        }
      }

      if (mounted) {
        setState(() {
          _videoGroups = rows.map((data) {
            final taskId = data['task_id'] as int?;
            return _GrammarVideoGroup(
              videoId: data['video_id'],
              title: data['title'] as String?,
              dayNumber: data['day_number'] as int?,
              taskType: taskId != null ? taskTypesById[taskId] : null,
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
                  if (video.grammarPoints.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final title = _buildTitle(video, isPersian);

                  return Card(
                    margin: const EdgeInsets.only(
                      bottom: AppConstants.standardPadding,
                    ),
                    child: ExpansionTile(
                      initiallyExpanded: index == 0,
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
                        '${video.grammarPoints.length} '
                        '${AppLocalizations.getString('grammar_points_suffix', isPersian)}',
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
