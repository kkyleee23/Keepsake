import 'package:flutter/material.dart';

/// The app-icon mark (mascot on a green rounded square).
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/brand/app_icon.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
  }
}

/// The "Keepsake" wordmark with the leaf.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.height = 30});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/brand/wordmark.png',
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
  }
}

/// The mascot illustration, for warm moments (onboarding, empty states).
class Mascot extends StatelessWidget {
  const Mascot({super.key, this.size = 160});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/brand/mascot.png',
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
  }
}
