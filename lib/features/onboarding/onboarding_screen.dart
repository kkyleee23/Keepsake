import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/providers.dart';
import '../../shared/widgets/brand.dart';
import '../../shared/widgets/primary_button.dart';

class _Slide {
  const _Slide(this.title, this.body, this.mascot);
  final String title;
  final String body;
  final bool mascot; // mascot art vs. the app mark
}

const _slides = [
  _Slide(
    'Make something worth keeping.',
    'A letter, a memory, a small gift. Made for one person to keep.',
    true,
  ),
  _Slide(
    'Give it your way.',
    'Send a private link or a QR code. They open it without making an account.',
    false,
  ),
  _Slide(
    'Yours to revisit.',
    'Everything you make and receive stays in one quiet place.',
    true,
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
                padding: const EdgeInsets.only(right: AppSpacing.xs, top: AppSpacing.xs),
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
                label: last ? 'Get started' : 'Continue',
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (slide.mascot)
            const Mascot(size: 200)
          else
            const BrandMark(size: 132),
          const SizedBox(height: AppSpacing.xl),
          Text(
            slide.title,
            style: AppTypography.display,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            slide.body,
            style: AppTypography.bodyLarge.copyWith(color: AppColors.inkSoft),
            textAlign: TextAlign.center,
          ),
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
              color: i == active ? AppColors.accent : AppColors.hairline,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
