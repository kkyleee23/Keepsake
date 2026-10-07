import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/keepsake.dart';
import 'application/keepsakes_controller.dart';
import 'widgets/keepsake_card.dart';
import '../../shared/widgets/brand.dart';
import '../../shared/widgets/empty_state.dart';

enum _Lib {
  created('Created'),
  received('Received'),
  drafts('Drafts'),
  archived('Archived');

  const _Lib(this.label);
  final String label;

  bool matches(Keepsake k) {
    switch (this) {
      case _Lib.created:
        return !k.isDraft && !k.isReceived && !k.isArchived;
      case _Lib.received:
        return k.isReceived && !k.isArchived;
      case _Lib.drafts:
        return k.isDraft && !k.isReceived && !k.isArchived;
      case _Lib.archived:
        return k.isArchived;
    }
  }
}

/// The library: everything made and received, in one place.
class KeepsakesScreen extends ConsumerStatefulWidget {
  const KeepsakesScreen({super.key});

  @override
  ConsumerState<KeepsakesScreen> createState() => _KeepsakesScreenState();
}

class _KeepsakesScreenState extends ConsumerState<KeepsakesScreen> {
  _Lib _filter = _Lib.created;
  String _query = '';

  void _open(Keepsake k) {
    context.push(k.isDraft ? '/editor/${k.id}' : '/preview/${k.id}');
  }

  bool _matchesQuery(Keepsake k) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return k.title.toLowerCase().contains(q) ||
        k.recipientName.toLowerCase().contains(q) ||
        k.senderName.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(keepsakesControllerProvider).valueOrNull ?? const [];
    final items =
        all.where((k) => _filter.matches(k) && _matchesQuery(k)).toList();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.xl,
              AppSpacing.gutter,
              AppSpacing.md,
            ),
            child: Text('Keepsakes', style: AppTypography.displaySmall),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: const InputDecoration(
                hintText: 'Search',
                prefixIcon: Icon(Icons.search, color: AppColors.inkFaint),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
              children: [
                for (final f in _Lib.values)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: _FilterChip(
                      label: f.label,
                      selected: _filter == f,
                      onTap: () => setState(() => _filter = f),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: items.isEmpty
                ? _emptyFor(_filter)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      0,
                      AppSpacing.gutter,
                      AppSpacing.xxl,
                    ),
                    children: [
                      for (final k in items)
                        KeepsakeCard(
                          keepsake: k,
                          onTap: () => _open(k),
                          onLongPress: () => _showActions(k),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _emptyFor(_Lib f) {
    if (_query.isNotEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'Nothing matches',
        message: 'Try a different search.',
      );
    }
    switch (f) {
      case _Lib.created:
        return EmptyState(
          illustration: const Mascot(size: 150),
          title: 'No keepsakes yet',
          message: "Make something they'll want to keep.",
          actionLabel: 'Create a Keepsake',
          onAction: () => context.go('/create'),
        );
      case _Lib.received:
        return const EmptyState(
          icon: Icons.inbox_outlined,
          title: 'Nothing received yet',
          message: 'Keepsakes you open will be saved here.',
        );
      case _Lib.drafts:
        return const EmptyState(
          icon: Icons.edit_outlined,
          title: 'No drafts',
          message: 'Unfinished keepsakes wait for you here.',
        );
      case _Lib.archived:
        return const EmptyState(
          icon: Icons.archive_outlined,
          title: 'Nothing archived',
          message: 'Archived keepsakes are tucked away here.',
        );
    }
  }

  void _showActions(Keepsake k) {
    final canShare = k.shareToken != null && !k.isReceived;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              leading: const Icon(Icons.open_in_new, color: AppColors.inkSoft),
              title: Text(k.isDraft ? 'Keep editing' : 'Open',
                  style: AppTypography.bodyLarge),
              onTap: () {
                Navigator.pop(ctx);
                _open(k);
              },
            ),
            if (canShare)
              ListTile(
                leading: const Icon(Icons.link, color: AppColors.inkSoft),
                title: Text('Copy link', style: AppTypography.bodyLarge),
                onTap: () async {
                  Navigator.pop(ctx);
                  await Clipboard.setData(
                      ClipboardData(text: AppConfig.shareUrl(k.shareToken!)));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link copied')),
                    );
                  }
                },
              ),
            ListTile(
              leading: Icon(
                k.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                color: AppColors.inkSoft,
              ),
              title: Text(k.isArchived ? 'Unarchive' : 'Archive',
                  style: AppTypography.bodyLarge),
              onTap: () {
                Navigator.pop(ctx);
                final c = ref.read(keepsakesControllerProvider.notifier);
                if (k.isArchived) {
                  c.unarchive(k);
                } else {
                  c.archive(k);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: Text('Delete',
                  style: AppTypography.bodyLarge
                      .copyWith(color: AppColors.error)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(k);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Keepsake k) async {
    final published = k.shareToken != null && !k.isReceived;
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        icon: const Icon(Icons.delete_outline, color: AppColors.error),
        title: Text('Delete "${k.title}"?', style: AppTypography.heading),
        content: Text(
          published
              ? "This can't be undone, and the link will stop working."
              : "This can't be undone.",
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes == true) {
      await ref.read(keepsakesControllerProvider.notifier).deleteKeepsake(k);
    }
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.accent : AppColors.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.hairline,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.body.copyWith(
              color: selected ? AppColors.onAccent : AppColors.inkSoft,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
