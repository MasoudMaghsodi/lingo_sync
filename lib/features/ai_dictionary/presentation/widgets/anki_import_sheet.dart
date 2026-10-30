import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingo_sync/core/providers/settings_provider.dart';
import '../../data/services/anki_import_service.dart';
import '../providers/flashcards_provider.dart';

class AnkiImportSheet extends ConsumerStatefulWidget {
  const AnkiImportSheet({super.key});

  @override
  ConsumerState<AnkiImportSheet> createState() => _AnkiImportSheetState();
}

class _AnkiImportSheetState extends ConsumerState<AnkiImportSheet> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _folderController = TextEditingController(
    text: 'Anki Decks',
  );
  bool _isImporting = false;
  int _parsedCount = 0;
  List<AnkiCardItem> _parsedCards = [];

  @override
  void dispose() {
    _textController.dispose();
    _folderController.dispose();
    super.dispose();
  }

  void _onTextChanged(String text) {
    final service = ref.read(ankiImportServiceProvider);
    final cards = service.parseDelimitedText(
      text,
      folder: _folderController.text.trim().isEmpty
          ? 'Anki Decks'
          : _folderController.text.trim(),
    );
    setState(() {
      _parsedCards = cards;
      _parsedCount = cards.length;
    });
  }

  void _insertSampleTemplate() {
    _textController.text =
        'ubiquitous\tحاضر در همه جا، فراگیر\tSmartphones have become ubiquitous.\n'
        'ephemeral\tزودگذر، موقتی\tFame in the internet age can be ephemeral.\n'
        'meticulous\tبسیار دقیق و موشکافانه\tShe did a meticulous research.\n'
        'resilience\tتاب‌آوری، مقاومت\tResilience helps us overcome setbacks.\n'
        'eloquent\tفصیح، شیوا\tAn eloquent speech captivated the audience.';
    _onTextChanged(_textController.text);
  }

  Future<void> _handleImport() async {
    if (_parsedCards.isEmpty) return;

    setState(() => _isImporting = true);
    await HapticFeedback.mediumImpact();

    final service = ref.read(ankiImportServiceProvider);
    final result = await service.importCards(_parsedCards);

    if (!mounted) return;
    setState(() => _isImporting = false);

    result.fold(
      onSuccess: (count) {
        ref.invalidate(flashcardsProvider);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 $count کارت انکی با موفقیت به لایتنر اضافه شد!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      onFailure: (err) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در ذخیره کارت‌ها: $err'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPersian = ref.watch(isPersianProvider);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131722) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.system_update_alt_rounded,
                        color: Colors.blueAccent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPersian
                              ? 'وارد کردن کارت‌های انکی'
                              : 'Anki Deck Importer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          isPersian
                              ? 'پشتیبانی از AnkiWeb، متن تب‌بندی شده و CSV'
                              : 'Supports AnkiWeb, TSV & CSV decks',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Folder Name Input
            TextField(
              controller: _folderController,
              decoration: InputDecoration(
                labelText: isPersian
                    ? 'پوشه یا نام مجموعه انکی'
                    : 'Deck / Folder Name',
                prefixIcon: const Icon(Icons.folder_outlined, size: 20),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF1E2333)
                    : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Text/TSV Input
            TextField(
              controller: _textController,
              onChanged: _onTextChanged,
              maxLines: 6,
              style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: isPersian
                    ? 'متن کارت‌ها را اینجا الصاق کنید...\nفرمت:\nکلمه [Tab] ترجمه فارسی [Tab] مثال'
                    : 'Paste cards here...\nFormat:\nWord [Tab] Meaning [Tab] Example',
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF1E2333)
                    : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Sample template button
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _insertSampleTemplate,
                icon: const Icon(Icons.lightbulb_outline_rounded, size: 16),
                label: Text(
                  isPersian ? 'درج فرمت نمونه انکی' : 'Insert Sample Template',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Detected cards badge & Submit button
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _parsedCount > 0
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.grey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isPersian
                        ? '$_parsedCount کارت شناسایی شد'
                        : '$_parsedCount cards detected',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: _parsedCount > 0 ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_parsedCount > 0 && !_isImporting)
                        ? _handleImport
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 3,
                    ),
                    child: _isImporting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isPersian
                                ? 'ایمپورت مستقیم به جعبه لایتنر'
                                : 'Import to Leitner Deck',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
