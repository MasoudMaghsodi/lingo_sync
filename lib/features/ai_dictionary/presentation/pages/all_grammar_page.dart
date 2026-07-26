import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/ui_constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/services/tts_service.dart';
import '../../../../core/widgets/persian_content_text.dart';
import '../../data/models/video_analysis_model.dart';
import '../../data/repositories/video_analysis_repository.dart';

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
    return (isPersian ? faMap[key] : enMap[key]) ?? taskType;
  }

  String _buildTitle(_GrammarVideoGroup video, bool isPersian) {
    if (video.title != null && video.title!.trim().isNotEmpty) {
      return video.title!.trim();
    }
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
    final shortId = video.videoId.substring(
      0,
      video.videoId.length.clamp(0, 6),
    );
    return 'Video $shortId...';
  }

  Future<void> _loadAllGrammars() async {
    if (mounted) setState(() => _isLoading = true);

    // 🚀 واگذاری به ریپازیتوری
    final repo = ref.read(videoAnalysisRepositoryProvider);
    final result = await repo.getAllGrammarVideos();

    if (mounted) {
      result.when(
        success: (rows) {
          setState(() {
            _videoGroups = rows.map((data) {
              return _GrammarVideoGroup(
                videoId: data['video_id'],
                title: data['title'] as String?,
                dayNumber: data['day_number'] as int?,
                taskType: data['task_type'] as String?,
                grammarPoints: (data['grammar_points'] as List)
                    .map((e) => GrammarPoint.fromJson(e))
                    .toList(),
              );
            }).toList();
            _isLoading = false;
          });
        },
        failure: (_) {
          setState(() => _isLoading = false);
        },
      );
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
                padding: const EdgeInsets.all(UIConstants.standardPadding),
                itemCount: _videoGroups.length,
                itemBuilder: (context, index) {
                  final video = _videoGroups[index];
                  if (video.grammarPoints.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final title = _buildTitle(video, isPersian);

                  return Card(
                    margin: const EdgeInsets.only(
                      bottom: UIConstants.standardPadding,
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
                        '${video.grammarPoints.length} ${AppLocalizations.getString('grammar_points_suffix', isPersian)}',
                      ),
                      childrenPadding: const EdgeInsets.all(
                        UIConstants.standardPadding,
                      ),
                      children: video.grammarPoints.map((grammar) {
                        return Container(
                          margin: const EdgeInsets.only(
                            bottom: UIConstants.standardPadding,
                          ),
                          padding: const EdgeInsets.all(
                            UIConstants.standardPadding,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(
                              UIConstants.standardBorderRadius,
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
                              PersianContentText(
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
                                    UIConstants.standardBorderRadius,
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
