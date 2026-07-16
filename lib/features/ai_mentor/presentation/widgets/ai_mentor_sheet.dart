import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingo_sync/features/ai_mentor/controller/ai_mentor_controller.dart';
import 'package:lingo_sync/features/ai_mentor/data/mentor_state.dart';

import '../../../../core/providers/settings_provider.dart';

class AiMentorSheet extends ConsumerStatefulWidget {
  const AiMentorSheet({super.key});
  @override
  ConsumerState<AiMentorSheet> createState() => _AiMentorSheetState();
}

class _AiMentorSheetState extends ConsumerState<AiMentorSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

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
    super.dispose();
  }

  String _statusText(MentorPhase phase, bool isPersian) {
    switch (phase) {
      case MentorPhase.connecting:
        return isPersian ? 'در حال اتصال...' : 'Connecting...';
      case MentorPhase.settingUp:
        return isPersian ? 'در حال آماده‌سازی...' : 'Initializing...';
      case MentorPhase.receivingAudio:
        return isPersian ? 'استاد صحبت می‌کند' : 'Mentor is speaking';
      case MentorPhase.aiDisconnected:
        return isPersian
            ? 'سشن پایان یافت (لمس برای شروع مجدد)'
            : 'Session Ended (Tap to restart)';
      case MentorPhase.disconnected:
        return isPersian ? 'اینترنت قطع شد!' : 'No Internet Connection!';
      case MentorPhase.ready:
        return isPersian ? 'استاد می‌شنود...' : 'Mentor is listening...';
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
    final session = ref.watch(aiMentorControllerProvider);
    final controller = ref.read(aiMentorControllerProvider.notifier);

    final speakingScale =
        (session.phase == MentorPhase.ready ||
            session.phase == MentorPhase.receivingAudio)
        ? 1.0 + (session.amplitude * 0.4)
        : _pulseAnimation.value;

    final orbColor = _orbColor(session.phase);
    final isRetryPhase =
        session.phase == MentorPhase.aiDisconnected ||
        session.phase == MentorPhase.disconnected;

    return SizedBox.expand(
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  color: theme.colorScheme.surface.withValues(alpha: 0.1),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.45,
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.85),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(40),
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _statusText(session.phase, isPersian),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: orbColor,
                    ),
                  ),
                  const SizedBox(height: 50),
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
                              orbColor.withValues(alpha: 0.5),
                              orbColor.withValues(alpha: 0.1),
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: orbColor.withValues(alpha: 0.4),
                              blurRadius: 40,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            isRetryPhase
                                ? Icons.refresh_rounded
                                : Icons.mic_none_rounded,
                            color: theme.colorScheme.surface,
                            size: 45,
                          ),
                        ),
                      ),
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
}
