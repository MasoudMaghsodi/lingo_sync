import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingo_sync/core/localization/app_localizations.dart';
import 'package:lingo_sync/core/providers/settings_provider.dart';
import 'package:lingo_sync/features/ai_mentor/data/models/mentor_state.dart';
import 'package:lingo_sync/features/ai_mentor/presentation/providers/ai_mentor_controller.dart';
import 'package:lingo_sync/features/ai_mentor/presentation/providers/mentor_chat_provider.dart';

class AiMentorSheet extends ConsumerStatefulWidget {
  const AiMentorSheet({super.key});

  @override
  ConsumerState<AiMentorSheet> createState() => _AiMentorSheetState();
}

class _AiMentorSheetState extends ConsumerState<AiMentorSheet>
    with SingleTickerProviderStateMixin {
  int _selectedTabIndex = 0; // 0: Live Voice, 1: Mentor Chat, 2: Multi-Agent Council
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final TextEditingController _councilController = TextEditingController();

  static const List<String> _quickPrompts = [
    '📊 تحلیل وضعیت و اشتباهات اخیر من',
    '🧠 وضعیت لایتنر و کارت‌های امروز من چیه؟',
    '🎯 یک برنامه آموزشی سریع برای امروز بده',
    '💡 ۵ اصطلاح پرکاربرد نیتیو برای آزمون',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();
    _councilController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _statusText(MentorPhase phase, bool isPersian) {
    switch (phase) {
      case MentorPhase.connecting:
        return AppLocalizations.getString('connecting', isPersian);
      case MentorPhase.settingUp:
        return AppLocalizations.getString('initializing', isPersian);
      case MentorPhase.receivingAudio:
        return AppLocalizations.getString('mentor_speaking', isPersian);
      case MentorPhase.aiDisconnected:
        return AppLocalizations.getString('mentor_session_ended', isPersian);
      case MentorPhase.disconnected:
        return AppLocalizations.getString('mentor_no_internet', isPersian);
      case MentorPhase.ready:
        return AppLocalizations.getString('mentor_listening', isPersian);
    }
  }

  Color _orbColor(MentorPhase phase) {
    switch (phase) {
      case MentorPhase.connecting:
      case MentorPhase.settingUp:
        return Colors.blueAccent;
      case MentorPhase.receivingAudio:
        return Colors.tealAccent.shade400;
      case MentorPhase.aiDisconnected:
      case MentorPhase.disconnected:
        return Colors.redAccent;
      case MentorPhase.ready:
        return Colors.deepPurpleAccent.shade200;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPersian = ref.watch(isPersianProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final totalHeight = MediaQuery.of(context).size.height;
    final sheetHeight = _selectedTabIndex == 0
        ? totalHeight * 0.52
        : totalHeight * 0.88;

    return SizedBox.expand(
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              height: sheetHeight,
              width: double.infinity,
              padding: EdgeInsets.only(bottom: bottomInset),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 25,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle Bar
                  const SizedBox(height: 12),
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Header with Segment Selector
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, size: 24),
                          tooltip: 'بستن',
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildTabChip(
                                  index: 0,
                                  icon: Icons.graphic_eq_rounded,
                                  label: 'مکالمه زنده',
                                  theme: theme,
                                ),
                                const SizedBox(width: 8),
                                _buildTabChip(
                                  index: 1,
                                  icon: Icons.chat_bubble_outline_rounded,
                                  label: 'چت هوشمند',
                                  theme: theme,
                                ),
                                const SizedBox(width: 8),
                                _buildTabChip(
                                  index: 2,
                                  icon: Icons.groups_rounded,
                                  label: 'شورای اساتید',
                                  theme: theme,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                  const Divider(height: 20),

                  // Tab Views
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _buildSelectedTab(isPersian, theme),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabChip({
    required int index,
    required IconData icon,
    required String label,
    required ThemeData theme,
  }) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedTabIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.2)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? theme.colorScheme.primary : Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? theme.colorScheme.primary : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedTab(bool isPersian, ThemeData theme) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildVoiceOrbTab(isPersian, theme);
      case 1:
        return _buildMentorChatTab(isPersian, theme);
      case 2:
        return _buildCouncilTab(isPersian, theme);
      default:
        return const SizedBox.shrink();
    }
  }

  // ==========================================
  // TAB 0: LIVE VOICE DIALOG
  // ==========================================
  Widget _buildVoiceOrbTab(bool isPersian, ThemeData theme) {
    final session = ref.watch(aiMentorControllerProvider);
    final controller = ref.read(aiMentorControllerProvider.notifier);

    final speakingScale = (session.phase == MentorPhase.ready ||
            session.phase == MentorPhase.receivingAudio)
        ? 1.0 + (session.amplitude * 0.4)
        : _pulseAnimation.value;

    final orbColor = _orbColor(session.phase);
    final isRetryPhase = session.phase == MentorPhase.aiDisconnected ||
        session.phase == MentorPhase.disconnected;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _statusText(session.phase, isPersian),
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: orbColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Gemini 3.8 Live Voice',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade400,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 36),
        GestureDetector(
          onTap: controller.onOrbTap,
          child: AnimatedScale(
            scale: speakingScale,
            duration: const Duration(milliseconds: 100),
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    orbColor.withValues(alpha: 0.55),
                    orbColor.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: orbColor.withValues(alpha: 0.45),
                    blurRadius: 40,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  isRetryPhase
                      ? Icons.refresh_rounded
                      : (session.phase == MentorPhase.receivingAudio
                          ? Icons.volume_up_rounded
                          : Icons.mic_rounded),
                  color: Colors.white,
                  size: 45,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'برای شروع یا توقف مکالمه ضربه بزنید',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 1: OMNI-CONTEXT MENTOR CHAT
  // ==========================================
  Widget _buildMentorChatTab(bool isPersian, ThemeData theme) {
    final chatState = ref.watch(mentorChatProvider);
    final chatNotifier = ref.read(mentorChatProvider.notifier);

    return Column(
      children: [
        // Quick prompts horizontal scroll
        SizedBox(
          height: 38,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _quickPrompts.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final prompt = _quickPrompts[index];
              return ActionChip(
                label: Text(
                  prompt,
                  style: const TextStyle(fontSize: 11.5),
                ),
                backgroundColor:
                    theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  chatNotifier.sendMessage(prompt);
                  _scrollToBottom();
                },
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // Chat Messages List
        Expanded(
          child: ListView.builder(
            controller: _chatScrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: chatState.messages.length,
            itemBuilder: (context, index) {
              final msg = chatState.messages[index];
              return _buildChatMessageItem(msg, theme);
            },
          ),
        ),

        // Loading Indicator
        if (chatState.isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'مربی در حال تایپ و تحلیل داده‌های شماست...',
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.primary),
                ),
              ],
            ),
          ),

        // Error Banner
        if (chatState.errorMessage != null)
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              chatState.errorMessage!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),

        // Message Input Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  textDirection: TextDirection.rtl,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'از مربی خود بپرسید (مثلاً: برنامم چیه؟)...',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (text) {
                    if (text.trim().isNotEmpty) {
                      chatNotifier.sendMessage(text);
                      _chatController.clear();
                      _scrollToBottom();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: () {
                  final text = _chatController.text.trim();
                  if (text.isNotEmpty) {
                    HapticFeedback.lightImpact();
                    chatNotifier.sendMessage(text);
                    _chatController.clear();
                    _scrollToBottom();
                  }
                },
                icon: const Icon(Icons.send_rounded, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatMessageItem(MentorChatMessage msg, ThemeData theme) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primary.withValues(alpha: 0.2)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 4 : 16),
            bottomRight: Radius.circular(isUser ? 16 : 4),
          ),
          border: Border.all(
            color: isUser
                ? theme.colorScheme.primary.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: SelectableText(
          msg.text,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: isUser ? theme.colorScheme.primary : Colors.white,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 2: MULTI-AGENT DELIBERATION COUNCIL
  // ==========================================
  Widget _buildCouncilTab(bool isPersian, ThemeData theme) {
    final chatState = ref.watch(mentorChatProvider);
    final chatNotifier = ref.read(mentorChatProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple.shade900.withValues(alpha: 0.4),
                  Colors.indigo.shade900.withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.deepPurpleAccent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.psychology_alt_rounded, color: Colors.purpleAccent, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'شورای ۳ نفره هوش مصنوعی: تحلیل همزمان ساختار گرامری، کاربرد طبیعی و جمع‌بندی نهایی استاد ارشد.',
                    style: TextStyle(fontSize: 12, color: Colors.purple.shade100, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Council Question Input
          TextField(
            controller: _councilController,
            textDirection: TextDirection.rtl,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'موضوع یا سوال پیچیده گرامری/آزمونی خود را بنویسید...',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          ElevatedButton.icon(
            onPressed: chatState.isLoadingCouncil
                ? null
                : () {
                    final query = _councilController.text.trim();
                    if (query.isNotEmpty) {
                      HapticFeedback.mediumImpact();
                      chatNotifier.askCouncil(query);
                    }
                  },
            icon: chatState.isLoadingCouncil
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.gavel_rounded),
            label: Text(
              chatState.isLoadingCouncil
                  ? 'اساتید در حال مشورت و تبادل نظر هستند...'
                  : 'تشکیل جلسه و تحلیل اساتید',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 16),

          // Council Results
          if (chatState.councilError != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                chatState.councilError!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ),

          if (chatState.councilResult != null) ...[
            // Master Consensus Card
            _buildCouncilCard(
              title: '🏆 جمع‌بندی نهایی استاد ارشد',
              content: chatState.councilResult!.consensus,
              color: Colors.amber.shade300,
              theme: theme,
            ),
            const SizedBox(height: 12),

            // Grammar Perspective Card
            _buildCouncilCard(
              title: '📐 تحلیل ساختاری و گرامری (Linguistic Specialist)',
              content: chatState.councilResult!.grammar,
              color: Colors.blueAccent.shade100,
              theme: theme,
            ),
            const SizedBox(height: 12),

            // Pragmatic Perspective Card
            _buildCouncilCard(
              title: '🗣️ دیدگاه مربی کاربرد طبیعی (Pragmatic Coach)',
              content: chatState.councilResult!.pragmatic,
              color: Colors.tealAccent.shade100,
              theme: theme,
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildCouncilCard({
    required String title,
    required String content,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        iconColor: color,
        collapsedIconColor: Colors.grey,
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SelectableText(
              content,
              style: const TextStyle(fontSize: 13.5, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}
