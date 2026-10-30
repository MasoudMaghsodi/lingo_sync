import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/app_config.dart';

class C1UpgradeStudioSheet extends StatefulWidget {
  final String? initialText;

  const C1UpgradeStudioSheet({super.key, this.initialText});

  static Future<void> show(BuildContext context, {String? initialText}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => C1UpgradeStudioSheet(initialText: initialText),
    );
  }

  @override
  State<C1UpgradeStudioSheet> createState() => _C1UpgradeStudioSheetState();
}

class _C1UpgradeStudioSheetState extends State<C1UpgradeStudioSheet> {
  late final TextEditingController _inputController;
  final FlutterTts _tts = FlutterTts();

  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _result;
  bool _isPlayingAudio = false;

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController(text: widget.initialText ?? '');
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.45);
      _tts.setCompletionHandler(() {
        if (mounted) setState(() => _isPlayingAudio = false);
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _inputController.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _upgradeToC1() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final token = supabase.auth.currentSession?.accessToken;
      final uri = Uri.parse('${AppConfig.aiServerBaseUrl}/api/c1_upgrade_studio');

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      } else {
        headers['x-secret-key'] = AppConfig.proxySecretKey;
      }

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({
          'text': text,
          'userId': supabase.auth.currentUser?.id,
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() => _result = body);
      } else {
        final body = jsonDecode(response.body) as Map<String, dynamic>?;
        setState(() => _error = body?['error']?.toString() ?? 'خطا در ارتقا به C1');
      }
    } catch (e) {
      setState(() => _error = 'خطای اتصال به سرور: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _speakUpgraded(String text) async {
    if (_isPlayingAudio) {
      await _tts.stop();
      setState(() => _isPlayingAudio = false);
      return;
    }

    setState(() => _isPlayingAudio = true);
    await _tts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    return Container(
      height: mediaQuery.size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.amber, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'استودیو ارتقای ۶۰ ثانیه‌ای C1',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'بازنویسی جمله شما با ساختار C1 و لغات فلش‌کارت‌های فعال',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),

            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Text Input
                  Text(
                    'جمله یا پاسخ شما (انگلیسی):',
                    style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: TextField(
                      controller: _inputController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'e.g. I agree with this idea because it helps people learn faster...',
                        hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Upgrade Button
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _upgradeToC1,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.transform),
                    label: Text(_isLoading ? 'در حال بازنویسی با هوش مصنوعی...' : 'ارتقا به سطح C1 (IELTS 8+)'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
                      ),
                    ),
                  ],

                  if (_result != null) ...[
                    const SizedBox(height: 20),
                    // Result Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.amber.withValues(alpha: 0.12),
                            theme.colorScheme.primary.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.workspace_premium, color: Colors.amber, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'نسخه ارتقا یافته C1:',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: Icon(
                                  _isPlayingAudio ? Icons.stop_circle : Icons.volume_up,
                                  color: Colors.amber.shade900,
                                ),
                                tooltip: 'پخش تلفظ و شدووینگ',
                                onPressed: () {
                                  final text = _result!['upgradedC1Text']?.toString() ?? '';
                                  _speakUpgraded(text);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 18),
                                tooltip: 'کپی متن',
                                onPressed: () {
                                  final text = _result!['upgradedC1Text']?.toString() ?? '';
                                  Clipboard.setData(ClipboardData(text: text));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('متن C1 در کلیپ‌بورد کپی شد')),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              _result!['upgradedC1Text']?.toString() ?? '',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Metadata Chips
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Chip(
                                avatar: const Icon(Icons.style, size: 16),
                                label: Text(
                                  _result!['grammarPatternUsed']?.toString() ?? 'Advanced Syntax',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                              if (_result!['srsWordsUsed'] is List)
                                for (final w in (_result!['srsWordsUsed'] as List))
                                  Chip(
                                    avatar: const Icon(Icons.auto_stories, size: 16, color: Colors.teal),
                                    label: Text('$w', style: const TextStyle(fontSize: 11)),
                                    visualDensity: VisualDensity.compact,
                                  ),
                            ],
                          ),

                          if (_result!['explanationFa'] != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _result!['explanationFa'].toString(),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
