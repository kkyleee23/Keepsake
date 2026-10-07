import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// A quiet profile: identity, then a short settings list. No vanity metrics.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          const _IdentityCard(),
          const SizedBox(height: AppSpacing.xl),
          const _SettingsGroup(
            items: [
              _SettingsItem(Icons.notifications_none, 'Notifications'),
              _SettingsItem(Icons.lock_outline, 'Privacy'),
              _SettingsItem(Icons.help_outline, 'Help'),
              _SettingsItem(Icons.info_outline, 'About Keepsake'),
            ],
          ),
        ],
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Not signed in', style: AppTypography.label),
              const SizedBox(height: 2),
              Text(
                'Sign in to keep your keepsakes safe.',
                style: AppTypography.caption,
              ),
            ],
          ),
        ],
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
  const _SettingsItem(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.inkSoft),
      title: Text(label, style: AppTypography.bodyLarge),
      trailing: const Icon(Icons.chevron_right, color: AppColors.inkFaint),
      onTap: () {},
    );
  }
}
