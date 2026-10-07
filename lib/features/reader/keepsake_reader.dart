import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/keepsake.dart';
import '../sections/section_view.dart';
import '../../shared/widgets/primary_button.dart';

/// The recipient experience: a restrained sealed cover that opens into the
/// content. Shared by Preview and (later) the live recipient route so the
/// creator sees exactly what will be received.
class KeepsakeReader extends StatefulWidget {
  const KeepsakeReader({super.key, required this.keepsake});

  final Keepsake keepsake;

  @override
  State<KeepsakeReader> createState() => _KeepsakeReaderState();
}

class _KeepsakeReaderState extends State<KeepsakeReader> {
  bool _opened = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      child: _opened
          ? _Content(keepsake: widget.keepsake)
          : _Cover(
              keepsake: widget.keepsake,
              onOpen: () => setState(() => _opened = true),
            ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.keepsake, required this.onOpen});

  final Keepsake keepsake;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final k = keepsake;
    return Padding(
      key: const ValueKey('cover'),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),
          Text(k.occasion.label.toUpperCase(),
              style: AppTypography.caption, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          Text(
            k.recipientName.isEmpty ? k.title : 'For ${k.recipientName}',
            style: AppTypography.display,
            textAlign: TextAlign.center,
          ),
          if (k.coverNote != null && k.coverNote!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              k.coverNote!,
              style: AppTypography.bodyLarge.copyWith(color: AppColors.inkSoft),
              textAlign: TextAlign.center,
            ),
          ],
          const Spacer(),
          if (k.senderName.isNotEmpty) ...[
            Text('Made for you by ${k.senderName}',
                style: AppTypography.caption, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
          ],
          PrimaryButton(label: 'Open', onPressed: onOpen, expand: false),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.keepsake});

  final Keepsake keepsake;

  @override
  Widget build(BuildContext context) {
    final sections = keepsake.orderedSections;
    return ListView.separated(
      key: const ValueKey('content'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.xl,
        AppSpacing.gutter,
        AppSpacing.xxxl,
      ),
      itemCount: sections.length + 1,
      separatorBuilder: (_, index) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: index == 0
            ? const SizedBox.shrink()
            : const Divider(color: AppColors.hairline),
      ),
      itemBuilder: (context, index) {
        if (index == 0) {
          // A quiet opening line before the content.
          return Text(
            keepsake.recipientName.isEmpty
                ? keepsake.title
                : 'For ${keepsake.recipientName}',
            style: AppTypography.displaySmall,
          );
        }
        return SectionView(section: sections[index - 1]);
      },
    );
  }
}
