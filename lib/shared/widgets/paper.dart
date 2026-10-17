import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import 'gift_art.dart';

/// A tiled paper texture as a decoration image.
DecorationImage paperImage(String asset, {ColorFilter? colorFilter}) =>
    DecorationImage(
      image: AssetImage(asset),
      repeat: ImageRepeat.repeat,
      scale: 1 / PaperTextures.tileScale,
      colorFilter: colorFilter,
    );

/// Puts a screen on paper: a solid, textured backing behind a transparent
/// Scaffold and app bar. The backing is opaque, so during page transitions
/// and the iOS back swipe the page underneath never shows through.
class PaperPage extends StatelessWidget {
  const PaperPage({
    super.key,
    required this.child,
    this.texture = PaperTextures.stone,
    this.color = AppColors.paper,
  });

  final Widget child;
  final String texture;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(color: color, image: paperImage(texture)),
      child: Theme(
        data: theme.copyWith(
          scaffoldBackgroundColor: Colors.transparent,
          appBarTheme: theme.appBarTheme.copyWith(
            backgroundColor: Colors.transparent,
          ),
        ),
        child: child,
      ),
    );
  }
}

/// A card made of cream paper with a hairline edge. Keeps the tap ripple
/// (the texture is painted as ink, under the ripple).
class PaperCard extends StatelessWidget {
  const PaperCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.all(16),
    this.radius = AppRadius.card,
    this.texture = PaperTextures.cream,
    this.color = AppColors.surface,
    this.edge = AppColors.hairline,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsets padding;
  final BorderRadius radius;
  final String texture;
  final Color color;
  final Color edge;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    return Material(
      type: MaterialType.transparency,
      child: Ink(
        decoration: BoxDecoration(
          color: color,
          image: paperImage(texture),
          borderRadius: radius,
          border: Border.all(color: edge),
        ),
        child: onTap == null && onLongPress == null
            ? content
            : InkWell(
                onTap: onTap,
                onLongPress: onLongPress,
                borderRadius: radius,
                child: content,
              ),
      ),
    );
  }
}
