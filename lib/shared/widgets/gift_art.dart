import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/keepsake_style.dart';
import 'postmark.dart';
import 'stickers.dart';

/// Hand-drawn pieces that make an opened keepsake feel like a gift: an
/// envelope with a leaf seal, letter paper with a folded corner, washi tape,
/// and small leaves. All flat vector shapes (no gradients, no shadows) in the
/// brand's paper and sage tones.

/// The brand leaf as a path inside [rect]: pointed tip top-right, stem
/// bottom-left, matching the leaf on the wordmark and the mascot.
Path leafPath(Rect rect) {
  final w = rect.width, h = rect.height;
  Offset p(double x, double y) => Offset(rect.left + x * w, rect.top + y * h);
  final a = p(0.08, 0.92), b = p(0.95, 0.06);
  return Path()
    ..moveTo(a.dx, a.dy)
    ..quadraticBezierTo(p(-0.02, 0.22).dx, p(-0.02, 0.22).dy, b.dx, b.dy)
    ..quadraticBezierTo(p(1.02, 0.80).dx, p(1.02, 0.80).dy, a.dx, a.dy)
    ..close();
}

/// A small leaf, filled, with a midrib.
class Leaf extends StatelessWidget {
  const Leaf({
    super.key,
    this.size = 18,
    this.color = AppColors.sage,
    this.angle = 0,
  });

  final double size;
  final Color color;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: CustomPaint(size: Size.square(size), painter: _LeafPainter(color)),
    );
  }
}

class _LeafPainter extends CustomPainter {
  _LeafPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    canvas.drawPath(leafPath(r), Paint()..color = color);
    canvas.drawLine(
      Offset(size.width * 0.16, size.height * 0.84),
      Offset(size.width * 0.70, size.height * 0.30),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..strokeWidth = math.max(1, size.width * 0.06)
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_LeafPainter old) => old.color != color;
}

/// The wax seal: an evergreen disc with a white leaf, or the sender's
/// initials pressed in. Closes every envelope.
class LeafSeal extends StatelessWidget {
  const LeafSeal({
    super.key,
    this.size = 40,
    this.color = AppColors.accent,
    this.mono,
  });

  final double size;
  final Color color;

  /// Letters pressed into the wax instead of the leaf.
  final String? mono;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _SealPainter(color, mono),
    );
  }
}

class _SealPainter extends CustomPainter {
  _SealPainter(this.color, this.mono);
  final Color color;
  final String? mono;

  @override
  void paint(Canvas canvas, Size size) => paintSeal(
    canvas,
    size.center(Offset.zero),
    size.shortestSide / 2,
    color: color,
    mono: mono,
  );

  @override
  bool shouldRepaint(_SealPainter old) =>
      old.color != color || old.mono != mono;
}

/// Draws the seal centered at [c] with radius [r]. A slightly wavy rim reads
/// as pressed wax without any shading.
void paintSeal(
  Canvas canvas,
  Offset c,
  double r, {
  double opacity = 1,
  Color color = AppColors.accent,
  String? mono,
}) {
  if (opacity <= 0) return;
  final rim = Path();
  const bumps = 14;
  for (var i = 0; i <= bumps * 4; i++) {
    final t = i / (bumps * 4) * math.pi * 2;
    final rr = r * (1 + 0.045 * math.sin(t * bumps));
    final o = c + Offset(math.cos(t) * rr, math.sin(t) * rr);
    i == 0 ? rim.moveTo(o.dx, o.dy) : rim.lineTo(o.dx, o.dy);
  }
  rim.close();
  canvas.drawPath(rim, Paint()..color = color.withValues(alpha: opacity));
  canvas.drawCircle(
    c,
    r * 0.74,
    Paint()
      ..color = Colors.white.withValues(alpha: 0.28 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, r * 0.06),
  );
  if (mono != null && mono.isNotEmpty) {
    // Letters pressed into the wax: a darker groove under a pale face.
    TextPainter letters(Color ink) => TextPainter(
      text: TextSpan(
        text: mono,
        style: TextStyle(
          fontFamily: 'Playfair',
          fontWeight: FontWeight.w700,
          fontSize: r * (mono.length == 1 ? 1.05 : 0.74),
          height: 1,
          color: ink,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final groove = letters(
      Color.lerp(color, Colors.black, 0.35)!.withValues(alpha: opacity),
    );
    final face = letters(Colors.white.withValues(alpha: 0.93 * opacity));
    final at = c - Offset(face.width / 2, face.height / 2);
    groove.paint(canvas, at.translate(0, r * 0.05));
    face.paint(canvas, at);
    groove.dispose();
    face.dispose();
    return;
  }
  final leafRect = Rect.fromCenter(
    center: c,
    width: r * 0.95,
    height: r * 0.95,
  );
  canvas.drawPath(
    leafPath(leafRect),
    Paint()..color = Colors.white.withValues(alpha: 0.95 * opacity),
  );
}

/// An envelope that can open. [open] runs 0 (sealed) to 1 (flap fully up),
/// [rise] lifts the letter out of the pocket (0 to 1).
class EnvelopeArt extends StatelessWidget {
  const EnvelopeArt({
    super.key,
    this.width = 260,
    this.open = 0,
    this.rise = 0,
    this.showSeal = true,
    this.paper = LetterPaper.cream,
    this.sealColor = AppColors.accent,
    this.sealMono,
    this.stickers = const [],
    this.postmark,
  });

  final double width;
  final double open;
  final double rise;
  final bool showSeal;

  /// Stuck on the front; they peel away as the envelope opens.
  final List<PlacedSticker> stickers;

  /// Initials on the seal instead of the leaf.
  final String? sealMono;

  /// The day it was sent, inked over the top corner like real mail.
  final DateTime? postmark;

  /// The envelope's paper (cream, kraft, seed, linen).
  final LetterPaper paper;
  final Color sealColor;

  static const double aspect = 0.66; // height / width

  /// Total box height as a multiple of the envelope height: room above for
  /// the opened flap and the rising letter.
  static const double headroom = 1.62;

  @override
  Widget build(BuildContext context) {
    final h = width * aspect;
    final art = CustomPaint(
      painter: _EnvelopePainter(
        open: open,
        rise: rise,
        seal: showSeal,
        paper: paper,
        sealColor: sealColor,
        sealMono: sealMono,
      ),
    );
    // Extra headroom above so the opened flap and the rising letter fit.
    return SizedBox(
      width: width,
      height: h * EnvelopeArt.headroom,
      child: stickers.isEmpty && postmark == null
          ? art
          : Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(child: art),
                Positioned.fill(
                  child: Opacity(
                    opacity: (1 - open * 2.5).clamp(0.0, 1.0),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        EnvelopeStickers(
                          stickers: stickers,
                          width: width,
                          top: h * (EnvelopeArt.headroom - 1),
                        ),
                        if (postmark != null)
                          Positioned(
                            right: width * 0.16,
                            top: h * (EnvelopeArt.headroom - 1) + h * 0.06,
                            child: Postmark(date: postmark!, size: width * 0.2),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _EnvelopePainter extends CustomPainter {
  _EnvelopePainter({
    required this.open,
    required this.rise,
    required this.seal,
    required this.paper,
    required this.sealColor,
    this.sealMono,
  }) : super(repaint: PaperTextures.instance);

  final double open;
  final double rise;
  final bool seal;
  final LetterPaper paper;
  final Color sealColor;
  final String? sealMono;

  /// Cream envelopes are the cream texture tinted to the envelope tones;
  /// other papers use their own texture, a shade darker on the inside.
  Paint _paper(Color c, {bool inside = false}) {
    if (paper == LetterPaper.cream || paper == LetterPaper.dotted) {
      return PaperTextures.instance.paint(PaperTextures.cream, tint: c) ??
          (Paint()..color = c);
    }
    return PaperTextures.instance.paint(
          paper.texture,
          tint: inside ? const Color(0xFFE4DED2) : null,
        ) ??
        (Paint()..color = paper.color);
  }

  /// The letter inside is always cream.
  static Paint _letter() =>
      PaperTextures.instance.paint(PaperTextures.cream) ??
      (Paint()..color = AppColors.giftPaper);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = w * EnvelopeArt.aspect;
    final top = size.height - h; // envelope sits at the bottom of the box
    final body = Rect.fromLTWH(0, top, w, h);
    final radius = Radius.circular(w * 0.045);
    final stroke = math.max(1.0, w * 0.006);

    final edge = Paint()
      ..color = paper == LetterPaper.cream ? AppColors.giftEdge : paper.edge
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeJoin = StrokeJoin.round;

    // Back panel.
    final back = RRect.fromRectAndRadius(body, radius);
    canvas.drawRRect(back, _paper(AppColors.envelopeShade, inside: true));
    canvas.drawRRect(back, edge);

    final flapDepth = h * 0.56;
    // Flap scale about the top edge: 1 = closed (pointing down), -1 = open.
    final flapScale = math.cos(open * math.pi);

    void drawFlap() {
      final tipY = top + flapDepth * flapScale;
      final flap = Path()
        ..moveTo(0, top + w * 0.02)
        ..quadraticBezierTo(0, top, w * 0.04, top)
        ..lineTo(w * 0.96, top)
        ..quadraticBezierTo(w, top, w, top + w * 0.02)
        ..lineTo(w * 0.56, tipY - (flapScale >= 0 ? h * 0.03 : -h * 0.03))
        ..quadraticBezierTo(
          w * 0.5,
          tipY,
          w * 0.44,
          tipY - (flapScale >= 0 ? h * 0.03 : -h * 0.03),
        )
        ..close();
      canvas.drawPath(
        flap,
        _paper(
          flapScale >= 0 ? AppColors.envelope : AppColors.envelopeShade,
          inside: flapScale < 0,
        ),
      );
      canvas.drawPath(flap, edge);
    }

    // An open flap sits behind the letter.
    if (flapScale < 0) drawFlap();

    // The letter, rising out of the pocket.
    if (rise > 0 || open > 0.5) {
      final lift = h * 0.58 * Curves.easeOut.transform(rise.clamp(0.0, 1.0));
      final letter = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.08, top + h * 0.08 - lift, w * 0.84, h * 0.84),
        Radius.circular(w * 0.025),
      );
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, w, top + h * 0.98));
      canvas.drawRRect(letter, _letter());
      canvas.drawRRect(letter, edge);
      // A few quiet "written" lines and a tiny heart on the letter.
      final line = Paint()
        ..color = AppColors.giftEdge
        ..strokeWidth = stroke * 1.4
        ..strokeCap = StrokeCap.round;
      final lx = letter.left + w * 0.08;
      for (var i = 0; i < 3; i++) {
        final y = letter.top + h * (0.16 + i * 0.1);
        final end = letter.right - w * (i == 2 ? 0.30 : 0.08);
        canvas.drawLine(Offset(lx, y), Offset(end, y), line);
      }
      _heart(
        canvas,
        Offset(letter.right - w * 0.14, letter.top + h * 0.37),
        w * 0.035,
      );
      canvas.restore();
    }

    // Front pocket: left, right and bottom folds.
    final pocket = Path()
      ..moveTo(0, top + h * 0.06)
      ..lineTo(w * 0.5, top + h * 0.60)
      ..lineTo(w, top + h * 0.06)
      ..lineTo(w, top + h - radius.y)
      ..quadraticBezierTo(w, top + h, w - radius.x, top + h)
      ..lineTo(radius.x, top + h)
      ..quadraticBezierTo(0, top + h, 0, top + h - radius.y)
      ..close();
    canvas.drawPath(pocket, _paper(AppColors.envelope));
    // Fold lines from the bottom corners.
    final fold = Path()
      ..moveTo(w * 0.02, top + h * 0.98)
      ..lineTo(w * 0.42, top + h * 0.56)
      ..moveTo(w * 0.98, top + h * 0.98)
      ..lineTo(w * 0.58, top + h * 0.56);
    canvas.drawPath(fold, edge);
    canvas.drawPath(pocket, edge);

    // A closed flap sits on top of everything.
    if (flapScale >= 0) drawFlap();

    // Seal on the flap tip; it lifts away as the flap opens.
    if (seal) {
      final tip = Offset(w * 0.5, top + flapDepth * flapScale - h * 0.02);
      paintSeal(
        canvas,
        tip,
        h * 0.13,
        opacity: (1 - open * 2.5).clamp(0, 1),
        color: sealColor,
        mono: sealMono,
      );
    }
  }

  void _heart(Canvas canvas, Offset c, double s) {
    final p = Path()
      ..moveTo(c.dx, c.dy + s * 0.9)
      ..cubicTo(
        c.dx - s * 1.6,
        c.dy - s * 0.2,
        c.dx - s * 0.6,
        c.dy - s * 1.3,
        c.dx,
        c.dy - s * 0.4,
      )
      ..cubicTo(
        c.dx + s * 0.6,
        c.dy - s * 1.3,
        c.dx + s * 1.6,
        c.dy - s * 0.2,
        c.dx,
        c.dy + s * 0.9,
      )
      ..close();
    canvas.drawPath(p, Paint()..color = AppColors.heart);
  }

  @override
  bool shouldRepaint(_EnvelopePainter old) =>
      old.open != open ||
      old.rise != rise ||
      old.seal != seal ||
      old.paper != paper ||
      old.sealColor != sealColor ||
      old.sealMono != sealMono;
}

/// Letter paper: a warm sheet with a folded top-right corner.
/// The stationery a letter can be written on.
/// The real-looking paper textures (made by tool/make_paper_textures.py),
/// loaded once into memory so painters can tile them. Until they load,
/// surfaces fall back to their flat colour, then repaint.
class PaperTextures extends ChangeNotifier {
  PaperTextures._();

  static final PaperTextures instance = PaperTextures._();

  static const cream = 'assets/textures/paper_cream.jpg';
  static const kraft = 'assets/textures/paper_kraft.jpg';
  static const seed = 'assets/textures/paper_sage.jpg';
  static const linen = 'assets/textures/paper_linen.jpg';
  static const cloth = 'assets/textures/cloth.jpg';
  static const stone = 'assets/textures/paper_stone.jpg';

  /// Each 768 px tile covers 256 logical px: about one texture pixel per
  /// screen pixel on a 3x phone.
  static const double tileScale = 1 / 3;

  final Map<String, ui.Image> _images = {};
  Future<void>? _loading;

  ui.Image? operator [](String asset) => _images[asset];

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    // All six at once, not one after another: they no longer queue behind
    // each other while the first screen is being built.
    await Future.wait([
      for (final asset in [cream, kraft, seed, linen, cloth, stone])
        _loadOne(asset),
    ]);
  }

  Future<void> _loadOne(String asset) async {
    try {
      final data = await rootBundle.load(asset);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      _images[asset] = (await codec.getNextFrame()).image;
      // Tell the surfaces as soon as this one is ready, so paper appears as
      // it arrives instead of everything waiting for the slowest texture.
      notifyListeners();
    } catch (_) {
      // A missing texture just means the flat colour is used.
    }
  }

  /// A paint that tiles [asset], optionally tinted by multiplying [tint].
  Paint? paint(String? asset, {Color? tint}) {
    final img = asset == null ? null : _images[asset];
    if (img == null) return null;
    final p = Paint()
      ..shader = ImageShader(
        img,
        TileMode.repeated,
        TileMode.repeated,
        Matrix4.diagonal3Values(tileScale, tileScale, 1).storage,
        filterQuality: FilterQuality.medium,
      );
    if (tint != null) {
      p.colorFilter = ColorFilter.mode(tint, BlendMode.multiply);
    }
    return p;
  }
}

enum LetterPaper {
  cream(
    'cream',
    'Cream',
    PaperTextures.cream,
    AppColors.giftPaper,
    AppColors.giftEdge,
    false,
  ),
  dotted(
    'dotted',
    'Dotted',
    PaperTextures.cream,
    AppColors.giftPaper,
    AppColors.giftEdge,
    true,
  ),
  linen(
    'linen',
    'Linen',
    PaperTextures.linen,
    Color(0xFFF5EFE3),
    Color(0xFFE0D6C4),
    false,
  ),
  sage(
    'sage',
    'Seed',
    PaperTextures.seed,
    Color(0xFFE1E6D3),
    Color(0xFFC9D2B8),
    false,
    signature: AppColors.accent,
  ),
  // Darker inks so everything stays readable on brown paper.
  kraft(
    'kraft',
    'Kraft',
    PaperTextures.kraft,
    Color(0xFFC49B6C),
    Color(0xFFA9824F),
    false,
    softInk: Color(0xFF4A3420),
    faintInk: Color(0xFF6E5236),
    signature: Color(0xFF1E4634),
  );

  const LetterPaper(
    this.id,
    this.label,
    this.texture,
    this.color,
    this.edge,
    this.dots, {
    this.softInk = AppColors.inkSoft,
    this.faintInk = AppColors.inkFaint,
    this.signature = AppColors.sage,
  });

  /// Secondary text (sign-offs, counts) that reads well on this paper.
  final Color softInk;

  /// Hints and placeholders on this paper.
  final Color faintInk;

  /// The handwritten sign-off and the writer's name.
  final Color signature;

  final String id;
  final String label;
  final String texture;

  /// The paper's average colour: used until the texture loads, and where a
  /// flat fill is needed.
  final Color color;
  final Color edge;
  final bool dots;

  static LetterPaper fromId(String? id) => LetterPaper.values.firstWhere(
    (p) => p.id == id,
    orElse: () => LetterPaper.cream,
  );
}

/// How a letter is set: clean, in handwriting, or in a classic serif.
enum LetterFont {
  clean('clean', 'Clean'),
  hand('hand', 'Handwritten'),
  classic('classic', 'Classic');

  const LetterFont(this.id, this.label);

  final String id;
  final String label;

  static LetterFont fromId(String? id) => LetterFont.values.firstWhere(
    (f) => f.id == id,
    orElse: () => LetterFont.clean,
  );

  /// The reading style for the letter's body.
  TextStyle get body => switch (this) {
    LetterFont.clean => const TextStyle(
      fontFamily: 'Inter',
      fontSize: 16,
      height: 1.75,
      color: AppColors.ink,
    ),
    LetterFont.hand => const TextStyle(
      fontFamily: 'Caveat',
      fontSize: 23,
      height: 1.4,
      color: AppColors.ink,
      fontVariations: [FontVariation('wght', 500)],
    ),
    LetterFont.classic => const TextStyle(
      fontFamily: 'Playfair',
      fontSize: 17,
      height: 1.75,
      color: AppColors.ink,
    ),
  };

  /// The style for the letter's title.
  TextStyle get title => switch (this) {
    LetterFont.clean => const TextStyle(
      fontFamily: 'Montserrat',
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 1.25,
      color: AppColors.ink,
    ),
    LetterFont.hand => const TextStyle(
      fontFamily: 'Caveat',
      fontSize: 32,
      height: 1.15,
      color: AppColors.ink,
      fontVariations: [FontVariation('wght', 700)],
    ),
    LetterFont.classic => const TextStyle(
      fontFamily: 'Playfair',
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: 1.25,
      color: AppColors.ink,
    ),
  };
}

/// A soft dot grid, like a bullet-journal page.
class DotGridPainter extends CustomPainter {
  const DotGridPainter({this.color = AppColors.giftEdge, this.spacing = 20});

  final Color color;
  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    for (var y = spacing; y < size.height; y += spacing) {
      for (var x = spacing; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1.1, p);
      }
    }
  }

  @override
  bool shouldRepaint(DotGridPainter old) =>
      old.color != color || old.spacing != spacing;
}

class PaperSheet extends StatelessWidget {
  const PaperSheet({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.fold = 22,
    this.color = AppColors.giftPaper,
    this.edge = AppColors.giftEdge,
    this.dots = false,
    this.texture = PaperTextures.cream,
  });

  /// A sheet in one of the letter papers.
  factory PaperSheet.of(
    LetterPaper paper, {
    Key? key,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(AppSpacing.lg),
    double fold = 22,
  }) => PaperSheet(
    key: key,
    padding: padding,
    fold: fold,
    color: paper.color,
    edge: paper.edge,
    dots: paper.dots,
    texture: paper.texture,
    child: child,
  );

  final Widget child;
  final EdgeInsets padding;
  final double fold;
  final Color color;
  final Color edge;
  final bool dots;

  /// Texture asset (see [PaperTextures]); null for a flat colour.
  final String? texture;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PaperPainter(
        fold: fold,
        color: color,
        edge: edge,
        dots: dots,
        texture: texture,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _PaperPainter extends CustomPainter {
  _PaperPainter({
    required this.fold,
    required this.color,
    required Color edge,
    required this.dots,
    this.texture,
  }) : edgeColor = edge,
       super(repaint: PaperTextures.instance);

  final double fold;
  final Color color;
  final Color edgeColor;
  final bool dots;
  final String? texture;

  @override
  void paint(Canvas canvas, Size size) {
    const r = AppRadius.lg;
    final w = size.width, h = size.height, f = fold;
    final sheet = Path()..moveTo(r, 0);
    if (f > 0) {
      sheet
        ..lineTo(w - f, 0)
        ..lineTo(w, f);
    } else {
      sheet
        ..lineTo(w - r, 0)
        ..quadraticBezierTo(w, 0, w, r);
    }
    sheet
      ..lineTo(w, h - r)
      ..quadraticBezierTo(w, h, w - r, h)
      ..lineTo(r, h)
      ..quadraticBezierTo(0, h, 0, h - r)
      ..lineTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..close();
    final edge = Paint()
      ..color = edgeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      sheet,
      PaperTextures.instance.paint(texture) ?? (Paint()..color = color),
    );
    if (dots) {
      canvas.save();
      canvas.clipPath(sheet);
      DotGridPainter(
        color: edgeColor.withValues(alpha: 0.9),
      ).paint(canvas, size);
      canvas.restore();
    }
    canvas.drawPath(sheet, edge);
    if (f <= 0) return;
    // The folded-over corner.
    final corner = Path()
      ..moveTo(w - f, 0)
      ..lineTo(w - f, f * 0.78)
      ..quadraticBezierTo(w - f, f, w - f * 0.78, f)
      ..lineTo(w, f)
      ..close();
    canvas.drawPath(
      corner,
      Paint()..color = Color.lerp(color, edgeColor, 0.55)!,
    );
    canvas.drawPath(corner, edge);
  }

  @override
  bool shouldRepaint(_PaperPainter old) =>
      old.fold != fold ||
      old.color != color ||
      old.edgeColor != edgeColor ||
      old.dots != dots ||
      old.texture != texture;
}

/// A strip of washi tape, as if holding a photo or note in place.
class WashiTape extends StatelessWidget {
  const WashiTape({
    super.key,
    this.width = 72,
    this.height = 20,
    this.angle = -0.06,
    this.color = AppColors.sageSoft,
  });

  final double width;
  final double height;
  final double angle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: CustomPaint(
        size: Size(width, height),
        painter: _TapePainter(color),
      ),
    );
  }
}

class _TapePainter extends CustomPainter {
  _TapePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    const teeth = 5;
    final p = Path()..moveTo(0, 0);
    p.lineTo(w, 0);
    for (var i = 0; i < teeth; i++) {
      final y0 = h * i / teeth, y1 = h * (i + 0.5) / teeth;
      p.lineTo(w - (i.isEven ? 3 : 0), y0);
      p.lineTo(w - 3, y1);
    }
    p.lineTo(w, h);
    p.lineTo(0, h);
    for (var i = teeth; i > 0; i--) {
      final y0 = h * i / teeth, y1 = h * (i - 0.5) / teeth;
      p.lineTo(i.isEven ? 3 : 0, y0);
      p.lineTo(3, y1);
    }
    p.close();
    canvas.drawPath(p, Paint()..color = color.withValues(alpha: 0.85));
    // Faint stripes, like printed tape.
    final stripe = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 2;
    for (var x = 10.0; x < w - 6; x += 12) {
      canvas.drawLine(Offset(x, 2), Offset(x - 5, h - 2), stripe);
    }
  }

  @override
  bool shouldRepaint(_TapePainter old) => old.color != color;
}

/// The ink a letter is written in.
enum LetterInk {
  classic('classic', 'Classic', null),
  blueBlack('blue', 'Blue-black', Color(0xFF1F3561)),
  sepia('sepia', 'Sepia', Color(0xFF5B3A1E)),
  evergreen('green', 'Evergreen', Color(0xFF22513A));

  const LetterInk(this.id, this.label, this._color);

  final String id;
  final String label;
  final Color? _color;

  /// The writing colour on [paper]. Classic is the paper's own dark ink.
  Color on(LetterPaper paper) => _color ?? AppColors.ink;

  /// The signature colour on [paper].
  Color signatureOn(LetterPaper paper) => _color ?? paper.signature;

  static LetterInk fromId(String? id) => LetterInk.values.firstWhere(
    (i) => i.id == id,
    orElse: () => LetterInk.classic,
  );
}
