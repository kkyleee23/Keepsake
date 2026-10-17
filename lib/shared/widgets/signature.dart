import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/signature.dart';
import 'eager_pan.dart';
import 'gift_art.dart';
import 'primary_button.dart';

/// A hand-drawn signature, [width] wide.
class SignatureView extends StatelessWidget {
  const SignatureView({
    super.key,
    required this.signature,
    required this.color,
    this.width = 180,
  });

  final Signature signature;
  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Signed by hand',
      image: true,
      child: CustomPaint(
        size: Size(width, width / Signature.aspect),
        painter: _InkPainter(signature.strokes, color),
      ),
    );
  }
}

class _InkPainter extends CustomPainter {
  _InkPainter(this.strokes, this.color);

  final List<List<Offset>> strokes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = (size.height * 0.04).clamp(1.4, 4.0)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    Offset at(Offset p) => Offset(p.dx * size.width, p.dy * size.height);
    for (final s in strokes) {
      if (s.length == 1) {
        canvas.drawCircle(
          at(s.first),
          pen.strokeWidth / 2,
          Paint()..color = color,
        );
        continue;
      }
      // Smooth: curve through the midpoints between samples.
      final path = Path()..moveTo(at(s.first).dx, at(s.first).dy);
      for (var i = 1; i < s.length - 1; i++) {
        final a = at(s[i]), b = at(s[i + 1]);
        path.quadraticBezierTo(
          a.dx,
          a.dy,
          (a.dx + b.dx) / 2,
          (a.dy + b.dy) / 2,
        );
      }
      path.lineTo(at(s.last).dx, at(s.last).dy);
      canvas.drawPath(path, pen);
    }
  }

  @override
  bool shouldRepaint(_InkPainter old) => true;
}

/// Opens a pad to sign by hand on [paper] in [ink]. Returns the signature,
/// or null if they close it without one.
Future<Signature?> showSignaturePad(
  BuildContext context, {
  required LetterPaper paper,
  required Color ink,
}) {
  return showModalBottomSheet<Signature>(
    context: context,
    isScrollControlled: true,
    // Drawing would fight a drag-to-close sheet.
    enableDrag: false,
    builder: (_) => _SignaturePad(paper: paper, ink: ink),
  );
}

class _SignaturePad extends StatefulWidget {
  const _SignaturePad({required this.paper, required this.ink});

  final LetterPaper paper;
  final Color ink;

  @override
  State<_SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<_SignaturePad> {
  final _strokes = <List<Offset>>[];
  int get _points => _strokes.fold(0, (n, s) => n + s.length);
  bool get _full =>
      _strokes.length >= Signature.maxStrokes || _points >= Signature.maxPoints;

  void _start(Offset p, Size box) {
    if (_full) return;
    setState(() => _strokes.add([_norm(p, box)]));
  }

  void _move(Offset p, Size box) {
    if (_strokes.isEmpty || _points >= Signature.maxPoints) return;
    final n = _norm(p, box);
    final last = _strokes.last.last;
    // Skip points that add nothing; keeps the signature small.
    if ((n - last).distance < Signature.minStep) return;
    setState(() => _strokes.last.add(n));
  }

  Offset _norm(Offset p, Size box) => Offset(
    (p.dx / box.width).clamp(0.0, 1.0),
    (p.dy / box.height).clamp(0.0, 1.0),
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.lg,
          AppSpacing.gutter,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sign it by hand', style: AppTypography.heading),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Use your finger, like signing a card. It goes under your '
              'letter.',
              style: AppTypography.body,
            ),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, c) {
                final box = Size(c.maxWidth, c.maxWidth / Signature.aspect);
                return SizedBox.fromSize(
                  size: box,
                  child: RawGestureDetector(
                    gestures: {
                      EagerPan: GestureRecognizerFactoryWithHandlers<EagerPan>(
                        EagerPan.new,
                        (r) {
                          r.onStart = (d) => _start(d.localPosition, box);
                          r.onUpdate = (d) => _move(d.localPosition, box);
                        },
                      ),
                    },
                    child: PaperSheet.of(
                      widget.paper,
                      fold: 14,
                      padding: EdgeInsets.zero,
                      child: Stack(
                        children: [
                          // A faint line to sign on.
                          Positioned(
                            left: box.width * 0.08,
                            right: box.width * 0.08,
                            bottom: box.height * 0.24,
                            child: Container(
                              height: 1,
                              color: widget.paper.faintInk.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          if (_strokes.isEmpty)
                            Positioned(
                              left: box.width * 0.08,
                              bottom: box.height * 0.08,
                              child: Text(
                                'Sign here',
                                style: AppTypography.caption.copyWith(
                                  color: widget.paper.faintInk,
                                ),
                              ),
                            ),
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _InkPainter(_strokes, widget.ink),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            if (_full)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  'That’s as much as one signature can hold.',
                  style: AppTypography.caption,
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                TextButton(
                  onPressed: _strokes.isEmpty
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          setState(_strokes.clear);
                        },
                  child: const Text('Clear'),
                ),
                const Spacer(),
                PrimaryButton(
                  label: 'Use Signature',
                  expand: false,
                  onPressed: _strokes.isEmpty
                      ? null
                      : () => Navigator.pop(
                          context,
                          Signature([
                            for (final s in _strokes) [...s],
                          ]),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
