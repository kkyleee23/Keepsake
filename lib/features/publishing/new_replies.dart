import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/keepsake.dart';
import '../../data/models/keepsake_response.dart';
import '../../data/providers.dart';
import '../../shared/widgets/motion.dart';
import 'replies_section.dart';

/// Replies newer than [seen]. Everything counts as new until the creator
/// has looked once.
int countNewReplies(List<KeepsakeResponse> replies, DateTime? seen) =>
    seen == null
    ? replies.length
    : replies.where((r) => r.createdAt.isAfter(seen)).length;

/// When the creator last looked at each keepsake's replies. Kept on this
/// phone only.
class RepliesSeen extends Notifier<Map<String, DateTime>> {
  static const _prefix = 'replies_seen_';

  @override
  Map<String, DateTime> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return {
      for (final key in prefs.getKeys())
        if (key.startsWith(_prefix))
          key.substring(_prefix.length): ?DateTime.tryParse(
            prefs.getString(key) ?? '',
          ),
    };
  }

  Future<void> markSeen(String keepsakeId) async {
    final now = DateTime.now();
    state = {...state, keepsakeId: now};
    await ref
        .read(sharedPreferencesProvider)
        .setString('$_prefix$keepsakeId', now.toUtc().toIso8601String());
  }
}

final repliesSeenProvider =
    NotifierProvider<RepliesSeen, Map<String, DateTime>>(RepliesSeen.new);

/// How many replies came in since the creator last looked, for a keepsake
/// keyed as "id|token,token". 0 when they can't be loaded.
final newRepliesProvider = FutureProvider.autoDispose.family<int, String>((
  ref,
  key,
) async {
  final bar = key.indexOf('|');
  final id = key.substring(0, bar);
  final tokens = key.substring(bar + 1);
  final seen = ref.watch(repliesSeenProvider.select((m) => m[id]));
  final replies = await ref.watch(repliesProvider(tokens).future);
  return replies == null ? 0 : countNewReplies(replies, seen);
});

/// A small "2 new replies" tag for a keepsake card; nothing when there are
/// none (or the keepsake isn't one you shared).
class NewRepliesTag extends ConsumerWidget {
  const NewRepliesTag({super.key, required this.keepsake});

  final Keepsake keepsake;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = keepsake.allTokens;
    final n = keepsake.isReceived || tokens.isEmpty
        ? 0
        : ref
                  .watch(
                    newRepliesProvider('${keepsake.id}|${tokens.join(',')}'),
                  )
                  .valueOrNull ??
              0;
    return AnimatedSwitcher(
      duration: Motion.of(context, Motion.medium),
      switchInCurve: Motion.pop,
      transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
      child: n == 0
          ? const SizedBox.shrink(key: ValueKey(0))
          : Container(
              key: const ValueKey('new'),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.heart.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite, size: 12, color: AppColors.heart),
                  const SizedBox(width: 4),
                  Text(
                    '$n new ${n == 1 ? 'reply' : 'replies'}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.heart,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Marks a keepsake's replies as seen when the screen showing them opens and
/// again when it closes (so ones that arrived while open count as seen).
mixin MarksRepliesSeen<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  late final RepliesSeen _seen;

  String get seenKeepsakeId;

  @override
  void initState() {
    super.initState();
    _seen = ref.read(repliesSeenProvider.notifier);
    final id = seenKeepsakeId;
    scheduleMicrotask(() => _seen.markSeen(id));
  }

  @override
  void dispose() {
    final seen = _seen;
    final id = seenKeepsakeId;
    // After this frame: changing providers mid-teardown isn't allowed.
    scheduleMicrotask(() => seen.markSeen(id));
    super.dispose();
  }
}
