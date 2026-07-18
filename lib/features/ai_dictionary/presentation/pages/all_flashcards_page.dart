import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lingo_sync/core/services/tts_service.dart';
import 'package:flutter/services.dart';
import '../../data/models/word_analysis_model.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/localization/app_localizations.dart';
import '../widgets/archive/archive_card_tile.dart';
import '../widgets/archive/archive_filters_panel.dart';
import '../widgets/archive/archive_folder_bar.dart';

class AllFlashcardsPage extends ConsumerStatefulWidget {
  const AllFlashcardsPage({super.key});

  @override
  ConsumerState<AllFlashcardsPage> createState() => _AllFlashcardsPageState();
}

class _AllFlashcardsPageState extends ConsumerState<AllFlashcardsPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Cached in initState — see the note in VideoLessonPage for why
  // ref.read must never be called inside dispose().
  late final TtsService _tts;

  List<Map<String, dynamic>> _allCards = [];
  List<Map<String, dynamic>> _filteredCards = [];
  bool _isLoading = true;

  final List<String> _selectedCefrLevels = [];
  final List<String> _selectedPartsOfSpeech = [];

  Set<String> _folders = {'General', 'Grammar'};
  String _currentFolder = 'All';

  @override
  void initState() {
    super.initState();
    _tts = ref.read(ttsServiceProvider);
    _loadAllCards();
  }

  Future<void> _speak(String text) => _tts.speak(text);

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _loadAllCards() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return;
    }

    try {
      final response = await _supabase
          .from('flashcards')
          .select('*, global_dictionary(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _allCards = List<Map<String, dynamic>>.from(response);
          // استخراج پوشه‌ها و نگه‌داشتن پوشه‌های پایه
          _folders = {'General', 'Grammar'};
          for (var card in _allCards) {
            if (card['folder_name'] != null &&
                card['folder_name'].toString().trim().isNotEmpty) {
              _folders.add(card['folder_name']);
            }
          }
          _applyAdvancedFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyAdvancedFilters() {
    setState(() {
      _filteredCards = _allCards.where((card) {
        final globalDict = card['global_dictionary'] ?? {};
        final aiAnalysisMap =
            globalDict['ai_analysis'] ?? card['ai_analysis'] ?? {};
        final wordData = WordAnalysis.fromJson(aiAnalysisMap);
        final cardFolder = card['folder_name'] ?? 'General';

        if (_currentFolder != 'All' && cardFolder != _currentFolder) {
          return false;
        }

        if (_selectedCefrLevels.isNotEmpty) {
          final hasLevel = wordData.synonymsByLevel.keys.any(
            (key) => _selectedCefrLevels.contains(key),
          );
          if (!hasLevel) {
            return false;
          }
        }

        if (_selectedPartsOfSpeech.isNotEmpty) {
          final cleanPos = wordData.partOfSpeech.toLowerCase();
          final matchPos = _selectedPartsOfSpeech.any(
            (pos) => cleanPos.contains(pos.toLowerCase()),
          );
          if (!matchPos) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  void _onCefrToggled(String level, bool checked) {
    setState(() {
      if (checked) {
        _selectedCefrLevels.add(level);
      } else {
        _selectedCefrLevels.remove(level);
      }
    });
    _applyAdvancedFilters();
  }

  void _onPosToggled(String pos, bool checked) {
    setState(() {
      if (checked) {
        _selectedPartsOfSpeech.add(pos);
      } else {
        _selectedPartsOfSpeech.remove(pos);
      }
    });
    _applyAdvancedFilters();
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCefrLevels.clear();
      _selectedPartsOfSpeech.clear();
      _currentFolder = 'All';
      _filteredCards = _allCards;
    });
  }

  void _addNewFolderDialog(bool isPersian) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            AppLocalizations.getString('create_folder_title', isPersian),
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: AppLocalizations.getString(
                'folder_name_hint',
                isPersian,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.getString('cancel', isPersian)),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    _folders.add(controller.text.trim());
                  });
                  Navigator.pop(context);
                }
              },
              child: Text(AppLocalizations.getString('save', isPersian)),
            ),
          ],
        );
      },
    );
  }

  void _showFolderOptions(String folderName, bool isPersian) {
    if (folderName == 'All' ||
        folderName == 'General' ||
        folderName == 'Grammar') {
      return; // پوشه‌های سیستمی نباید تغییر کنند
    }

    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${AppLocalizations.getString('manage_folder_title', isPersian)}: $folderName',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: Colors.blue),
                title: Text(AppLocalizations.getString('rename', isPersian)),
                onTap: () {
                  Navigator.pop(context);
                  _renameFolderDialog(folderName, isPersian);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_rounded, color: Colors.red),
                title: Text(
                  AppLocalizations.getString('delete_folder_action', isPersian),
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteFolder(folderName, isPersian);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _renameFolderDialog(String oldName, bool isPersian) {
    final controller = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            AppLocalizations.getString('rename_folder_title', isPersian),
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: AppLocalizations.getString('new_name_hint', isPersian),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.getString('cancel', isPersian)),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isNotEmpty && newName != oldName) {
                  Navigator.pop(context);
                  setState(() => _isLoading = true);
                  try {
                    final userId = _supabase.auth.currentUser?.id;
                    await _supabase
                        .from('flashcards')
                        .update({'folder_name': newName})
                        .eq('folder_name', oldName)
                        .eq('user_id', userId!);
                    if (_currentFolder == oldName) _currentFolder = newName;
                    await _loadAllCards();
                  } catch (e) {
                    setState(() => _isLoading = false);
                  }
                }
              },
              child: Text(AppLocalizations.getString('save', isPersian)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteFolder(String folderName, bool isPersian) async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      await _supabase
          .from('flashcards')
          .update({'folder_name': 'General'})
          .eq('folder_name', folderName)
          .eq('user_id', userId!);
      if (_currentFolder == folderName) _currentFolder = 'All';
      await _loadAllCards();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _moveCardToFolder(Map<String, dynamic> card) {
    final theme = Theme.of(context);
    final isPersian = ref.read(isPersianProvider);
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppLocalizations.getString('move_to_folder_title', isPersian),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _folders.map((folder) {
                  return ActionChip(
                    label: Text(folder),
                    backgroundColor: card['folder_name'] == folder
                        ? theme.colorScheme.primary.withValues(alpha: 0.2)
                        : null,
                    onPressed: () async {
                      Navigator.pop(context);
                      setState(() => _isLoading = true);
                      try {
                        await _supabase
                            .from('flashcards')
                            .update({'folder_name': folder})
                            .eq('id', card['id']);
                        await _loadAllCards();
                      } catch (e) {
                        setState(() => _isLoading = false);
                        if (mounted) {
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.getString(
                                  'move_error',
                                  isPersian,
                                ),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPersian = ref.watch(isPersianProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.getString('archive', isPersian)),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            onPressed: () => _addNewFolderDialog(isPersian),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ArchiveFiltersPanel(
            selectedCefrLevels: _selectedCefrLevels,
            selectedPartsOfSpeech: _selectedPartsOfSpeech,
            isPersian: isPersian,
            onCefrToggled: _onCefrToggled,
            onPosToggled: _onPosToggled,
            onClearFilters: _clearAllFilters,
          ),
          const Divider(height: 1),
          ArchiveFolderBar(
            folders: ['All', ..._folders],
            currentFolder: _currentFolder,
            onFolderSelected: (folder) {
              setState(() => _currentFolder = folder);
              _applyAdvancedFilters();
            },
            onFolderLongPress: (folder) =>
                _showFolderOptions(folder, isPersian),
          ),
          const Divider(height: 1),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCards.isEmpty
                ? Center(
                    child: Text(
                      AppLocalizations.getString('no_words', isPersian),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadAllCards,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredCards.length,
                      itemBuilder: (context, index) {
                        final card = _filteredCards[index];
                        final globalDict = card['global_dictionary'] ?? {};
                        final aiAnalysisMap =
                            globalDict['ai_analysis'] ??
                            card['ai_analysis'] ??
                            {};
                        final wordData = WordAnalysis.fromJson(aiAnalysisMap);

                        return ArchiveCardTile(
                          card: card,
                          wordData: wordData,
                          isPersian: isPersian,
                          onSpeak: _speak,
                          onMove: _moveCardToFolder,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
