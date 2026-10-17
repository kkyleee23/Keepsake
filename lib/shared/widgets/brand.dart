import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The mascot's expressions, matching the art in assets/brand/states.
enum MascotPose {
  idle,
  happy,
  excited,
  thinking,
  wink,
  sad,
  surprised,
  typing,
  sending,
  received,
  hugging,
  sleepy,
  celebrating,
  working,
  uploading,
  error,
  offline,
  done,
  // Made with Figma AI from the same character description, for newer
  // features: books, writing, photos, gifts, greetings and privacy.
  reading,
  writing,
  photo,
  gift,
  waving,
  secure,
}

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
  const Wordmark({super.key, this.height = 34});

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

/// The mascot, optionally in a named [pose]. With [animate] it hops once
/// when it appears and again when tapped (no endless idle loop).
class Mascot extends StatefulWidget {
  const Mascot({super.key, this.size = 160, this.pose, this.animate = false});

  final double size;
  final MascotPose? pose;
  final bool animate;

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Timer? _hello;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 720),
      );
      // A hello hop, a moment after the screen settles.
      _hello = Timer(const Duration(milliseconds: 260), _hop);
    }
  }

  void _hop() {
    if (!mounted || MediaQuery.of(context).disableAnimations) return;
    _controller?.forward(from: 0);
  }

  @override
  void dispose() {
    _hello?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asset = widget.pose == null
        ? 'assets/brand/mascot.png'
        : 'assets/brand/states/${widget.pose!.name}.png';
    final image = Image.asset(
      asset,
      height: widget.size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );

    final controller = _controller;
    if (controller == null) return image;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _hop();
      },
      child: AnimatedBuilder(
        animation: controller,
        child: image,
        builder: (context, child) {
          final t = controller.value;
          // Up and down once, with a little squash on landing.
          final lift = math.sin(math.pi * Curves.easeOut.transform(t));
          final land = t > 0.75 ? math.sin(math.pi * (t - 0.75) / 0.25) : 0.0;
          return Transform.translate(
            offset: Offset(0, -widget.size * 0.07 * lift),
            child: Transform.scale(
              scaleX: 1 + 0.04 * land,
              scaleY: 1 - 0.05 * land,
              alignment: Alignment.bottomCenter,
              child: Transform.rotate(
                angle: 0.05 * math.sin(2 * math.pi * t) * (1 - t),
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}
