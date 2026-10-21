import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/surprises.dart';
import '../../shared/widgets/eager_pan.dart';
import '../../shared/widgets/motion.dart';

/// Soft paper colours for the notes in a jar (and their fields in the editor).
const List<Color> jarNoteColors = [
  Color(0xFFF6E7BC), // butter
  Color(0xFFF4D8CC), // peach
  Color(0xFFDCE7D0), // mint
  Color(0xFFDDE4EE), // sky
  Color(0xFFEADFEA), // lilac
];

const _gold = Color(0xFFC9A646);
const _goldLight = Color(0xFFDDC271);
const _goldDark = Color(0xFF9C7F2C);

TextStyle _hand(double size, {Color color = AppColors.ink}) => TextStyle(
  fontFamily: AppTypography.tag,
  fontSize: size,
  height: 1.2,
  fontVariations: const [FontVariation('wght', 600)],
  color: color,
);

/// A little ticket with a secret under gold foil. Scratch it off with a
/// finger, or tap the button under it.
class ScratchCard extends StatefulWidget {
  const ScratchCard({super.key, required this.content});

  final ScratchContent content;

  @override
  State<ScratchCard> createState() => _ScratchCardState();
}

class _ScratchCardState extends State<ScratchCard>
    with SingleTickerProviderStateMixin {
  static const double _brush = 34;
  static const int _cols = 20;
  static const int _rows = 8;

  /// How much has to be scratched before the rest falls away by itself.
  static const double _enough = 0.55;

  final List<List<Offset>> _strokes = [];
  final Set<int> _cells = {};
  bool _revealed = false;
  late final AnimationController _fall = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void dispose() {
    _fall.dispose();
    super.dispose();
  }

  void _mark(Offset p, Size size) {
    final cw = size.width / _cols;
    final ch = size.height / _rows;
    const r = _brush / 2;
    for (var row = 0; row < _rows; row++) {
      for (var col = 0; col < _cols; col++) {
        final c = Offset((col + 0.5) * cw, (row + 0.5) * ch);
        if ((c - p).distance <= r) _cells.add(row * _cols + col);
      }
    }
  }

  void _start(Offset p, Size size) {
    if (_revealed) return;
    setState(() => _strokes.add([p]));
    _mark(p, size);
  }

  void _move(Offset p, Size size) {
    if (_revealed || _strokes.isEmpty) return;
    final last = _strokes.last.last;
    // Fill in the gaps of a quick swipe so coverage matches what's drawn.
    final steps = ((p - last).distance / 8).ceil().clamp(1, 40);
    for (var i = 1; i <= steps; i++) {
      _mark(Offset.lerp(last, p, i / steps)!, size);
    }
    // A cap on stored points keeps a very long scribble cheap to paint.
    if (_strokes.length < 200 && _strokes.last.length < 600) {
      _strokes.last.add(p);
    }
    setState(() {});
    if (_cells.length >= _cols * _rows * _enough) _reveal();
  }

  void _reveal() {
    if (_revealed) return;
    HapticFeedback.mediumImpact();
    setState(() => _revealed = true);
    if (Motion.reduced(context)) {
      _fall.value = 1;
    } else {
      _fall.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.content;
    final secret = c.secret.isEmpty ? 'A little secret' : c.secret;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (c.title.isNotEmpty) ...[
          Text(
            c.title,
            style: AppTypography.heading,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        ClipPath(
          clipper: const _TicketClipper(),
          child: Container(
            color: AppColors.giftPaper,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: CustomPaint(
              foregroundPainter: const _TicketEdgePainter(),
              child: Stack(
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 120),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.lg,
                        ),
                        child: ExcludeSemantics(
                          excluding: !_revealed,
                          child: Text(
                            secret,
                            textAlign: TextAlign.center,
                            style: _hand(28),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _fall,
                      builder: (context, _) {
                        if (_fall.value >= 1) return const SizedBox.shrink();
                        return LayoutBuilder(
                          builder: (context, box) {
                            final size = box.biggest;
                            return Semantics(
                              button: true,
                              label:
                                  'Hidden under gold foil. Double tap to '
                                  'reveal it.',
                              onTap: _reveal,
                              child: RawGestureDetector(
                                behavior: HitTestBehavior.opaque,
                                gestures: {
                                  EagerPan:
                                      GestureRecognizerFactoryWithHandlers<
                                        EagerPan
                                      >(EagerPan.new, (g) {
                                        g.onDown = (d) =>
                                            _start(d.localPosition, size);
                                        g.onUpdate = (d) =>
                                            _move(d.localPosition, size);
                                      }),
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: CustomPaint(
                                    size: size,
                                    painter: _FoilPainter(
                                      strokes: _strokes,
                                      version:
                                          _cells.length +
                                          _strokes.fold(
                                            0,
                                            (n, s) => n + s.length,
                                          ),
                                      hint: c.hint.isEmpty
                                          ? 'Scratch here'
                                          : c.hint,
                                      fall: _fall.value,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Center(
          child: AnimatedSwitcher(
            duration: Motion.of(context, Motion.medium),
            child: _revealed
                ? Padding(
                    key: const ValueKey('found'),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: Text(
                      'You found it.',
                      style: _hand(22, color: AppColors.sage),
                    ),
                  )
                : TextButton(
                    key: const ValueKey('tap'),
                    onPressed: _reveal,
                    child: const Text('Can’t Scratch? Tap to Reveal'),
                  ),
          ),
        ),
      ],
    );
  }
}

/// A ticket: rounded corners and a half-circle bite out of each side.
class _TicketClipper extends CustomClipper<Path> {
  const _TicketClipper();

  @override
  Path getClip(Size size) {
    const notch = 10.0;
    final card = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(14)),
      );
    final bites = Path()
      ..addOval(
        Rect.fromCircle(center: Offset(0, size.height / 2), radius: notch),
      )
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width, size.height / 2),
          radius: notch,
        ),
      );
    return Path.combine(PathOperation.difference, card, bites);
  }

  @override
  bool shouldReclip(_TicketClipper oldClipper) => false;
}

/// A dashed line around the foil window, like a printed ticket.
class _TicketEdgePainter extends CustomPainter {
  const _TicketEdgePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.giftEdge
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final r = RRect.fromRectAndRadius(
      (Offset.zero & size).inflate(5),
      const Radius.circular(13),
    );
    for (final m in (Path()..addRRect(r)).computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 9) {
        canvas.drawPath(m.extractPath(d, d + 4.5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_TicketEdgePainter oldDelegate) => false;
}

class _FoilPainter extends CustomPainter {
  _FoilPainter({
    required this.strokes,
    required this.version,
    required this.hint,
    required this.fall,
  });

  final List<List<Offset>> strokes;

  /// Changes whenever [strokes] grows, since the list itself is reused.
  final int version;
  final String hint;

  /// 0 while scratching, then up to 1 as the last of the foil falls away.
  final double fall;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final fade = (1 - fall * 1.6).clamp(0.0, 1.0);
    canvas.saveLayer(rect, Paint()..color = Color.fromRGBO(0, 0, 0, fade));
    canvas.drawRect(rect, Paint()..color = _gold);

    // Fine diagonal grain and speckles, the same every time.
    final grain = Paint()
      ..color = _goldLight
      ..strokeWidth = 1;
    for (var x = -size.height; x < size.width; x += 7) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        grain,
      );
    }
    final rnd = math.Random(7);
    final speck = Paint();
    for (var i = 0; i < (size.width * size.height / 180).clamp(20, 400); i++) {
      speck.color = rnd.nextBool() ? _goldDark : const Color(0xFFF1DE9C);
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
        rnd.nextDouble() * 1.2 + 0.4,
        speck,
      );
    }

    // The words printed on the foil, with a small star either side.
    final tp = TextPainter(
      text: TextSpan(
        text: hint,
        style: _hand(24, color: _goldDark),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: math.max(0, size.width - 80));
    final at = Offset(
      (size.width - tp.width) / 2,
      (size.height - tp.height) / 2,
    );
    tp.paint(canvas, at);
    final star = Paint()..color = _goldDark;
    _star(canvas, Offset(at.dx - 18, size.height / 2), 6, star);
    _star(canvas, Offset(at.dx + tp.width + 18, size.height / 2), 6, star);
    tp.dispose();

    // Where a finger has been, the foil is gone.
    final erase = Paint()
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.stroke
      ..strokeWidth = _ScratchCardState._brush
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final s in strokes) {
      if (s.length == 1) {
        canvas.drawCircle(
          s.first,
          _ScratchCardState._brush / 2,
          Paint()..blendMode = BlendMode.clear,
        );
      } else {
        final path = Path()..moveTo(s.first.dx, s.first.dy);
        for (final p in s.skip(1)) {
          path.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(path, erase);
      }
    }
    canvas.restore();

    // Gold flecks tumbling off as it goes.
    if (fall > 0) {
      final f = math.Random(11);
      final fleck = Paint();
      for (var i = 0; i < 26; i++) {
        final x = f.nextDouble() * size.width;
        final y0 = f.nextDouble() * size.height * 0.6;
        final speed = 0.6 + f.nextDouble() * 0.8;
        final y = y0 + fall * size.height * speed;
        final a = (1 - fall).clamp(0.0, 1.0);
        fleck.color = (i.isEven ? _gold : _goldLight).withValues(alpha: a);
        canvas.save();
        canvas.translate(x + math.sin(fall * 6 + i) * 6, y);
        canvas.rotate(fall * (3 + i % 4));
        canvas.drawRect(const Rect.fromLTWH(-3, -2, 6, 4), fleck);
        canvas.restore();
      }
    }
  }

  void _star(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final rr = i.isEven ? r : r * 0.35;
      final a = -math.pi / 2 + i * math.pi / 4;
      final p = c + Offset(math.cos(a) * rr, math.sin(a) * rr);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path..close(), paint);
  }

  @override
  bool shouldRepaint(_FoilPainter old) =>
      old.version != version || old.fall != fall || old.hint != hint;
}

/// A glass jar of folded notes. Tap it and one tumbles out and opens.
class NoteJarView extends StatefulWidget {
  const NoteJarView({super.key, required this.jar, this.seed});

  final NoteJar jar;

  /// Fixes the order notes come out in (for tests). Random otherwise.
  final int? seed;

  @override
  State<NoteJarView> createState() => _NoteJarViewState();
}

class _NoteJarViewState extends State<NoteJarView>
    with TickerProviderStateMixin {
  late List<int> _order = _shuffled();
  int _taken = 0;
  int? _current;

  late final AnimationController _wiggle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final AnimationController _tumble = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 760),
  );

  List<int> _shuffled() {
    final r = widget.seed == null ? math.Random() : math.Random(widget.seed);
    return List.generate(widget.jar.notes.length, (i) => i)..shuffle(r);
  }

  @override
  void dispose() {
    _wiggle.dispose();
    _tumble.dispose();
    super.dispose();
  }

  int get _total => widget.jar.notes.length;
  int get _left => _total - _taken;

  void _take() {
    if (_left <= 0) return;
    HapticFeedback.selectionClick();
    setState(() {
      _current = _order[_taken];
      _taken++;
    });
    if (Motion.reduced(context)) {
      _tumble.value = 1;
    } else {
      _wiggle.forward(from: 0);
      _tumble.forward(from: 0);
    }
  }

  void _again() {
    HapticFeedback.lightImpact();
    setState(() {
      _order = _shuffled();
      _taken = 0;
      _current = null;
    });
    _tumble.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    final jar = widget.jar;
    if (_total == 0) return const SizedBox.shrink();
    final done = _left == 0;
    return Column(
      children: [
        Semantics(
          button: !done,
          label: done
              ? 'An empty jar. You’ve read every note.'
              : 'A jar with $_left '
                    '${_left == 1 ? 'note' : 'notes'} left. Tap to take one.',
          excludeSemantics: true,
          onTap: done ? null : _take,
          child: GestureDetector(
            onTap: _take,
            child: AnimatedBuilder(
              animation: _wiggle,
              builder: (context, child) {
                final t = _wiggle.value;
                final a = math.sin(t * math.pi * 4) * 0.07 * (1 - t);
                return Transform.rotate(
                  angle: a,
                  alignment: Alignment.bottomCenter,
                  child: child,
                );
              },
              child: SizedBox(
                width: 200,
                height: 236,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _JarPainter(left: _left, total: _total),
                      ),
                    ),
                    Positioned(
                      left: 42,
                      right: 42,
                      top: 104,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.giftPaper,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.giftEdge),
                        ),
                        child: Text(
                          jar.title.isEmpty ? 'Little notes' : jar.title,
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: _hand(18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_current != null)
          AnimatedBuilder(
            animation: _tumble,
            builder: (context, child) {
              final t = _tumble.value;
              // First it drops out of the jar, spinning, then it unfolds.
              final drop = Curves.easeOutBack.transform(
                (t / 0.55).clamp(0.0, 1.0),
              );
              final open = Curves.easeOutCubic.transform(
                ((t - 0.45) / 0.55).clamp(0.0, 1.0),
              );
              final tilt = (_taken.isEven ? 1 : -1) * 0.025;
              return Opacity(
                opacity: (t * 4).clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, -70 * (1 - drop)),
                  child: Transform.rotate(
                    angle: tilt + (1 - drop) * 0.9,
                    child: Transform.scale(
                      scaleX: 0.45 + 0.55 * drop,
                      scaleY: 0.18 + 0.82 * open,
                      child: child,
                    ),
                  ),
                ),
              );
            },
            child: _FoldedNote(
              key: ValueKey(_taken),
              text: jar.notes[_current!],
              color: jarNoteColors[_current! % jarNoteColors.length],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text(
              'Tap the jar to take a note.',
              style: _hand(22, color: AppColors.inkSoft),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          done ? 'You’ve read them all' : '$_taken of $_total read',
          style: AppTypography.caption,
        ),
        const SizedBox(height: AppSpacing.xxs),
        if (done)
          TextButton(onPressed: _again, child: const Text('Put Them Back'))
        else if (_current != null)
          TextButton(onPressed: _take, child: const Text('Take Another')),
      ],
    );
  }
}

class _FoldedNote extends StatelessWidget {
  const _FoldedNote({super.key, required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final edge = Color.lerp(color, AppColors.ink, 0.12)!;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320, minHeight: 96),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: edge),
        ),
        child: CustomPaint(
          // The crease from where it was folded.
          painter: _CreasePainter(edge),
          child: Center(
            child: Text(text, textAlign: TextAlign.center, style: _hand(26)),
          ),
        ),
      ),
    );
  }
}

class _CreasePainter extends CustomPainter {
  _CreasePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    final y = size.height / 2;
    for (
      var x = -AppSpacing.lg + 4;
      x < size.width + AppSpacing.lg - 4;
      x += 6
    ) {
      canvas.drawLine(Offset(x, y), Offset(x + 3, y), p);
    }
  }

  @override
  bool shouldRepaint(_CreasePainter old) => old.color != color;
}

/// The jar itself: kraft lid tied with twine, a glass body with a shine,
/// and the notes still inside piled up from the bottom.
class _JarPainter extends CustomPainter {
  _JarPainter({required this.left, required this.total});

  final int left;
  final int total;

  static const _glassEdge = Color(0xFFA9B5A0);
  static const _glass = Color(0x29C8D4B5);
  static const _lid = Color(0xFFC9A77C);
  static const _lidDark = Color(0xFFA7845A);
  static const _twine = Color(0xFF8C6A45);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final body = RRect.fromRectAndCorners(
      Rect.fromLTRB(14, 52, w - 14, h - 4),
      topLeft: const Radius.circular(34),
      topRight: const Radius.circular(34),
      bottomLeft: const Radius.circular(26),
      bottomRight: const Radius.circular(26),
    );
    final neck = Rect.fromLTRB(46, 30, w - 46, 60);

    // The glass.
    canvas.drawRect(neck, Paint()..color = _glass);
    canvas.drawRRect(body, Paint()..color = _glass);

    // The notes left inside.
    canvas.save();
    canvas.clipRRect(body.deflate(5));
    final shown = math.min(left, 30);
    final rnd = math.Random(3);
    const perRow = 5;
    final inner = body.outerRect.deflate(10);
    final step = inner.width / perRow;
    for (var i = 0; i < 30; i++) {
      final row = i ~/ perRow;
      final col = i % perRow;
      final jx = rnd.nextDouble() * 10 - 5;
      final jy = rnd.nextDouble() * 6 - 3;
      final angle = rnd.nextDouble() * 1.2 - 0.6;
      if (i >= shown) continue;
      final c = Offset(
        inner.left + step * (col + 0.5) + (row.isOdd ? step / 2 - 6 : 0) + jx,
        inner.bottom - 12 - row * 15 + jy,
      );
      _note(canvas, c, angle, jarNoteColors[(i * 3) % jarNoteColors.length]);
    }
    canvas.restore();

    final edge = Paint()
      ..color = _glassEdge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(body, edge);
    canvas.drawLine(neck.topLeft, neck.bottomLeft + const Offset(0, -6), edge);
    canvas.drawLine(
      neck.topRight,
      neck.bottomRight + const Offset(0, -6),
      edge,
    );

    // A shine down the left side.
    final shine = Paint()
      ..color = const Color(0xB3FFFFFF)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(30, 92), Offset(30, h - 46), shine);
    canvas.drawLine(Offset(30, h - 34), Offset(30, h - 30), shine);

    // Kraft lid with a twine tie and a little bow.
    final lid = RRect.fromRectAndRadius(
      Rect.fromLTRB(38, 10, w - 38, 34),
      const Radius.circular(6),
    );
    canvas.drawRRect(lid, Paint()..color = _lid);
    final ridge = Paint()
      ..color = _lidDark
      ..strokeWidth = 1.2;
    for (var x = lid.left + 8; x < lid.right - 4; x += 8) {
      canvas.drawLine(Offset(x, lid.top + 3), Offset(x, lid.bottom - 3), ridge);
    }
    final twine = Paint()
      ..color = _twine
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(42, 38), Offset(w - 42, 38), twine);
    canvas.drawLine(Offset(42, 42), Offset(w - 42, 42), twine);
    final knot = Offset(w / 2 + 22, 40);
    canvas.drawOval(
      Rect.fromCenter(
        center: knot + const Offset(-8, -3),
        width: 14,
        height: 9,
      ),
      twine,
    );
    canvas.drawOval(
      Rect.fromCenter(center: knot + const Offset(8, -3), width: 14, height: 9),
      twine,
    );
    canvas.drawLine(knot, knot + const Offset(-6, 12), twine);
    canvas.drawLine(knot, knot + const Offset(7, 11), twine);
  }

  void _note(Canvas canvas, Offset c, double angle, Color color) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);
    final r = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 28, height: 16),
      const Radius.circular(2),
    );
    canvas.drawRRect(r, Paint()..color = color);
    final fold = Paint()
      ..color = Color.lerp(color, AppColors.ink, 0.18)!
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(r, fold);
    canvas.drawLine(const Offset(0, -8), const Offset(0, 8), fold);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_JarPainter old) => old.left != left || old.total != total;
}
