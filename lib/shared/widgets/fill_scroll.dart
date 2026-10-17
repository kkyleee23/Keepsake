import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Fills the screen so a [Column] with [Spacer]s can center and pin content,
/// but scrolls instead of overflowing on short screens or when the keyboard
/// is open.
class FillScroll extends StatelessWidget {
  const FillScroll({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (constraints.maxHeight - padding.vertical)
                .clamp(0.0, double.infinity)
                .toDouble(),
          ),
          child: IntrinsicHeight(child: child),
        ),
      ),
    );
  }
}
