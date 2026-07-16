import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:lingo_sync/core/localization/app_localizations.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/providers/pomodoro_provider.dart';

const double _kIconSize = 56;
const double _kPanelWidth = 236;

class FloatingPomodoro extends ConsumerStatefulWidget {
  const FloatingPomodoro({super.key});

  @override
  ConsumerState<FloatingPomodoro> createState() => _FloatingPomodoroState();
}

class _FloatingPomodoroState extends ConsumerState<FloatingPomodoro> {
  double _x = 20;
  double _y = 100;
  bool _isExpanded = false;
  bool _isInitialized = false;
  final TextEditingController _timeController = TextEditingController();

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  void _initializePosition(BuildContext context, bool isPersian) {
    if (_isInitialized) return;
    final size = MediaQuery.of(context).size;
    _x = isPersian ? 20 : size.width - _kIconSize - 20;
    _y = MediaQuery.of(context).padding.top + 90;
    _isInitialized = true;
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _toggleExpanded() {
    HapticFeedback.selectionClick();
    setState(() => _isExpanded = !_isExpanded);
  }

  void _collapse() {
    if (_isExpanded) setState(() => _isExpanded = false);
  }

  void _showSettingsDialog(ThemeData theme, bool isPersian) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            AppLocalizations.getString('pomodoro_set_focus_time', isPersian),
          ),
          content: TextField(
            controller: _timeController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            autofocus: true,
            decoration: InputDecoration(
              hintText: AppLocalizations.getString(
                'pomodoro_enter_minutes_hint',
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
                final min = int.tryParse(_timeController.text);
                if (min != null && min > 0) {
                  ref.read(pomodoroProvider.notifier).setCustomTime(min);
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

  @override
  Widget build(BuildContext context) {
    final pomodoro = ref.watch(pomodoroProvider);
    final theme = Theme.of(context);
    final isPersian = ref.watch(isPersianProvider);
    final screenSize = MediaQuery.of(context).size;

    _initializePosition(context, isPersian);

    if (!pomodoro.isGloballyVisible) {
      // Fully hidden — a small ambient dot is the only way back in.
      return Positioned(
        right: isPersian ? null : 16,
        left: isPersian ? 16 : null,
        top: MediaQuery.of(context).padding.top + 12,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            ref.read(pomodoroProvider.notifier).setVisibility(true);
          },
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }

    // Where should the panel sit relative to the icon, given screen edges?
    final opensLeft = isPersian
        ? true
        : (_x + _kIconSize / 2) > screenSize.width / 2;
    final opensUp = (_y + _kIconSize + 260) > screenSize.height;

    return Stack(
      children: [
        // Tap-outside-to-collapse layer — only present while expanded, so it
        // never intercepts touches on the rest of the app otherwise.
        if (_isExpanded)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _collapse,
              child: const SizedBox.expand(),
            ),
          ),

        // The panel, anchored beside the icon, flipping side/direction to
        // stay on-screen. AnimatedSwitcher gives it a soft pop-in/out.
        Positioned(
          left: opensLeft ? null : _x,
          right: opensLeft ? (screenSize.width - _x - _kIconSize) : null,
          top: opensUp ? null : _y,
          bottom: opensUp ? (screenSize.height - _y) : null,
          width: _kPanelWidth,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                scale: Tween(begin: 0.9, end: 1.0).animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                ),
                alignment: opensUp
                    ? (opensLeft ? Alignment.bottomRight : Alignment.bottomLeft)
                    : (opensLeft ? Alignment.topRight : Alignment.topLeft),
                child: child,
              ),
            ),
            child: _isExpanded
                ? _PomodoroPanel(
                    key: const ValueKey('panel'),
                    pomodoro: pomodoro,
                    theme: theme,
                    isPersian: isPersian,
                    formatTime: _formatTime,
                    onPlayPause: () =>
                        ref.read(pomodoroProvider.notifier).toggleTimer(),
                    onReset: () =>
                        ref.read(pomodoroProvider.notifier).resetTimer(),
                    onSettings: () => _showSettingsDialog(theme, isPersian),
                    onHide: () {
                      setState(() => _isExpanded = false);
                      ref.read(pomodoroProvider.notifier).setVisibility(false);
                    },
                  )
                : const SizedBox.shrink(key: ValueKey('empty')),
          ),
        ),

        // The persistent icon itself — draggable only while collapsed, so
        // dragging and tapping never fight over the same gesture.
        Positioned(
          left: _x,
          top: _y,
          child: GestureDetector(
            onPanUpdate: _isExpanded
                ? null
                : (details) {
                    setState(() {
                      _x = (_x + details.delta.dx).clamp(
                        0.0,
                        screenSize.width - _kIconSize,
                      );
                      _y = (_y + details.delta.dy).clamp(
                        MediaQuery.of(context).padding.top,
                        screenSize.height - _kIconSize - 20,
                      );
                    });
                  },
            onTap: _toggleExpanded,
            child: _PomodoroIcon(pomodoro: pomodoro, theme: theme),
          ),
        ),
      ],
    );
  }
}

// ==== The always-visible trigger: icon + ambient progress ring ====

class _PomodoroIcon extends StatelessWidget {
  final PomodoroState pomodoro;
  final ThemeData theme;

  const _PomodoroIcon({required this.pomodoro, required this.theme});

  @override
  Widget build(BuildContext context) {
    final total = pomodoro.defaultMinutes * 60;
    final progress = total > 0
        ? (1 - (pomodoro.remainingSeconds / total)).clamp(0.0, 1.0)
        : 0.0;

    final bg = pomodoro.isFinished
        ? Colors.amber.shade700
        : (pomodoro.isRunning
              ? theme.colorScheme.primary
              : theme.colorScheme.surface);
    final fg = (pomodoro.isRunning || pomodoro.isFinished)
        ? Colors.white
        : theme.colorScheme.primary;

    return SizedBox(
      width: _kIconSize,
      height: _kIconSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (pomodoro.isRunning)
            SizedBox(
              width: _kIconSize,
              height: _kIconSize,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 2.5,
                backgroundColor: Colors.white.withValues(alpha: 0.35),
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          Container(
            width: _kIconSize - 8,
            height: _kIconSize - 8,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: pomodoro.isFinished
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                : (pomodoro.isRunning
                      ? Text(
                          _mmss(pomodoro.remainingSeconds),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : Icon(Icons.timer_rounded, color: fg, size: 24)),
          ),
        ],
      ),
    );
  }

  static String _mmss(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

// ==== The expanded control panel ====

class _PomodoroPanel extends StatelessWidget {
  final PomodoroState pomodoro;
  final ThemeData theme;
  final bool isPersian;
  final String Function(int) formatTime;
  final VoidCallback onPlayPause;
  final VoidCallback onReset;
  final VoidCallback onSettings;
  final VoidCallback onHide;

  const _PomodoroPanel({
    super.key,
    required this.pomodoro,
    required this.theme,
    required this.isPersian,
    required this.formatTime,
    required this.onPlayPause,
    required this.onReset,
    required this.onSettings,
    required this.onHide,
  });

  @override
  Widget build(BuildContext context) {
    final total = pomodoro.defaultMinutes * 60;
    final progress = total > 0
        ? (1 - (pomodoro.remainingSeconds / total)).clamp(0.0, 1.0)
        : 0.0;

    return Material(
      type: MaterialType.transparency,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.getString('pomodoro_focus_label', isPersian),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    letterSpacing: 0.4,
                  ),
                ),
                GestureDetector(
                  onTap: onHide,
                  child: Icon(
                    Icons.visibility_off_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              pomodoro.isFinished
                  ? AppLocalizations.getString('pomodoro_done_label', isPersian)
                  : formatTime(pomodoro.remainingSeconds),
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: pomodoro.isFinished
                    ? Colors.amber.shade700
                    : theme.colorScheme.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.12,
                ),
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _PanelAction(
                  icon: Icons.refresh_rounded,
                  onTap: onReset,
                  theme: theme,
                ),
                _PanelAction(
                  icon: pomodoro.isRunning
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  onTap: onPlayPause,
                  theme: theme,
                  primary: true,
                ),
                _PanelAction(
                  icon: Icons.settings_rounded,
                  onTap: onSettings,
                  theme: theme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final ThemeData theme;
  final bool primary;

  const _PanelAction({
    required this.icon,
    required this.onTap,
    required this.theme,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: primary ? 52 : 40,
        height: primary ? 52 : 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: primary
              ? theme.colorScheme.primary
              : theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
        child: Icon(
          icon,
          color: primary ? Colors.white : theme.colorScheme.primary,
          size: primary ? 26 : 20,
        ),
      ),
    );
  }
}
