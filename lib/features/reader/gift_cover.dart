import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/brand.dart';
import '../../shared/widgets/fill_scroll.dart';
import '../../shared/widgets/gift_art.dart';
import '../../shared/widgets/primary_button.dart';

/// The moment before opening: a sealed envelope with the mascot peeking from
/// behind it. Tapping Open lifts the flap, breaks the seal and slides the
/// letter out, then hands over to the content.
///
/// Shared by the live recipient screen and the creator's preview, so both see
/// the same thing.
class GiftCover extends StatefulWidget {
  const GiftCover({
    super.key,
    required this.onOpen,
    this.occasion,
    this.recipientName,
    this.title,
    this.coverNote,
    this.senderName,
    this.playOpening = true,
  });

  final VoidCallback onOpen;
  final String? occasion;
  final String? recipientName;
  final String? title;
  final String? coverNote;
  final String? senderName;

  /// False when something else must happen first (for example a PIN), so the
  /// envelope doesn't open before the content is actually unlocked.
  final bool playOpening;

  @override
  State<GiftCover> createState() => _GiftCoverState();
}

class _GiftCoverState extends State<GiftCover>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );
  late final Animation<double> _open = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.0, 0.45, curve: Curves.easeInOut),
  );
  late final Animation<double> _rise = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.38, 0.92, curve: Curves.easeOut),
  );
  bool _opening = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _onOpen() async {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (!widget.playOpening || reduceMotion) {
      widget.onOpen();
      return;
    }
    setState(() => _opening = true);
    await _c.forward();
    if (mounted) widget.onOpen();
  }

  String? _clean(String? s) {
    final t = s?.trim() ?? '';
    return t.isEmpty ? null : t;
  }

  @override
  Widget build(BuildContext context) {
    final occasion = _clean(widget.occasion);
    final to = _clean(widget.recipientName);
    final note = _clean(widget.coverNote);
    final from = _clean(widget.senderName);
    final heading = to != null
        ? 'For $to'
        : (_clean(widget.title) ?? 'Something for you');

    return FillScroll(
      child: Column(
        children: [
          const Spacer(),
          if (occasion != null) ...[
            Text(
              occasion,
              style: AppTypography.eyebrow,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          Text(
            heading,
            style: AppTypography.display,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Builder(
            builder: (context) {
              // Screen width, not a LayoutBuilder: FillScroll measures its
              // child's intrinsic height, which a LayoutBuilder can't report.
              final screen = MediaQuery.sizeOf(context);
              final w = [
                280.0,
                screen.width - AppSpacing.xl * 2 - AppSpacing.lg,
                screen.height * 0.34, // keep Open on screen on short phones
              ].reduce(math.min);
              return AnimatedBuilder(
                animation: _c,
                builder: (context, _) => SizedBox(
                  width: w + AppSpacing.lg,
                  height:
                      w * EnvelopeArt.aspect * EnvelopeArt.headroom +
                      AppSpacing.md,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      Positioned(
                        bottom: AppSpacing.md,
                        child: EnvelopeArt(
                          width: w,
                          open: _open.value,
                          rise: _rise.value,
                        ),
                      ),
                      // The mascot sits on the envelope's corner, then hops
                      // away as it opens.
                      Positioned(
                        right: -AppSpacing.xs,
                        bottom: _open.value * 24,
                        child: Opacity(
                          opacity: (1 - _open.value * 1.6).clamp(0.0, 1.0),
                          child: Mascot(
                            size: w * 0.4,
                            pose: MascotPose.excited,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (note != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              note,
              style: AppTypography.bodyLarge.copyWith(color: AppColors.inkSoft),
              textAlign: TextAlign.center,
            ),
          ],
          const Spacer(),
          if (from != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Leaf(size: 14, angle: -0.3),
                const SizedBox(width: AppSpacing.xxs),
                Flexible(
                  child: Text(
                    'Made for you by $from',
                    style: AppTypography.caption,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          PrimaryButton(label: 'Open', onPressed: _opening ? null : _onOpen),
        ],
      ),
    );
  }
}
