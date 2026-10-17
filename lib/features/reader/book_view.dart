import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/brand.dart';
import '../../shared/widgets/gift_art.dart';
import '../../shared/widgets/motion.dart';
import 'long_form.dart';

/// One page of a book gift.
class BookPage {
  const BookPage({required this.title, required this.body});

  final String title;
  final String body;
}

/// The closed book: an evergreen cloth cover with a darker spine, a leaf on
/// the front, and the page block peeking out on the right.
class BookCoverArt extends StatelessWidget {
  const BookCoverArt({
    super.key,
    required this.title,
    this.author,
    this.width = 200,
  });

  final String title;
  final String? author;
  final double width;

  @override
  Widget build(BuildContext context) {
    final h = width * 1.32;
    final spine = width * 0.08;
    return SizedBox(
      width: width + 8,
      height: h + 6,
      child: Stack(
        children: [
          // Page block behind the cover.
          Positioned(
            left: 8,
            top: 6,
            child: CustomPaint(
              size: Size(width, h),
              painter: _PageBlockPainter(),
            ),
          ),
          Container(
            width: width,
            height: h,
            decoration: BoxDecoration(
              color: AppColors.accent,
              // Woven book cloth, dyed evergreen.
              image: _cloth(AppColors.accent),
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(4),
                right: Radius.circular(10),
              ),
              border: Border.all(color: AppColors.accentPressed),
            ),
            child: Row(
              children: [
                Container(
                  width: spine,
                  decoration: BoxDecoration(
                    color: AppColors.accentPressed,
                    image: _cloth(AppColors.accentPressed),
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(3),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(width * 0.09),
                    child: Column(
                      children: [
                        const Spacer(),
                        Leaf(
                          size: width * 0.16,
                          color: AppColors.giftPaper.withValues(alpha: 0.9),
                          angle: -0.3,
                        ),
                        SizedBox(height: width * 0.06),
                        Text(
                          title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: AppTypography.heading.copyWith(
                            color: AppColors.giftPaper,
                            fontSize: width * 0.1,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const Spacer(),
                        if ((author ?? '').isNotEmpty)
                          Text(
                            author!,
                            style: AppTypography.eyebrow.copyWith(
                              color: AppColors.sageSoft,
                              fontSize: width * 0.1,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

DecorationImage _cloth(Color dye) => DecorationImage(
  image: const AssetImage(PaperTextures.cloth),
  repeat: ImageRepeat.repeat,
  scale: 1 / PaperTextures.tileScale,
  colorFilter: ColorFilter.mode(dye, BlendMode.multiply),
);

/// Book paper, for the pages.
const DecorationImage _bookPaper = DecorationImage(
  image: AssetImage(PaperTextures.cream),
  repeat: ImageRepeat.repeat,
  scale: 1 / PaperTextures.tileScale,
);

class _PageBlockPainter extends CustomPainter {
  _PageBlockPainter() : super(repaint: PaperTextures.instance);

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndCorners(
      Offset.zero & size,
      topRight: const Radius.circular(8),
      bottomRight: const Radius.circular(8),
    );
    canvas.drawRRect(
      r,
      PaperTextures.instance.paint(PaperTextures.cream) ??
          (Paint()..color = AppColors.giftPaper),
    );
    final edge = Paint()
      ..color = AppColors.giftEdge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(r, edge);
    // Fine lines along the fore-edge, like stacked pages.
    for (var i = 1; i <= 3; i++) {
      final x = size.width - i * 2.2;
      canvas.drawLine(Offset(x, 6), Offset(x, size.height - 6), edge);
    }
  }

  @override
  bool shouldRepaint(_PageBlockPainter old) => false;
}

/// The book inside a gift. Tapping opens the cover (it swings around the
/// spine), then the reader takes over; coming back closes it again.
class BookGift extends StatefulWidget {
  const BookGift({
    super.key,
    required this.title,
    required this.pages,
    this.dedication,
    this.author,
  });

  final String title;
  final String? dedication;
  final String? author;
  final List<BookPage> pages;

  @override
  State<BookGift> createState() => _BookGiftState();
}

class _BookGiftState extends State<BookGift>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    if (_c.isAnimating) return;
    if (!Motion.reduced(context)) {
      await _c.forward(from: 0);
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      Motion.route<void>(
        context,
        BookReaderScreen(
          title: widget.title,
          dedication: widget.dedication,
          author: widget.author,
          pages: widget.pages,
        ),
      ),
    );
    if (mounted) await _c.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.pages.length;
    return Column(
      children: [
        Text(
          'A book  ·  $n ${n == 1 ? 'page' : 'pages'}',
          style: AppTypography.eyebrow,
        ),
        const SizedBox(height: AppSpacing.md),
        GestureDetector(
          onTap: _open,
          child: Pressable(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final t = Curves.easeInOutCubic.transform(_c.value);
                return Stack(
                  children: [
                    // The title page waits underneath the cover.
                    Positioned(
                      left: 0,
                      top: 0,
                      child: _MiniTitlePage(
                        title: widget.title,
                        width: 200,
                        visible: t > 0.02,
                      ),
                    ),
                    Transform(
                      alignment: Alignment.centerLeft,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0014)
                        ..rotateY(-t * math.pi * 0.55),
                      child: Opacity(
                        opacity: (1 - (t - 0.75).clamp(0.0, 1.0) * 4).clamp(
                          0.0,
                          1.0,
                        ),
                        child: BookCoverArt(
                          title: widget.title,
                          author: widget.author,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: _open,
          icon: const Icon(Icons.menu_book_outlined, size: 20),
          label: const Text('Open the Book'),
        ),
      ],
    );
  }
}

class _MiniTitlePage extends StatelessWidget {
  const _MiniTitlePage({
    required this.title,
    required this.width,
    required this.visible,
  });

  final String title;
  final double width;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Container(
      width: width,
      height: width * 1.32,
      decoration: BoxDecoration(
        color: AppColors.giftPaper,
        image: _bookPaper,
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
        border: Border.all(color: AppColors.giftEdge),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: AppTypography.heading,
      ),
    );
  }
}

/// Full-screen book. Drag sideways or tap the edges to turn a page; the page
/// swings around the spine. Starts on a title page and ends on "The end".
class BookReaderScreen extends StatefulWidget {
  const BookReaderScreen({
    super.key,
    required this.title,
    required this.pages,
    this.dedication,
    this.author,
  });

  final String title;
  final String? dedication;
  final String? author;
  final List<BookPage> pages;

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  int _index = 0;
  int _dir = 0; // 1 turning forward, -1 turning back, 0 still
  double _width = 1;

  int get _count => widget.pages.length + 2; // title page + pages + end

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  bool _can(int dir) => dir > 0 ? _index < _count - 1 : _index > 0;

  Future<void> _go(int dir) async {
    if (_turn.isAnimating || !_can(dir)) return;
    if (Motion.reduced(context)) {
      setState(() => _index += dir);
      return;
    }
    setState(() => _dir = dir);
    await _turn.forward(from: _turn.value);
    _finish();
  }

  void _finish() {
    setState(() {
      _index += _dir;
      _dir = 0;
    });
    _turn.value = 0;
  }

  void _dragUpdate(DragUpdateDetails d) {
    if (_turn.isAnimating) return;
    final dx = d.primaryDelta ?? 0;
    if (_dir == 0) {
      final dir = dx < 0 ? 1 : -1;
      if (!_can(dir)) return;
      setState(() => _dir = dir);
    }
    _turn.value = (_turn.value - dx / _width * _dir).clamp(0.0, 1.0);
  }

  Future<void> _dragEnd(DragEndDetails d) async {
    if (_dir == 0) return;
    final v = (d.primaryVelocity ?? 0) * -_dir;
    if (_turn.value > 0.35 || v > 600) {
      await _turn.forward();
      _finish();
    } else {
      await _turn.reverse();
      setState(() => _dir = 0);
    }
  }

  Widget _page(int i) {
    final Widget content;
    if (i == 0) {
      content = _TitlePage(
        title: widget.title,
        dedication: widget.dedication,
        author: widget.author,
      );
    } else if (i == _count - 1) {
      content = _EndPage(author: widget.author);
    } else {
      final p = widget.pages[i - 1];
      content = _ContentPage(page: p, number: i);
    }
    return _Paper(child: content);
  }

  /// The turning page rotates about the spine (left edge) and disappears
  /// edge-on at 90 degrees, revealing the page beneath.
  Widget _turning(Widget page, double t) {
    return Transform(
      alignment: Alignment.centerLeft,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0012)
        ..rotateY(-t * math.pi / 2),
      child: page,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xs,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: LayoutBuilder(
                  builder: (context, box) {
                    _width = box.maxWidth;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragUpdate: _dragUpdate,
                      onHorizontalDragEnd: _dragEnd,
                      onTapUp: (d) {
                        final x = d.localPosition.dx / box.maxWidth;
                        if (x > 0.7) _go(1);
                        if (x < 0.3) _go(-1);
                      },
                      child: AnimatedBuilder(
                        animation: _turn,
                        builder: (context, _) {
                          final t = Curves.easeInOut.transform(_turn.value);
                          if (_dir > 0) {
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                _page(_index + 1),
                                _turning(_page(_index), t),
                              ],
                            );
                          }
                          if (_dir < 0) {
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                _page(_index),
                                _turning(_page(_index - 1), 1 - t),
                              ],
                            );
                          }
                          return _page(_index);
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _can(-1) ? () => _go(-1) : null,
                    tooltip: 'Previous page',
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${_index + 1} of $_count',
                          style: AppTypography.caption,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: (_index + 1) / _count,
                            minHeight: 3,
                            backgroundColor: AppColors.hairline,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _can(1) ? () => _go(1) : null,
                    tooltip: 'Next page',
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A sheet of book paper: square at the spine, rounded at the fore-edge, with
/// a faint spine line.
class _Paper extends StatelessWidget {
  const _Paper({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.giftPaper,
        image: _bookPaper,
        borderRadius: const BorderRadius.horizontal(
          left: Radius.circular(3),
          right: Radius.circular(14),
        ),
        border: Border.all(color: AppColors.giftEdge),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: 6, color: AppColors.envelopeShade),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _TitlePage extends StatelessWidget {
  const _TitlePage({required this.title, this.dedication, this.author});

  final String title;
  final String? dedication;
  final String? author;

  @override
  Widget build(BuildContext context) {
    final by = author?.trim() ?? '';
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: math.max(0, box.maxHeight - AppSpacing.xl * 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const LeafSeal(size: 48),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                style: AppTypography.displaySmall,
                textAlign: TextAlign.center,
              ),
              if (by.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text('by $by', style: AppTypography.eyebrow),
              ],
              if ((dedication ?? '').isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  dedication!,
                  textAlign: TextAlign.center,
                  style: AppTypography.eyebrow.copyWith(
                    fontSize: 24,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Swipe or tap the right edge to turn the page',
                style: AppTypography.caption,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContentPage extends StatelessWidget {
  const _ContentPage({required this.page, required this.number});

  final BookPage page;
  final int number;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (page.title.isNotEmpty) ...[
                  Text(page.title, style: AppTypography.title),
                  const SizedBox(height: AppSpacing.md),
                ],
                Paragraphs(text: page.body, initial: page.title.isNotEmpty),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text('$number', style: AppTypography.eyebrow),
        ),
      ],
    );
  }
}

class _EndPage extends StatelessWidget {
  const _EndPage({this.author});

  final String? author;

  @override
  Widget build(BuildContext context) {
    final by = author?.trim() ?? '';
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Mascot(size: 120, pose: MascotPose.hugging),
            const SizedBox(height: AppSpacing.md),
            Text(
              'The end',
              style: AppTypography.eyebrow.copyWith(fontSize: 32),
            ),
            if (by.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Written for you by $by',
                style: AppTypography.body,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
