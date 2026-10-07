import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/remote/auth_service.dart';
import '../keepsakes/application/keepsakes_controller.dart';
import 'edit_profile_screen.dart';
import 'info_screens.dart';

/// A quiet profile: identity, a recipient entry point, then a short list.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  /// Accepts either a raw token or a full share link and opens it.
  Future<void> _openWithCode(BuildContext context) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Open with a code', style: AppTypography.heading),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Paste a link or code'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Open'),
          ),
        ],
      ),
    );
    if (value == null || value.isEmpty || !context.mounted) return;
    final token = value.contains('/receive/')
        ? value.split('/receive/').last.split(RegExp(r'[/?#]')).first
        : value;
    if (token.isNotEmpty) context.push('/receive/$token');
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Sign out?', style: AppTypography.heading),
        content: Text(
          'Your published keepsakes stay safe. Drafts on this device remain here.',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (yes == true) await ref.read(authServiceProvider).signOut();
  }

  Future<void> _confirmWipe(BuildContext context, WidgetRef ref) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        icon: const Icon(Icons.warning_amber_rounded, color: AppColors.error),
        title: Text('Delete everything?', style: AppTypography.heading),
        content: Text(
          'This removes every keepsake you have made and received, on this '
          'device and on the server. This cannot be undone.',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );
    if (yes == true) {
      await ref.read(keepsakesControllerProvider.notifier).wipeEverything();
      await ref.read(authServiceProvider).signOut();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.read(authServiceProvider);
    final name = auth.displayName ?? 'Your account';
    final email = auth.email ?? '';

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.xl,
          AppSpacing.gutter,
          AppSpacing.xxl,
        ),
        children: [
          Text('Profile', style: AppTypography.displaySmall),
          const SizedBox(height: AppSpacing.lg),
          _IdentityCard(
            name: name,
            email: email,
            onTap: () => _push(context, const EditProfileScreen()),
          ),
          const SizedBox(height: AppSpacing.md),
          _ActionCard(
            icon: Icons.qr_code_scanner,
            title: 'Open with a code',
            subtitle: 'Received a keepsake? Paste its link or code.',
            onTap: () => _openWithCode(context),
          ),
          const SizedBox(height: AppSpacing.xl),
          _SettingsGroup(
            items: [
              _SettingsItem(
                Icons.person_outline,
                'Edit profile',
                () => _push(context, const EditProfileScreen()),
              ),
              _SettingsItem(
                Icons.lock_outline,
                'Privacy & security',
                () => _push(context, const PrivacyInfoScreen()),
              ),
              _SettingsItem(
                Icons.help_outline,
                'Help',
                () => _push(context, const HelpScreen()),
              ),
              _SettingsItem(
                Icons.info_outline,
                'About Keepsake',
                () => _push(context, const AboutScreen()),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (email.isNotEmpty) ...[
            TextButton.icon(
              onPressed: () => _confirmSignOut(context, ref),
              icon: const Icon(Icons.logout, size: 20),
              label: const Text('Sign out'),
            ),
            TextButton.icon(
              onPressed: () => _confirmWipe(context, ref),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              icon: const Icon(Icons.delete_outline, size: 20),
              label: const Text('Delete my data'),
            ),
          ],
        ],
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.name,
    required this.email,
    required this.onTap,
  });

  final String name;
  final String email;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.card,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.card,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadius.card,
            border: Border.all(color: AppColors.hairline),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.surfaceAlt,
                child: Icon(Icons.person_outline, color: AppColors.inkSoft),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTypography.label),
                    const SizedBox(height: 2),
                    Text(
                      email.isEmpty ? 'Signed in' : email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.inkFaint),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.card,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.card,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadius.card,
            border: Border.all(color: AppColors.hairline),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.accent),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.label),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTypography.caption),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.inkFaint),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.items});

  final List<_SettingsItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            items[i],
          ],
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem(this.icon, this.label, this.onTap);

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.inkSoft),
      title: Text(label, style: AppTypography.bodyLarge),
      trailing: const Icon(Icons.chevron_right, color: AppColors.inkFaint),
      onTap: onTap,
    );
  }
}
