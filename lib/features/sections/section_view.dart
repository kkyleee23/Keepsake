import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/media/photo_codec.dart';
import '../../data/models/enums.dart';
import '../../data/models/keepsake_section.dart';
import '../../shared/widgets/brand.dart';
import '../../shared/widgets/gift_art.dart';

/// Read-only rendering of a single section, styled as part of a gift: letters
/// on paper, memories taped down, reasons on little leaves, Open When notes in
/// their own envelopes.
///
/// Used by both Preview and the recipient experience, so the creator always
/// sees exactly what will be received.
class SectionView extends StatelessWidget {
  const SectionView({super.key, required this.section, this.senderName});

  final KeepsakeSection section;

  /// Used to sign letters ("From Kyle").
  final String? senderName;

  String? _s(String key) {
    final v = (section.content[key] as String?)?.trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  @override
  Widget build(BuildContext context) {
    switch (section.type) {
      case SectionType.letter:
        return _Letter(title: _s('title'), body: _s('body'), from: senderName);
      case SectionType.memory:
        return _Memory(title: _s('title'), body: _s('body'), date: _s('date'));
      case SectionType.customMessage:
        return _Note(body: _s('body'));
      case SectionType.question:
        return _Question(prompt: _s('prompt'));
      case SectionType.reasons:
        return _Reasons(
          title: _s('title'),
          items:
              (section.content['items'] as List?)
                  ?.map((e) => e.toString().trim())
                  .where((e) => e.isNotEmpty)
                  .toList() ??
              const [],
        );
      case SectionType.openWhen:
        return _OpenWhen(
          title: _s('title'),
          items: (section.content['items'] as List?) ?? const [],
        );
      case SectionType.timeline:
        return _Timeline(
          title: _s('title'),
          entries: (section.content['entries'] as List?) ?? const [],
        );
      case SectionType.photo:
        return _Photos(
          title: _s('title'),
          photos: [
            for (final e in (section.content['photos'] as List?) ?? const [])
              Map<String, dynamic>.from(e as Map),
          ],
        );
      case SectionType.countdown:
        return _Countdown(
          label: _s('label'),
          date: DateTime.tryParse(_s('date') ?? ''),
        );
      default:
        // Unsupported-in-reader types degrade to a quiet label rather than
        // breaking the scroll.
        return Text(section.type.label, style: AppTypography.caption);
    }
  }
}

const _readingStyle = TextStyle(height: 1.7);

/// A section title with a small leaf, used above lists.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          const Leaf(size: 16, angle: -0.2),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Text(text, style: AppTypography.heading)),
        ],
      ),
    );
  }
}

/// A letter on warm paper with a folded corner, signed at the bottom.
class _Letter extends StatelessWidget {
  const _Letter({this.title, this.body, this.from});

  final String? title;
  final String? body;
  final String? from;

  @override
  Widget build(BuildContext context) {
    if (title == null && body == null) return const SizedBox.shrink();
    final sign = from?.trim() ?? '';
    return PaperSheet(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: Text(title!, style: AppTypography.title),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (body != null)
            Text(body!, style: AppTypography.bodyLarge.merge(_readingStyle)),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (sign.isNotEmpty)
                  Text(
                    'From $sign',
                    style: AppTypography.label.copyWith(color: AppColors.sage),
                  ),
                const SizedBox(width: AppSpacing.xs),
                const LeafSeal(size: 26),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A memory card held down with washi tape, slightly off-straight like it was
/// stuck in by hand.
class _Memory extends StatelessWidget {
  const _Memory({this.title, this.body, this.date});

  final String? title;
  final String? body;
  final String? date;

  @override
  Widget build(BuildContext context) {
    if (title == null && body == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Transform.rotate(
            angle: -0.012,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg + AppSpacing.xxs,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.giftEdge),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(date ?? 'A memory', style: AppTypography.eyebrow),
                  if (title != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(title!, style: AppTypography.heading),
                  ],
                  if (body != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      body!,
                      style: AppTypography.bodyLarge.merge(_readingStyle),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const Positioned(top: -10, child: WashiTape()),
        ],
      ),
    );
  }
}

/// A short message, set large and centered like the line inside a card. The
/// sprigs between sections frame it.
class _Note extends StatelessWidget {
  const _Note({this.body});

  final String? body;

  @override
  Widget build(BuildContext context) {
    if (body == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Text(
        body!,
        style: AppTypography.title.copyWith(height: 1.4),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// A question asked by the mascot, in a speech bubble.
class _Question extends StatelessWidget {
  const _Question({this.prompt});

  final String? prompt;

  @override
  Widget build(BuildContext context) {
    if (prompt == null) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Mascot(size: 96, pose: MascotPose.thinking),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.lg),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.giftPaper,
              border: Border.all(color: AppColors.giftEdge),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.xl),
                topRight: Radius.circular(AppRadius.xl),
                bottomRight: Radius.circular(AppRadius.xl),
                bottomLeft: Radius.circular(AppRadius.sm / 2),
              ),
            ),
            child: Text(
              prompt!,
              style: AppTypography.bodyLarge.merge(_readingStyle),
            ),
          ),
        ),
      ],
    );
  }
}

/// Each reason numbered on its own little leaf.
class _Reasons extends StatelessWidget {
  const _Reasons({this.title, required this.items});

  final String? title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return PaperSheet(
      fold: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) _SectionTitle(title!),
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == items.length - 1 ? 0 : AppSpacing.md,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LeafNumber(i + 1),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xxs),
                      child: Text(
                        items[i],
                        style: AppTypography.bodyLarge.merge(_readingStyle),
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

class _LeafNumber extends StatelessWidget {
  const _LeafNumber(this.n);

  final int n;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 34,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Leaf(size: 34, color: AppColors.sageSoft),
          Text(
            '$n',
            style: AppTypography.body.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _OpenWhen extends StatelessWidget {
  const _OpenWhen({this.title, required this.items});

  final String? title;
  final List<dynamic> items;

  @override
  Widget build(BuildContext context) {
    final cards = items
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((m) => (m['label'] as String?)?.trim().isNotEmpty ?? false)
        .toList();
    if (cards.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Each envelope already says "Open when", so only a custom title shows.
        if (title != null && title!.toLowerCase() != 'open when')
          _SectionTitle(title!),
        for (final m in cards)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _OpenWhenEnvelope(
              label: (m['label'] as String?)?.trim() ?? '',
              body: (m['body'] as String?)?.trim() ?? '',
            ),
          ),
      ],
    );
  }
}

/// One sealed little envelope. Tap to open it and read the note inside.
class _OpenWhenEnvelope extends StatefulWidget {
  const _OpenWhenEnvelope({required this.label, required this.body});

  final String label;
  final String body;

  @override
  State<_OpenWhenEnvelope> createState() => _OpenWhenEnvelopeState();
}

class _OpenWhenEnvelopeState extends State<_OpenWhenEnvelope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _toggle() {
    if (MediaQuery.of(context).disableAnimations) {
      _c.value = _c.value > 0.5 ? 0 : 1;
    } else if (_c.value > 0.5) {
      _c.reverse();
    } else {
      _c.forward();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final open =
        _c.status == AnimationStatus.forward ||
        _c.status == AnimationStatus.completed;
    return Semantics(
      button: true,
      expanded: open,
      label: 'Open when ${widget.label}',
      child: Material(
        color: AppColors.envelope,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: const BorderSide(color: AppColors.giftEdge),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _toggle,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final t = Curves.easeInOut.transform(_c.value);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        EnvelopeArt(
                          width: 46,
                          open: t,
                          rise: (t * 1.4 - 0.4).clamp(0.0, 1.0),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Open when', style: AppTypography.eyebrow),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(widget.label, style: AppTypography.label),
                            ],
                          ),
                        ),
                        Text(
                          open ? 'Close' : 'Open',
                          style: AppTypography.body.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    ClipRect(
                      child: Align(
                        alignment: Alignment.topCenter,
                        heightFactor: t,
                        child: Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.md),
                          child: SizedBox(
                            width: double.infinity,
                            child: PaperSheet(
                              fold: 16,
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Text(
                                widget.body.isEmpty
                                    ? 'A little something, just for now.'
                                    : widget.body,
                                style: AppTypography.bodyLarge.merge(
                                  _readingStyle,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Moments along a growing vine, a leaf at each one.
class _Timeline extends StatelessWidget {
  const _Timeline({this.title, required this.entries});

  final String? title;
  final List<dynamic> entries;

  @override
  Widget build(BuildContext context) {
    final items = entries
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) _SectionTitle(title!),
        for (var i = 0; i < items.length; i++)
          _VineEntry(data: items[i], index: i, last: i == items.length - 1),
      ],
    );
  }
}

class _VineEntry extends StatelessWidget {
  const _VineEntry({
    required this.data,
    required this.index,
    required this.last,
  });

  final Map<String, dynamic> data;
  final int index;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse((data['date'] as String?) ?? '');
    final title = (data['title'] as String?)?.trim() ?? '';
    final body = (data['body'] as String?)?.trim() ?? '';
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.xxs),
                Leaf(size: 20, angle: index.isEven ? -0.4 : 0.9),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.sage.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (date != null)
                    Text(
                      DateFormat.yMMMMd().format(date),
                      style: AppTypography.eyebrow,
                    ),
                  if (title.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(title, style: AppTypography.heading),
                  ],
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      body,
                      style: AppTypography.bodyLarge.merge(_readingStyle),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A countdown on little paper tiles.
class _Countdown extends StatefulWidget {
  const _Countdown({this.label, this.date});

  final String? label;
  final DateTime? date;

  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.date != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final date = widget.date;
    final diff = date?.difference(DateTime.now());
    final arrived = diff == null || diff.isNegative;
    return PaperSheet(
      fold: 0,
      child: Column(
        children: [
          if (widget.label != null) ...[
            Text(
              widget.label!,
              style: AppTypography.heading,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (date != null && !arrived)
            Row(
              children: [
                _Tile(diff.inDays, diff.inDays == 1 ? 'day' : 'days'),
                const SizedBox(width: AppSpacing.xs),
                _Tile(diff.inHours % 24, 'hr'),
                const SizedBox(width: AppSpacing.xs),
                _Tile(diff.inMinutes % 60, 'min'),
                const SizedBox(width: AppSpacing.xs),
                _Tile(diff.inSeconds % 60, 'sec'),
              ],
            )
          else if (date != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Mascot(size: 64, pose: MascotPose.celebrating),
                const SizedBox(width: AppSpacing.sm),
                Text("It's here.", style: AppTypography.displaySmall),
              ],
            ),
          if (date != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              DateFormat.yMMMMd().add_jm().format(date),
              style: AppTypography.body,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.value, this.unit);

  final int value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.button,
          border: Border.all(color: AppColors.giftEdge),
        ),
        child: Column(
          children: [
            Text(
              value.toString().padLeft(2, '0'),
              style: AppTypography.displaySmall.copyWith(
                color: AppColors.accent,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            Text(unit, style: AppTypography.caption),
          ],
        ),
      ),
    );
  }
}

class _PhotoItem {
  _PhotoItem(this.bytes, this.caption);
  final Uint8List bytes;
  final String caption;
}

/// Photos as little instant prints: white frames, a handwritten caption,
/// a strip of tape, each tilted a touch differently. Tap to see it large.
class _Photos extends StatefulWidget {
  const _Photos({this.title, required this.photos});

  final String? title;
  final List<Map<String, dynamic>> photos;

  @override
  State<_Photos> createState() => _PhotosState();
}

class _PhotosState extends State<_Photos> {
  late List<_PhotoItem> _items = _decode();

  // Decoding base64 is not free, so it happens once, not on every build.
  List<_PhotoItem> _decode() => [
    for (final m in widget.photos)
      if (PhotoCodec.decode(m['data'] as String?) case final bytes?)
        _PhotoItem(bytes, (m['caption'] as String?)?.trim() ?? ''),
  ];

  @override
  void didUpdateWidget(_Photos old) {
    super.didUpdateWidget(old);
    if (old.photos != widget.photos) _items = _decode();
  }

  void _view(int index) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: AppColors.ink.withValues(alpha: 0.92),
        barrierDismissible: true,
        pageBuilder: (_, _, _) => _PhotoViewer(items: _items, initial: index),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null) _SectionTitle(widget.title!),
        LayoutBuilder(
          builder: (context, box) {
            if (_items.length == 1) {
              return Center(
                child: SizedBox(
                  width: math.min(box.maxWidth - AppSpacing.lg, 320),
                  child: _Print(
                    item: _items.first,
                    angle: -0.025,
                    tape: true,
                    onTap: () => _view(0),
                  ),
                ),
              );
            }
            final w = (box.maxWidth - AppSpacing.md) / 2;
            return Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.lg,
              children: [
                for (var i = 0; i < _items.length; i++)
                  Padding(
                    // Stagger the right column a little, like prints laid
                    // down by hand.
                    padding: EdgeInsets.only(top: i.isOdd ? AppSpacing.md : 0),
                    child: SizedBox(
                      width: w,
                      child: _Print(
                        item: _items[i],
                        angle: const [
                          -0.035,
                          0.03,
                          0.02,
                          -0.025,
                          -0.015,
                          0.035,
                        ][i % 6],
                        tape: i % 3 != 2,
                        onTap: () => _view(i),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Print extends StatelessWidget {
  const _Print({
    required this.item,
    required this.angle,
    required this.tape,
    required this.onTap,
  });

  final _PhotoItem item;
  final double angle;
  final bool tape;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      button: true,
      label: item.caption.isEmpty ? 'Photo' : item.caption,
      child: Transform.rotate(
        angle: angle,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xs,
                  AppSpacing.xs,
                  AppSpacing.xs,
                  0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: AppColors.giftEdge),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: Image.memory(
                        item.bytes,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      ),
                    ),
                    SizedBox(
                      height: 40,
                      child: Center(
                        child: Text(
                          item.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.eyebrow.copyWith(
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (tape)
              const Positioned(
                top: -9,
                child: WashiTape(width: 56, height: 18),
              ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen photos on a dark backdrop. Swipe between them, pinch to zoom,
/// tap outside or Close to go back.
class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({required this.items, required this.initial});

  final List<_PhotoItem> items;
  final int initial;

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final PageController _pages = PageController(
    initialPage: widget.initial,
  );
  late int _index = widget.initial;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final caption = widget.items[_index].caption;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: const Text('Close'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: widget.items.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => InteractiveViewer(
                  maxScale: 4,
                  child: Center(child: Image.memory(widget.items[i].bytes)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  if (caption.isNotEmpty)
                    Text(
                      caption,
                      style: AppTypography.eyebrow.copyWith(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  if (widget.items.length > 1) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${_index + 1} of ${widget.items.length}',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
