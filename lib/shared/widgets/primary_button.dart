import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'motion.dart';

/// The one filled, full-width primary action for a screen.
///
/// Shows a loading spinner and disables itself while [onPressed] is running or
/// when [loading] is true, so a tap can't double-submit (design system 7).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(AppColors.onAccent),
            ),
          )
        : _content();

    final button = ElevatedButton(
      onPressed: loading ? null : onPressed,
      child: child,
    );

    final sized = expand
        ? SizedBox(width: double.infinity, child: button)
        : button;
    // A small, springy press so taps feel physical.
    return onPressed == null || loading ? sized : Pressable(child: sized);
  }

  // Labels may wrap to a second line with very large text instead of
  // overflowing the button.
  Widget _content() {
    final text = Text(label, textAlign: TextAlign.center, maxLines: 2);
    if (icon == null) return text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Flexible(child: text),
      ],
    );
  }

}
