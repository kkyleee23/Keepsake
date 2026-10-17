import 'package:flutter/material.dart';

import '../../core/text/reading.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/gift_art.dart';
import '../../shared/widgets/motion.dart';

final _reading = AppTypography.bodyLarge.copyWith(height: 1.75);

/// Text split into the writer's paragraphs, with breathing room between them.
/// When [initial] is set, the very first letter is raised and set in the
/// heading font, like the opening of a chapter.
class Paragraphs extends StatelessWidget {
  const Paragraphs({super.key, required this.text, this.initial = false});

  final String text;
  final bool initial;

  @override
  Widget build(BuildContext context) {
    final paras = Reading.paragraphs(text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < paras.length; i++)
          Padding(
            padding: EdgeInsets.only(
              bottom: i == paras.length - 1 ? 0 : AppSpacing.md,
            ),
            child: i == 0 && initial && paras[i].length > 1
                ? Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: paras[i].characters.first,
                          style: AppTypography.title.copyWith(
                            color: AppColors.accent,
                            fontSize: 26,
                            height: 1.0,
                          ),
                        ),
                        TextSpan(text: paras[i].characters.skip(1).string),
                      ],
                    ),
                    style: _reading,
                  )
                : Text(paras[i], style: _reading),
          ),
      ],
    );
  }
}

/// A letter's body. Short letters show in full; long ones show the opening
/// with a soft fade and a "Keep reading" that unfolds the rest.
class LetterBody extends StatefulWidget {
  const LetterBody({super.key, required this.text, this.fill});

  final String text;

  /// The paper colour behind the text, for the folded edge.
  final Color? fill;

  /// Letters longer than this many words start folded.
  static const int foldAfterWords = 450;

  @override
  State<LetterBody> createState() => _LetterBodyState();
}

class _LetterBodyState extends State<LetterBody> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final long = Reading.words(widget.text) > LetterBody.foldAfterWords;
    if (!long) return Paragraphs(text: widget.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: Motion.of(context, Motion.medium),
          curve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          child: _open
              ? Paragraphs(text: widget.text)
              : SizedBox(
                  height: 320,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        // The last lines fade into the paper (an alpha mask,
                        // so any paper texture shows through).
                        child: ShaderMask(
                          blendMode: BlendMode.dstIn,
                          shaderCallback: (r) => const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [0, 0.72, 0.97],
                            colors: [
                              Color(0xFF000000),
                              Color(0xFF000000),
                              Color(0x00000000),
                            ],
                          ).createShader(r),
                          child: ClipRect(
                            child: OverflowBox(
                              alignment: Alignment.topCenter,
                              maxHeight: double.infinity,
                              child: Paragraphs(text: widget.text),
                            ),
                          ),
                        ),
                      ),
                      // A folded-paper edge says "there's more below".
                      const Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _FoldEdge(),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: TextButton.icon(
            onPressed: () => setState(() => _open = !_open),
            icon: AnimatedRotation(
              turns: _open ? 0.5 : 0,
              duration: Motion.of(context, Motion.short),
              child: const Icon(Icons.expand_more, size: 20),
            ),
            label: Text(
              _open
                  ? 'Fold It Back Up'
                  : 'Keep Reading  ·  ${Reading.minutesLabel(widget.text)}',
            ),
          ),
        ),
      ],
    );
  }
}

/// The fold in a long letter: a dashed line across the paper.
class _FoldEdge extends StatelessWidget {
  const _FoldEdge();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 2,
      child: CustomPaint(
        size: Size(double.infinity, 1),
        painter: _DashPainter(),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  const _DashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColors.giftEdge
      ..strokeWidth = 1.2;
    for (var x = 0.0; x < size.width; x += 10) {
      canvas.drawLine(Offset(x, 0), Offset(x + 5, 0), p);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => false;
}

/// An essay inside the gift: a card with its title, the opening lines and a
/// way into a full reading view.
class EssayCard extends StatelessWidget {
  const EssayCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.body,
    this.author,
  });

  final String? title;
  final String? subtitle;
  final String body;
  final String? author;

  void _read(BuildContext context) {
    Navigator.of(context).push(
      Motion.route<void>(
        context,
        texture: PaperTextures.cream,
        EssayReaderScreen(
          title: title,
          subtitle: subtitle,
          body: body,
          author: author,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final first = Reading.paragraphs(body).firstOrNull ?? '';
    return PaperSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'An essay  ·  ${Reading.minutesLabel(body)}',
            style: AppTypography.eyebrow,
          ),
          const SizedBox(height: AppSpacing.xs),
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: Text(title!, style: AppTypography.title),
            ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              subtitle!,
              style: AppTypography.bodyLarge.copyWith(color: AppColors.inkSoft),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            first,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: _reading.copyWith(color: AppColors.inkSoft),
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => _read(context),
              icon: const Icon(Icons.menu_book_outlined, size: 20),
              label: const Text('Read the Essay'),
            ),
          ),
        ],
      ),
    );
  }
}

/// A full-page reading view: paper, generous type, a thin line at the top
/// that fills as you read, and a seal at the end.
class EssayReaderScreen extends StatefulWidget {
  const EssayReaderScreen({
    super.key,
    this.title,
    this.subtitle,
    required this.body,
    this.author,
  });

  final String? title;
  final String? subtitle;
  final String body;
  final String? author;

  @override
  State<EssayReaderScreen> createState() => _EssayReaderScreenState();
}

class _EssayReaderScreenState extends State<EssayReaderScreen> {
  final _scroll = ScrollController();
  final _progress = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final max = _scroll.position.maxScrollExtent;
      _progress.value = max <= 0 ? 1 : (_scroll.offset / max).clamp(0.0, 1.0);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final author = widget.author?.trim() ?? '';
    return Scaffold(
      appBar: AppBar(
        title: Text(Reading.minutesLabel(widget.body)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: ValueListenableBuilder<double>(
            valueListenable: _progress,
            builder: (_, v, _) => Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: v,
                child: Container(height: 2, color: AppColors.accent),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.lg,
            AppSpacing.gutter,
            AppSpacing.xxxl,
          ),
          children: [
            if (widget.title != null)
              Text(widget.title!, style: AppTypography.displaySmall),
            if (widget.subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.subtitle!,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.inkSoft,
                ),
              ),
            ],
            if (author.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text('by $author', style: AppTypography.eyebrow),
            ],
            const SizedBox(height: AppSpacing.lg),
            Container(height: 1, color: AppColors.giftEdge),
            const SizedBox(height: AppSpacing.lg),
            Paragraphs(text: widget.body, initial: true),
            const SizedBox(height: AppSpacing.xxl),
            const Center(child: LeafSeal(size: 36)),
            const SizedBox(height: AppSpacing.xs),
            Center(child: Text('The end', style: AppTypography.eyebrow)),
          ],
        ),
      ),
    );
  }
}
