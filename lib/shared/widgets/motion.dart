import 'package:flutter/material.dart';

import 'gift_art.dart' show PaperTextures;
import 'paper.dart';

/// One place for how things move in Keepsake: a few durations, a soft curve,
/// and a page transition. Everything goes still when the phone asks for
/// reduced motion.
abstract final class Motion {
  static const Duration short = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 320);
  static const Duration long = Duration(milliseconds: 520);

  /// A gentle settle: quick start, soft landing.
  static const Curve settle = Curves.easeOutCubic;

  /// A tiny overshoot for playful moments (a tab icon hopping, a tag popping).
  static const Curve pop = Curves.easeOutBack;

  static bool reduced(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  /// [d], or zero when reduced motion is on.
  static Duration of(BuildContext context, Duration d) =>
      reduced(context) ? Duration.zero : d;

  /// A route that fades in while rising a few pixels, like a card being set
  /// down. Used for pushes that aren't handled by the router.
  /// The page sits on paper ([texture]) so nothing shows through it.
  static Route<T> route<T>(
    BuildContext context,
    Widget page, {
    String texture = PaperTextures.stone,
  }) {
    return PageRouteBuilder<T>(
      transitionDuration: of(context, medium),
      reverseTransitionDuration: of(context, short),
      pageBuilder: (_, _, _) => PaperPage(texture: texture, child: page),
      transitionsBuilder: (_, anim, _, child) =>
          SoftRiseTransition(animation: anim, child: child),
    );
  }
}

/// Fade plus a small upward slide.
class SoftRiseTransition extends StatelessWidget {
  const SoftRiseTransition({
    super.key,
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Motion.settle,
      reverseCurve: Curves.easeIn,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

/// The app-wide page transition (set in the theme) so every screen opens the
/// same soft way.
class SoftRisePageTransitionsBuilder extends PageTransitionsBuilder {
  const SoftRisePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (Motion.reduced(context)) return child;
    // The page underneath dims back slightly while the new one rises.
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.92).animate(secondaryAnimation),
      child: SoftRiseTransition(animation: animation, child: child),
    );
  }
}

/// Fades and lifts its child into place once, after an optional [delay].
/// Give list items increasing [index] values for a gentle stagger.
class RiseIn extends StatefulWidget {
  const RiseIn({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  State<RiseIn> createState() => _RiseInState();
}

class _RiseInState extends State<RiseIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Motion.medium,
  );

  @override
  void initState() {
    super.initState();
    // Cap the stagger so long lists don't keep you waiting.
    final delay = Duration(milliseconds: 45 * widget.index.clamp(0, 8));
    Future.delayed(delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) _c.value = 1;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      SoftRiseTransition(animation: _c, child: widget.child);
}

/// Shrinks a touch while pressed and springs back: a physical "press" for
/// cards and buttons. Doesn't handle taps itself; wrap a tappable widget.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.scale = 0.97});

  final Widget child;
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: Motion.of(context, Motion.short),
        curve: _down ? Curves.easeOut : Motion.pop,
        child: widget.child,
      ),
    );
  }
}

/// Holds every tab's screen (so each keeps its scroll and state) and
/// cross-fades between them with a small settle, instead of a hard cut.
class FadingTabs extends StatelessWidget {
  const FadingTabs({super.key, required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final d = Motion.of(context, Motion.medium);
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < children.length; i++)
          IgnorePointer(
            ignoring: i != index,
            child: TickerMode(
              enabled: i == index,
              child: AnimatedOpacity(
                opacity: i == index ? 1 : 0,
                duration: d,
                curve: Motion.settle,
                child: AnimatedScale(
                  scale: i == index ? 1 : 0.985,
                  duration: d,
                  curve: Motion.settle,
                  child: ExcludeSemantics(
                    excluding: i != index,
                    child: children[i],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
