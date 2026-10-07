import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/brand.dart';

/// About Keepsake: identity, a short note on what it is, and the version.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.xl,
            AppSpacing.gutter,
            AppSpacing.xxl,
          ),
          children: [
            const Center(child: Mascot(size: 150)),
            const SizedBox(height: AppSpacing.lg),
            const Center(child: Wordmark(height: 30)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Make something worth keeping, and give it to someone.',
              style: AppTypography.bodyLarge.copyWith(color: AppColors.inkSoft),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Keepsake is for creating private digital gifts: a letter, a memory, '
              'a few reasons, an Open When collection. You make it, you give it to '
              'one person, and it stays theirs. It is not a social network, and it '
              'is not for an audience. One person can be the whole point.',
              style: AppTypography.bodyLarge.copyWith(height: 1.6),
            ),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: Text('Version 1.0.0', style: AppTypography.caption),
            ),
          ],
        ),
      ),
    );
  }
}

/// A plain-language explanation of how privacy works.
class PrivacyInfoScreen extends StatelessWidget {
  const PrivacyInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _InfoList(
      title: 'Privacy & security',
      blocks: [
        _Block('Your drafts are yours',
            'Drafts live on your device and in your account. No one else can see them.'),
        _Block('Private by link',
            'A published keepsake opens only through its private link or code. It is not listed or searchable.'),
        _Block('Add a PIN',
            'You can require a PIN to open. They type it to see the content.'),
        _Block('Sealed until its time',
            'A scheduled keepsake stays sealed until the moment you choose.'),
        _Block('Checked on the server',
            'Scheduled access, expiry, and PINs are enforced on the server, not just hidden in the app. A link alone never reveals protected content.'),
        _Block('PINs are never stored in the clear',
            'A PIN is hashed on the server and never kept on your device.'),
        _Block('You can take it back',
            'Delete a keepsake any time and its link stops working.'),
      ],
    );
  }
}

/// A short FAQ.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _InfoList(
      title: 'Help',
      blocks: [
        _Block('How do I send a keepsake?',
            'Create one, add what you want inside, then tap Publish. You get a link and a QR code to share.'),
        _Block('Does the other person need an account?',
            'No. They open the link, or enter the code on the Profile tab under "Open with a code".'),
        _Block("What's a PIN for?",
            'A little extra privacy. If you set one, they type it to open the keepsake.'),
        _Block('Where do keepsakes I open go?',
            'Into your library, under the Received tab.'),
        _Block('Can I change one after sending?',
            'Yes. Open it, edit it, and publish again. The same link updates.'),
      ],
    );
  }
}

class _Block {
  const _Block(this.heading, this.body);
  final String heading;
  final String body;
}

class _InfoList extends StatelessWidget {
  const _InfoList({required this.title, required this.blocks});

  final String title;
  final List<_Block> blocks;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.md,
            AppSpacing.gutter,
            AppSpacing.xxl,
          ),
          children: [
            for (final b in blocks)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.heading, style: AppTypography.heading),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      b.body,
                      style: AppTypography.bodyLarge
                          .copyWith(color: AppColors.inkSoft, height: 1.6),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
