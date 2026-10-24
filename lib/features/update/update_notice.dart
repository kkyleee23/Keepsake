import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/providers.dart';
import '../../data/remote/update_check.dart';
import '../../shared/widgets/brand.dart';
import '../../shared/widgets/gift_art.dart';
import '../../shared/widgets/paper.dart';
import '../../shared/widgets/primary_button.dart';

/// Remembers the one build someone has already been told about, so a notice
/// they put away does not come back every time they open the app. A build
/// they must have ignores this.
class UpdateDismissed extends Notifier<int> {
  static const _key = 'update.dismissed.build.v1';

  @override
  int build() => ref.read(sharedPreferencesProvider).getInt(_key) ?? 0;

  Future<void> putAway(String versionName) async {
    final code = _codeOf(versionName);
    await ref.read(sharedPreferencesProvider).setInt(_key, code);
    state = code;
  }

  static int _codeOf(String versionName) => versionName.hashCode & 0x7fffffff;
}

final updateDismissedProvider = NotifierProvider<UpdateDismissed, int>(
  UpdateDismissed.new,
);

Future<void> _openDownloadPage(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// A quiet card on Home when a newer build is out. Easy to put away.
class UpdateNotice extends ConsumerWidget {
  const UpdateNotice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(updateInfoProvider).valueOrNull;
    if (info == null || !info.show || info.mustUpdate) {
      return const SizedBox.shrink();
    }
    if (ref.watch(updateDismissedProvider) ==
        UpdateDismissed._codeOf(info.versionName)) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        image: paperImage(PaperTextures.cream),
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Mascot(pose: MascotPose.waving, size: 54),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('A newer Keepsake is ready', style: AppTypography.heading),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  info.note.isNotEmpty
                      ? info.note
                      : 'Version ${info.versionName} is on the website.',
                  style: AppTypography.label,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    PrimaryButton(
                      label: 'Get It',
                      expand: false,
                      onPressed: () => _openDownloadPage(info.url),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    TextButton(
                      onPressed: () => ref
                          .read(updateDismissedProvider.notifier)
                          .putAway(info.versionName),
                      child: const Text('Not Now'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Stands in front of everything when the installed build is too old to keep
/// using. There is no way past it except installing the new one, which is the
/// point: it is only ever turned on when an old build would do the wrong
/// thing.
class UpdateGate extends ConsumerWidget {
  const UpdateGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(updateInfoProvider).valueOrNull;
    if (info == null || !info.mustUpdate) return child;

    return Material(
      color: AppColors.paper,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Mascot(pose: MascotPose.waving, size: 120),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Time for the new Keepsake',
                  style: AppTypography.title,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  info.note.isNotEmpty
                      ? info.note
                      : 'This version is too old to keep going. The new one '
                            'is on the website and takes a moment to install.',
                  style: AppTypography.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: 'Get the New Version',
                  onPressed: () => _openDownloadPage(info.url),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Your drafts stay on this phone.',
                  style: AppTypography.caption,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
