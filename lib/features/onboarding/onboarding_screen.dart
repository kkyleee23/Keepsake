import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/providers.dart';
import '../../shared/widgets/brand.dart';
import '../../shared/widgets/fill_scroll.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/whole_words.dart';

class _Slide {
  const _Slide(this.title, this.body, {this.pose, this.brand = false});
  final String title;
  final String body;
  final MascotPose? pose; // mascot expression for this slide
  final bool brand; // show the app mark instead of the mascot
}

const _slides = [
  _Slide(
    'Make something worth keeping.',
    'A letter, a memory, a small gift. Made for one person to keep.',
    pose: MascotPose.waving,
  ),
  _Slide(
    'Give it your way.',
    'Send a private link or a QR code. They open it without making an account.',
    brand: true,
  ),
  _Slide(
    'Yours to revisit.',
    'Everything you make and receive stays in one quiet place.',
    pose: MascotPose.hugging,
  ),
];

/// First-launch intro. Shows once; completion is remembered.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() =>
      ref.read(onboardingSeenProvider.notifier).complete();

  void _next() {
    if (_page < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(
                  right: AppSpacing.xs,
                  top: AppSpacing.xs,
                ),
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Skip'),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => _SlideView(slide: _slides[i]),
              ),
            ),
            _Dots(count: _slides.length, active: _page),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.lg,
                AppSpacing.gutter,
                AppSpacing.xl,
              ),
              child: PrimaryButton(
                label: last ? 'Get Started' : 'Continue',
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final scale = MediaQuery.textScalerOf(context).scale(1);
    // Smaller art on short screens and with large text, so the words fit.
    final art = (size.height * 0.26 / (scale > 1 ? 1 + (scale - 1) * 0.5 : 1))
        .clamp(88.0, 200.0);
    final picture = slide.brand
        ? BrandMark(size: art * 0.66)
        : Mascot(size: art, pose: slide.pose, animate: true);
    final wide = size.width > size.height;
    final words = [
      WholeWords(
        slide.title,
        style: wide ? AppTypography.displaySmall : AppTypography.display,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        slide.body,
        style: AppTypography.bodyLarge.copyWith(color: AppColors.inkSoft),
        textAlign: TextAlign.center,
      ),
    ];

    // Landscape phones: the picture sits beside the words.
    if (wide) {
      return FillScroll(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            picture,
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: words,
              ),
            ),
          ],
        ),
      );
    }
    return FillScroll(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          picture,
          const SizedBox(height: AppSpacing.xl),
          ...words,
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == active ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == active
                  ? AppColors.accent
                  : AppColors.inkFaint.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
