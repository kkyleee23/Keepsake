import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/keepsake.dart';
import '../../data/providers.dart';
import '../reader/keepsake_reader.dart';
import '../../shared/widgets/empty_state.dart';

/// Shows the creator the exact recipient experience, wrapped in a thin preview
/// bar so it's clear this is a rehearsal, not the live keepsake.
class PreviewScreen extends ConsumerStatefulWidget {
  const PreviewScreen({super.key, required this.keepsakeId});

  final String keepsakeId;

  @override
  ConsumerState<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends ConsumerState<PreviewScreen> {
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _PreviewBar(onClose: () => context.pop()),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final k = _keepsake;
    if (k == null) {
      return EmptyState(
        icon: Icons.error_outline,
        title: "Can't preview this keepsake",
        message: 'It may have been deleted.',
        actionLabel: 'Go back',
        onAction: () => context.pop(),
      );
    }
    return KeepsakeReader(keepsake: k);
  }
}

class _PreviewBar extends StatelessWidget {
  const _PreviewBar({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      decoration: const BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close),
            tooltip: 'Close preview',
          ),
          Text('Preview', style: AppTypography.label),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Text('What they’ll see', style: AppTypography.caption),
          ),
        ],
      ),
    );
  }
}
