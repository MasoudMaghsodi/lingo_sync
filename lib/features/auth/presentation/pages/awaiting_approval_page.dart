import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lingo_sync/core/localization/app_localizations.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../application/auth_controller.dart';

class AwaitingApprovalPage extends ConsumerWidget {
  const AwaitingApprovalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPersian = ref.watch(isPersianProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PulsingIcon(color: theme.colorScheme.primary),
                const SizedBox(height: 28),
                Text(
                  AppLocalizations.getString(
                    'awaiting_approval_title',
                    isPersian,
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.getString(
                    'awaiting_approval_body',
                    isPersian,
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.6,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 40),
                TextButton.icon(
                  onPressed: () =>
                      ref.read(authControllerProvider.notifier).signOut(),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: Text(AppLocalizations.getString('logout', isPersian)),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PulsingIcon extends StatefulWidget {
  final Color color;
  const _PulsingIcon({required this.color});

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 1 + (_controller.value * 0.08);
        final glow = 0.15 + (_controller.value * 0.15);
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                widget.color.withValues(alpha: glow),
                Colors.transparent,
              ],
            ),
          ),
          alignment: Alignment.center,
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 0.12),
                border: Border.all(color: widget.color.withValues(alpha: 0.4)),
              ),
              child: Icon(
                Icons.hourglass_top_rounded,
                color: widget.color,
                size: 34,
              ),
            ),
          ),
        );
      },
    );
  }
}
