import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/keepsake.dart';
import '../../data/providers.dart';
import '../../shared/widgets/brand.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/primary_button.dart';

/// Confirmation after publishing: the link and QR to give to the recipient.
class PublishedScreen extends ConsumerStatefulWidget {
  const PublishedScreen({super.key, required this.keepsakeId});

  final String keepsakeId;

  @override
  ConsumerState<PublishedScreen> createState() => _PublishedScreenState();
}

class _PublishedScreenState extends ConsumerState<PublishedScreen> {
  Keepsake? _keepsake;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final k =
        await ref.read(keepsakeRepositoryProvider).getById(widget.keepsakeId);
    if (!mounted) return;
    setState(() {
      _keepsake = k;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final k = _keepsake;
    final token = k?.shareToken;
    if (k == null || token == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.error_outline,
          title: 'Not published',
          message: 'This keepsake doesn’t have a link yet.',
          actionLabel: 'Go home',
          onAction: () => context.go('/home'),
        ),
      );
    }

    final url = AppConfig.shareUrl(token);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/keepsakes'),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.md,
            AppSpacing.gutter,
            AppSpacing.xxl,
          ),
          children: [
            const Center(child: Mascot(size: 120)),
            const SizedBox(height: AppSpacing.md),
            Text('Ready to give', style: AppTypography.display),
            const SizedBox(height: AppSpacing.xs),
            Text(
              k.recipientName.isEmpty
                  ? 'Share this link, or let them scan the code.'
                  : 'Share this with ${k.recipientName}, '
                      'or let them scan the code.',
              style: AppTypography.bodyLarge.copyWith(color: AppColors.inkSoft),
            ),
            const SizedBox(height: AppSpacing.xl),

            Center(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadius.card,
                  border: Border.all(color: AppColors.hairline),
                ),
                child: QrImageView(
                  data: url,
                  size: 200,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: AppColors.ink,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            _LinkRow(url: url),
            const SizedBox(height: AppSpacing.lg),

            PrimaryButton(
              label: 'Share',
              icon: Icons.ios_share,
              onPressed: () {
                final subject = k.recipientName.isEmpty
                    ? 'A keepsake for you'
                    : 'A keepsake for ${k.recipientName}';
                Share.share(url, subject: subject);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: () => context.go('/keepsakes'),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.xs, AppSpacing.xs, AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              url,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body.copyWith(color: AppColors.ink),
            ),
          ),
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied')),
                );
              }
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy'),
          ),
        ],
      ),
    );
  }
}
