import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';

import 'package:lingo_sync/core/constants/app_constants.dart';
import 'package:lingo_sync/core/exceptions/app_exceptions.dart';
import 'package:lingo_sync/core/localization/app_localizations.dart';
import 'package:lingo_sync/core/providers/settings_provider.dart';
import 'package:lingo_sync/core/services/error_handler_service.dart';
import 'package:lingo_sync/features/auth/application/auth_controller.dart';
import '../../data/profile_repository.dart';
import '../providers/profile_provider.dart';

/// The app-wide settings/profile drawer, reachable from every top-level
/// tab page via the menu button in its AppBar (see `AppShellScaffoldKey`).
/// Shows the user's avatar, name, email, English level, quick stats, and
/// the language/theme toggles, cache clearing, and logout that used to
/// only be reachable from the login screen.
class AppSettingsDrawer extends ConsumerWidget {
  const AppSettingsDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isPersian = ref.watch(isPersianProvider);
    final isDarkMode = ref.watch(isDarkModeProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Drawer(
      child: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                error is AppException
                    ? errorHandler.getUserMessage(error)
                    : AppLocalizations.getString('save_error', isPersian),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (profile) => ListView(
            padding: EdgeInsets.zero,
            children: [
              _ProfileHeader(profile: profile, isPersian: isPersian),
              _StatsRow(profile: profile, isPersian: isPersian, theme: theme),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  isDarkMode
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  color: theme.colorScheme.primary,
                ),
                title: Text(
                  AppLocalizations.getString(
                    isDarkMode ? 'theme_dark_mode' : 'theme_light_mode',
                    isPersian,
                  ),
                ),
                trailing: Switch(
                  value: isDarkMode,
                  onChanged: (_) =>
                      ref.read(isDarkModeProvider.notifier).toggleTheme(),
                ),
                onTap: () =>
                    ref.read(isDarkModeProvider.notifier).toggleTheme(),
              ),
              ListTile(
                leading: Icon(
                  Icons.language_rounded,
                  color: theme.colorScheme.primary,
                ),
                title: Text(
                  AppLocalizations.getString(
                    isPersian ? 'language_persian' : 'language_english',
                    isPersian,
                  ),
                ),
                trailing: TextButton(
                  onPressed: () =>
                      ref.read(isPersianProvider.notifier).toggleLanguage(),
                  child: Text(isPersian ? 'EN' : 'فا'),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.cleaning_services_rounded,
                  color: theme.colorScheme.primary,
                ),
                title: Text(
                  AppLocalizations.getString('clear_cache', isPersian),
                ),
                onTap: () => _confirmClearCache(context, ref, isPersian),
              ),
              ListTile(
                leading: Icon(
                  Icons.info_outline_rounded,
                  color: theme.colorScheme.primary,
                ),
                title: Text(AppLocalizations.getString('about_app', isPersian)),
                onTap: () => _showAboutSheet(context, isPersian, theme),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.logout_rounded,
                  color: theme.colorScheme.error,
                ),
                title: Text(
                  AppLocalizations.getString('logout', isPersian),
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                onTap: () => _confirmLogout(context, ref, isPersian),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmClearCache(
    BuildContext context,
    WidgetRef ref,
    bool isPersian,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.getString('clear_cache_confirm_title', isPersian),
        ),
        content: Text(
          AppLocalizations.getString('clear_cache_confirm_body', isPersian),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.getString('cancel', isPersian)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.getString('clear_cache', isPersian)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await Hive.box('flashcards_cache').clear();
    await Hive.box('pending_sync').clear();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.getString('clear_cache_success', isPersian),
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _confirmLogout(
    BuildContext context,
    WidgetRef ref,
    bool isPersian,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.getString('logout_confirm_title', isPersian),
        ),
        content: Text(
          AppLocalizations.getString('logout_confirm_body', isPersian),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.getString('cancel', isPersian)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(AppLocalizations.getString('logout', isPersian)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }

  void _showAboutSheet(BuildContext context, bool isPersian, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LingoSync',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${AppLocalizations.getString('app_version_label', isPersian)}: '
              '${AppConstants.appVersion}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            const Text('SaharCast.ir  •  SaharCast  •  sahar_cast'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends ConsumerWidget {
  final UserProfile profile;
  final bool isPersian;

  const _ProfileHeader({required this.profile, required this.isPersian});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final name = (profile.fullName?.trim().isNotEmpty ?? false)
        ? profile.fullName!
        : profile.email;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AvatarPicker(avatarUrl: profile.avatarUrl, initial: initial),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            profile.email,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _editEnglishLevel(context, ref, profile, isPersian),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 15,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    profile.englishLevel ??
                        AppLocalizations.getString('level_not_set', isPersian),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.edit_rounded,
                    size: 13,
                    color: theme.colorScheme.primary.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editEnglishLevel(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
    bool isPersian,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.getString('edit_english_level', isPersian),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.englishLevels.map((level) {
                return ChoiceChip(
                  label: Text(level),
                  selected: profile.englishLevel == level,
                  onSelected: (_) async {
                    Navigator.pop(context);
                    await HapticFeedback.selectionClick();
                    final result = await ref
                        .read(profileRepositoryProvider)
                        .updateProfile(englishLevel: level);
                    result.getExceptionOrNull(); // surfaced via stream refresh
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarPicker extends ConsumerStatefulWidget {
  final String? avatarUrl;
  final String initial;

  const _AvatarPicker({required this.avatarUrl, required this.initial});

  @override
  ConsumerState<_AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends ConsumerState<_AvatarPicker> {
  bool _isUploading = false;

  Future<void> _pickAndUpload() async {
    // ignore: unused_local_variable
    final isPersian = ref.read(isPersianProvider);
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _isUploading = true);
    try {
      final bytes = await picked.readAsBytes();
      final extension = picked.path.split('.').last.toLowerCase();
      final result = await ref
          .read(profileRepositoryProvider)
          .uploadAvatar(bytes, fileExtension: extension);

      if (mounted) {
        result.fold(
          onSuccess: (_) {},
          onFailure: (exception) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorHandler.getUserMessage(exception)),
                backgroundColor: Colors.red,
              ),
            );
          },
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: _isUploading ? null : _pickAndUpload,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
            backgroundImage: widget.avatarUrl != null
                ? NetworkImage(widget.avatarUrl!)
                : null,
            child: widget.avatarUrl == null
                ? Text(
                    widget.initial,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  )
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary,
                border: Border.all(
                  color: theme.scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: _isUploading
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.camera_alt_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final UserProfile profile;
  final bool isPersian;
  final ThemeData theme;

  const _StatsRow({
    required this.profile,
    required this.isPersian,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _StatChip(
            icon: Icons.workspace_premium_rounded,
            label: '${profile.score} XP',
            theme: theme,
          ),
          const SizedBox(width: 8),
          _StatChip(
            icon: Icons.local_fire_department_rounded,
            label:
                '${profile.streakDays} '
                '${AppLocalizations.getString('days_suffix', isPersian)}',
            theme: theme,
          ),
          const SizedBox(width: 8),
          _StatChip(
            icon: Icons.calendar_today_rounded,
            label:
                '${AppLocalizations.getString('day', isPersian)} '
                '${profile.currentDay}',
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeData theme;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
