import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/keepsake_style.dart';
import '../../shared/widgets/eager_pan.dart';
import '../../shared/widgets/gift_art.dart';
import '../../shared/widgets/motion.dart';
import '../../shared/widgets/paper.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/stickers.dart';

const _envelopes = [
  LetterPaper.cream,
  LetterPaper.kraft,
  LetterPaper.sage,
  LetterPaper.linen,
];

String describeStyle(KeepsakeStyle s) {
  final paper = LetterPaper.fromId(s.envelope).label.toLowerCase();
  final n = s.stickers.length;
  return '${paper[0].toUpperCase()}${paper.substring(1)} envelope, '
      '${s.seal.label.toLowerCase()} seal'
      '${s.mono == null ? '' : ' with ${s.mono}'}'
      '${n == 0 ? '' : ', $n sticker${n == 1 ? '' : 's'}'}';
}

/// A row in the editor showing how the keepsake is wrapped.
class WrappingRow extends StatelessWidget {
  const WrappingRow({super.key, required this.style, required this.onTap});

  final KeepsakeStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.985,
      child: PaperCard(
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        child: Row(
          children: [
            EnvelopeArt(
              width: 56,
              paper: LetterPaper.fromId(style.envelope),
              sealColor: style.seal.color,
              sealMono: style.mono,
              stickers: style.stickers,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Wrapping', style: AppTypography.eyebrow),
                  Text(
                    describeStyle(style),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.inkFaint),
          ],
        ),
      ),
    );
  }
}

/// Pick the envelope paper and seal colour, with a live preview.
Future<KeepsakeStyle?> showWrappingSheet(
  BuildContext context,
  KeepsakeStyle current,
) {
  return showModalBottomSheet<KeepsakeStyle>(
    context: context,
    isScrollControlled: true,
    // Dragging stickers would fight a drag-to-close sheet.
    enableDrag: false,
    builder: (_) => _WrappingSheet(initial: current),
  );
}

class _WrappingSheet extends StatefulWidget {
  const _WrappingSheet({required this.initial});

  final KeepsakeStyle initial;

  @override
  State<_WrappingSheet> createState() => _WrappingSheetState();
}

/// Where new stickers go first: corners and edges, clear of the seal.
const _spots = [
  (0.84, 0.22, 6.0),
  (0.16, 0.78, -10.0),
  (0.84, 0.78, 8.0),
  (0.18, 0.24, -6.0),
  (0.5, 0.86, 3.0),
  (0.5, 0.16, -4.0),
];

class _WrappingSheetState extends State<_WrappingSheet> {
  late KeepsakeStyle _style = widget.initial;
  late final _mono = TextEditingController(text: widget.initial.mono ?? '');

  @override
  void dispose() {
    _mono.dispose();
    super.dispose();
  }

  /// The sticker being moved or changed, by its place in the list.
  int? _selected;

  List<PlacedSticker> get _stickers => _style.stickers;

  void _setStickers(List<PlacedSticker> list, {int? select}) {
    setState(() {
      _style = _style.copyWith(stickers: list);
      _selected = select;
    });
  }

  void _add(StickerKind kind) {
    if (_stickers.length >= KeepsakeStyle.maxStickers) return;
    // The first spot that isn't already taken.
    final spot = _spots.firstWhere(
      (p) =>
          _stickers.every((s) => (s.x - p.$1).abs() + (s.y - p.$2).abs() > 0.2),
      orElse: () => _spots[_stickers.length % _spots.length],
    );
    HapticFeedback.lightImpact();
    _setStickers([
      ..._stickers,
      PlacedSticker(kind: kind, x: spot.$1, y: spot.$2, turn: spot.$3),
    ], select: _stickers.length);
  }

  void _change(PlacedSticker Function(PlacedSticker) f) {
    final i = _selected;
    if (i == null || i >= _stickers.length) return;
    HapticFeedback.selectionClick();
    _setStickers([..._stickers]..[i] = f(_stickers[i]), select: i);
  }

  void _remove() {
    final i = _selected;
    if (i == null || i >= _stickers.length) return;
    HapticFeedback.lightImpact();
    _setStickers([..._stickers]..removeAt(i));
  }

  @override
  Widget build(BuildContext context) {
    final d = Motion.of(context, Motion.short);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.lg,
          AppSpacing.gutter,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How should it arrive?', style: AppTypography.heading),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'They see this envelope before they open it. Add stickers, '
              'then drag them where you like.',
              style: AppTypography.body,
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: _StickerBoard(
                width: math.min(300, MediaQuery.sizeOf(context).width - 64),
                style: _style,
                selected: _selected,
                onSelect: (i) => setState(() => _selected = i),
                onMove: (i, s) => setState(() {
                  _style = _style.copyWith(stickers: [..._stickers]..[i] = s);
                }),
              ),
            ),
            AnimatedSize(
              duration: Motion.of(context, Motion.short),
              curve: Motion.settle,
              child: _selected == null || _selected! >= _stickers.length
                  ? const SizedBox(width: double.infinity)
                  : _StickerTools(
                      onTurnLeft: () =>
                          _change((s) => s.copyWith(turn: s.turn - 10)),
                      onTurnRight: () =>
                          _change((s) => s.copyWith(turn: s.turn + 10)),
                      onSmaller: () =>
                          _change((s) => s.copyWith(scale: s.scale - 0.15)),
                      onBigger: () =>
                          _change((s) => s.copyWith(scale: s.scale + 0.15)),
                      onRemove: _remove,
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(child: Text('Stickers', style: AppTypography.label)),
                Text(
                  '${_stickers.length} of ${KeepsakeStyle.maxStickers}',
                  style: AppTypography.caption,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            _StickerTray(
              full: _stickers.length >= KeepsakeStyle.maxStickers,
              onPick: _add,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Envelope', style: AppTypography.label),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                for (final p in _envelopes)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(
                        () => _style = _style.copyWith(envelope: p.id),
                      ),
                      child: Pressable(
                        child: Column(
                          children: [
                            AnimatedContainer(
                              duration: d,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _style.envelope == p.id
                                      ? AppColors.accent
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: EnvelopeArt(
                                width: 58,
                                paper: p,
                                showSeal: false,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              p.label,
                              style: AppTypography.body.copyWith(
                                color: _style.envelope == p.id
                                    ? AppColors.accent
                                    : AppColors.inkSoft,
                                fontWeight: _style.envelope == p.id
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Seal', style: AppTypography.label),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final c in SealColor.values)
                  Semantics(
                    button: true,
                    selected: _style.seal == c,
                    label: '${c.label} seal',
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _style = _style.copyWith(seal: c)),
                      child: Pressable(
                        scale: 0.9,
                        child: Column(
                          children: [
                            AnimatedContainer(
                              duration: d,
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _style.seal == c
                                      ? AppColors.ink
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: LeafSeal(
                                size: 40,
                                color: c.color,
                                mono: _style.mono,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(c.label, style: AppTypography.caption),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Initials pressed into the wax instead of the leaf.
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your initials', style: AppTypography.label),
                      Text(
                        'Pressed into the seal. Leave empty for the leaf.',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 84,
                  child: TextField(
                    controller: _mono,
                    textAlign: TextAlign.center,
                    textCapitalization: TextCapitalization.characters,
                    autocorrect: false,
                    enableSuggestions: false,
                    style: AppTypography.heading.copyWith(letterSpacing: 2),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp('[A-Za-z]')),
                      LengthLimitingTextInputFormatter(2),
                      TextInputFormatter.withFunction(
                        (_, v) => v.copyWith(text: v.text.toUpperCase()),
                      ),
                    ],
                    decoration: const InputDecoration(
                      hintText: 'SM',
                      isDense: true,
                    ),
                    onChanged: (v) =>
                        setState(() => _style = _style.copyWith(mono: v)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text('Postmark', style: AppTypography.label),
              subtitle: Text(
                'The day you send it, stamped in the corner.',
                style: AppTypography.caption,
              ),
              value: _style.postmark,
              onChanged: (v) =>
                  setState(() => _style = _style.copyWith(postmark: v)),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Use This Wrapping',
              onPressed: () => Navigator.pop(context, _style),
            ),
          ],
        ),
      ),
    );
  }
}

/// The envelope with stickers you can drag around.
class _StickerBoard extends StatelessWidget {
  const _StickerBoard({
    required this.width,
    required this.style,
    required this.selected,
    required this.onSelect,
    required this.onMove,
  });

  final double width;
  final KeepsakeStyle style;
  final int? selected;
  final ValueChanged<int?> onSelect;
  final void Function(int, PlacedSticker) onMove;

  @override
  Widget build(BuildContext context) {
    final h = width * EnvelopeArt.aspect;
    // EnvelopeArt keeps room above for its opening flap; none is needed
    // here, so only a small margin is shown above the envelope.
    final top = h * 0.08;
    final hidden = h * (EnvelopeArt.headroom - 1) - top;
    final reduced = Motion.reduced(context);
    return SizedBox(
      width: width,
      height: h + top * 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Tapping the envelope itself puts the sticker down.
          Positioned(
            left: 0,
            top: -hidden,
            width: width,
            height: h * EnvelopeArt.headroom,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelect(null),
              child: AnimatedSwitcher(
                duration: Motion.of(context, Motion.medium),
                child: EnvelopeArt(
                  key: ValueKey((
                    style.envelope,
                    style.seal,
                    style.mono,
                    style.postmark,
                  )),
                  width: width,
                  paper: LetterPaper.fromId(style.envelope),
                  sealColor: style.seal.color,
                  sealMono: style.mono,
                  postmark: style.postmark ? DateTime.now() : null,
                ),
              ),
            ),
          ),
          for (final (i, s) in style.stickers.indexed)
            Positioned(
              key: ValueKey(i),
              left: s.x * width - EnvelopeStickers.sizeFor(s, width) / 2,
              top: top + s.y * h - EnvelopeStickers.sizeFor(s, width) / 2,
              width: EnvelopeStickers.sizeFor(s, width),
              height: EnvelopeStickers.sizeFor(s, width),
              child: Semantics(
                label: '${s.kind.label} sticker',
                selected: selected == i,
                button: true,
                onTap: () => onSelect(i),
                child: RawGestureDetector(
                  gestures: {
                    EagerPan: GestureRecognizerFactoryWithHandlers<EagerPan>(
                      EagerPan.new,
                      (r) {
                        r.onDown = (_) => onSelect(i);
                        r.onUpdate = (d) => onMove(
                          i,
                          s.copyWith(
                            x: s.x + d.delta.dx / width,
                            y: s.y + d.delta.dy / h,
                          ),
                        );
                      },
                    ),
                  },
                  // Each sticker pops on when it's stuck down, and lifts a
                  // little while it's picked up.
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: reduced ? 1 : 0.2, end: 1),
                    duration: Motion.of(context, Motion.long),
                    curve: Motion.pop,
                    builder: (context, v, child) =>
                        Transform.scale(scale: v, child: child),
                    child: AnimatedScale(
                      scale: selected == i ? 1.08 : 1,
                      duration: Motion.of(context, Motion.short),
                      curve: Motion.pop,
                      child: Transform.rotate(
                        angle: s.turn * math.pi / 180,
                        child: DecoratedBox(
                          position: DecorationPosition.foreground,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: selected == i
                                ? Border.all(
                                    color: AppColors.accent.withValues(
                                      alpha: 0.7,
                                    ),
                                    width: 1.5,
                                  )
                                : null,
                          ),
                          child: StickerView(
                            kind: s.kind,
                            size: EnvelopeStickers.sizeFor(s, width),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Turn, resize or take off the picked sticker.
class _StickerTools extends StatelessWidget {
  const _StickerTools({
    required this.onTurnLeft,
    required this.onTurnRight,
    required this.onSmaller,
    required this.onBigger,
    required this.onRemove,
  });

  final VoidCallback onTurnLeft;
  final VoidCallback onTurnRight;
  final VoidCallback onSmaller;
  final VoidCallback onBigger;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    Widget tool(
      IconData icon,
      String label,
      VoidCallback onTap, {
      Color? color,
    }) => Expanded(
      child: Tooltip(
        message: label,
        child: InkResponse(
          onTap: onTap,
          radius: 28,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: color ?? AppColors.ink),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        children: [
          tool(Icons.rotate_left, 'Tilt Left', onTurnLeft),
          tool(Icons.rotate_right, 'Tilt Right', onTurnRight),
          tool(Icons.remove_circle_outline, 'Smaller', onSmaller),
          tool(Icons.add_circle_outline, 'Bigger', onBigger),
          tool(
            Icons.delete_outline,
            'Peel Off',
            onRemove,
            color: AppColors.error,
          ),
        ],
      ),
    );
  }
}

/// Every sticker, to tap onto the envelope.
class _StickerTray extends StatelessWidget {
  const _StickerTray({required this.full, required this.onPick});

  final bool full;
  final ValueChanged<StickerKind> onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: StickerKind.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
            itemBuilder: (context, i) {
              final k = StickerKind.values[i];
              return Semantics(
                button: true,
                enabled: !full,
                label: 'Add ${k.label}',
                child: Pressable(
                  scale: 0.9,
                  child: GestureDetector(
                    onTap: full ? null : () => onPick(k),
                    child: AnimatedOpacity(
                      duration: Motion.of(context, Motion.short),
                      opacity: full ? 0.35 : 1,
                      child: Container(
                        width: 64,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: StickerView(kind: k, size: k.isPup ? 58 : 50),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (full)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              'Six is the most one envelope can hold. Peel one off to '
              'add another.',
              style: AppTypography.caption,
            ),
          ),
      ],
    );
  }
}
