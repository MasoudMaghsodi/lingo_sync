import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';
import '../../data/models/word_analysis_model.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/localization/app_localizations.dart';

class AllFlashcardsPage extends ConsumerStatefulWidget {
  const AllFlashcardsPage({super.key});

  @override
  ConsumerState<AllFlashcardsPage> createState() => _AllFlashcardsPageState();
}

class _AllFlashcardsPageState extends ConsumerState<AllFlashcardsPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final FlutterTts _flutterTts = FlutterTts();

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
    _initTts();
    _loadAllCards();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.45);
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
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
          title: Text(isPersian ? 'ایجاد پوشه جدید' : 'Create Folder'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: isPersian ? 'نام پوشه' : 'Folder Name',
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
                isPersian
                    ? 'مدیریت پوشه: $folderName'
                    : 'Manage Folder: $folderName',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: Colors.blue),
                title: Text(isPersian ? 'تغییر نام' : 'Rename'),
                onTap: () {
                  Navigator.pop(context);
                  _renameFolderDialog(folderName, isPersian);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_rounded, color: Colors.red),
                title: Text(
                  isPersian
                      ? 'حذف پوشه (انتقال لغات به General)'
                      : 'Delete (Move words to General)',
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
          title: Text(isPersian ? 'تغییر نام پوشه' : 'Rename Folder'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: isPersian ? 'نام جدید' : 'New Name',
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

  void _moveCardToFolder(
    Map<String, dynamic> card,
    ThemeData theme,
    bool isPersian,
  ) {
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
                isPersian ? 'انتقال به پوشه:' : 'Move to folder:',
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
                            const SnackBar(
                              content: Text('خطا در انتقال'),
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
    final theme = Theme.of(context);
    final isPersian = ref.watch(isPersianProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.getString('archive', isPersian),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
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
          ExpansionTile(
            title: Text(
              AppLocalizations.getString('filters', isPersian),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            leading: Icon(
              Icons.filter_alt_outlined,
              color: theme.colorScheme.primary,
            ),
            trailing: TextButton(
              onPressed: _clearAllFilters,
              child: Text(
                AppLocalizations.getString('clear_filters', isPersian),
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CEFR Levels:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'].map((
                        level,
                      ) {
                        final isSelected = _selectedCefrLevels.contains(level);
                        return FilterChip(
                          label: Text(level),
                          selected: isSelected,
                          onSelected: (checked) {
                            setState(() {
                              if (checked) {
                                _selectedCefrLevels.add(level);
                              } else {
                                _selectedCefrLevels.remove(level);
                              }
                            });
                            _applyAdvancedFilters();
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${AppLocalizations.getString('part_of_speech', isPersian)}:',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children:
                          [
                            'Noun',
                            'Verb',
                            'Adjective',
                            'Adverb',
                            'Grammar',
                          ].map((pos) {
                            final isSelected = _selectedPartsOfSpeech.contains(
                              pos,
                            );
                            return FilterChip(
                              label: Text(pos),
                              selected: isSelected,
                              onSelected: (checked) {
                                setState(() {
                                  if (checked) {
                                    _selectedPartsOfSpeech.add(pos);
                                  } else {
                                    _selectedPartsOfSpeech.remove(pos);
                                  }
                                });
                                _applyAdvancedFilters();
                              },
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 1),

          Container(
            height: 50,
            color: theme.colorScheme.surface,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: ['All', ..._folders].map((folder) {
                final isSelected = _currentFolder == folder;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: GestureDetector(
                    onLongPress: () => _showFolderOptions(folder, isPersian),
                    child: ChoiceChip(
                      label: Text(folder),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() => _currentFolder = folder);
                        _applyAdvancedFilters();
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
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

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.1),
                              child: Text(
                                wordData.partOfSpeech.isNotEmpty
                                    ? wordData.partOfSpeech
                                          .substring(0, 1)
                                          .toUpperCase()
                                    : 'W',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              wordData.word.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            subtitle: Text(
                              '${AppLocalizations.getString('box', isPersian)} ${card['repetition'] ?? 0} • ${card['folder_name'] ?? 'General'}',
                            ),
                            childrenPadding: const EdgeInsets.all(16),
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      isPersian
                                          ? wordData.persianMeaning
                                          : wordData.englishMeaning,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.drive_file_move_outline,
                                          color: theme.colorScheme.secondary,
                                        ),
                                        tooltip: isPersian
                                            ? 'انتقال پوشه'
                                            : 'Move',
                                        onPressed: () => _moveCardToFolder(
                                          card,
                                          theme,
                                          isPersian,
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.volume_up,
                                          color: theme.colorScheme.primary,
                                        ),
                                        onPressed: () => _speak(wordData.word),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Divider(),
                              Text(
                                isPersian
                                    ? wordData.englishMeaning
                                    : wordData.persianMeaning,
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 12),
                              if (wordData.examples.isNotEmpty) ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Example: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        wordData.examples.first,
                                        style: const TextStyle(
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: wordData.synonymsByLevel.entries.map((
                                  entry,
                                ) {
                                  Color levelColor = entry.key.contains('A')
                                      ? Colors.green
                                      : (entry.key.contains('B')
                                            ? Colors.blue
                                            : Colors.orange);
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: levelColor.withValues(
                                          alpha: 0.4,
                                        ),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${entry.key}: ${entry.value.word}',
                                      style: TextStyle(
                                        color: levelColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
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
