import 'package:flutter/material.dart';

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

/// The mascot, optionally in a named [pose], with an optional gentle idle bob.
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

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2600),
      )..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
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
    if (controller == null || MediaQuery.of(context).disableAnimations) {
      return image;
    }
    return AnimatedBuilder(
      animation: controller,
      child: image,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(controller.value);
        return Transform.translate(offset: Offset(0, -5 * t), child: child);
      },
    );
  }
}
