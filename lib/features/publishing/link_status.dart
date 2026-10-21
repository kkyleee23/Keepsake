import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/keepsake.dart';
import '../../data/providers.dart';
import '../../data/remote/keepsake_backend.dart';
import '../../shared/widgets/motion.dart';
import '../keepsakes/application/keepsakes_controller.dart';

/// Opened receipts for every link you've shared, fetched in one go. Null
/// when they can't be loaded.
final linkStatusProvider = FutureProvider.autoDispose<Map<String, LinkStatus>?>(
  (ref) async {
    final all = ref.watch(keepsakesControllerProvider).valueOrNull ?? const [];
    final tokens = [
      for (final k in all)
        if (!k.isReceived && k.shareToken != null) k.shareToken!,
    ];
    if (tokens.isEmpty) return const {};
    return ref.read(keepsakeBackendProvider).fetchStatus(tokens);
  },
);

/// A small "Opened Oct 21" tag for a card; nothing until it's opened.
class OpenedTag extends ConsumerWidget {
  const OpenedTag({super.key, required this.keepsake});

  final Keepsake keepsake;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = keepsake.shareToken;
    final status = token == null || keepsake.isReceived
        ? null
        : ref.watch(linkStatusProvider).valueOrNull?[token];
    final opened = status?.firstOpenedAt;
    return AnimatedSwitcher(
      duration: Motion.of(context, Motion.medium),
      switchInCurve: Motion.pop,
      transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
      child: opened == null
          ? const SizedBox.shrink(key: ValueKey(0))
          : Container(
              key: const ValueKey('opened'),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.drafts_outlined,
                    size: 13,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Opened ${DateFormat.MMMd().format(opened)}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// One plain sentence about whether they've opened it, for the link page.
String? receiptLine(Keepsake k, LinkStatus? s) {
  if (s == null) return null;
  if (!s.receipts) return 'You chose not to know when it’s opened.';
  final who = k.recipientName.isEmpty ? 'They' : k.recipientName;
  final first = s.firstOpenedAt;
  if (first == null) return 'Not opened yet. You’ll see it here when it is.';
  final when = DateFormat.yMMMd().format(first);
  return s.openCount > 1
      ? '$who opened it on $when, and has come back ${s.openCount - 1} '
            'more time${s.openCount == 2 ? '' : 's'}.'
      : '$who opened it on $when.';
}
