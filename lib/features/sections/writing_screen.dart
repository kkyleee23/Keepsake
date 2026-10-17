import 'package:flutter/material.dart';

import '../../core/text/prompts.dart';
import '../../core/text/reading.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/enums.dart';
import '../../shared/widgets/brand.dart';
import '../../shared/widgets/gift_art.dart';
import '../../shared/widgets/motion.dart';
import '../../shared/widgets/primary_button.dart';

/// What a [WritingScreen] is being used for. Each kind shows the fields that
/// make sense for it.
enum WritingKind { letter, essay, page }

/// A quiet, full-screen place to write something long: a letter, an essay, or
/// a page of a book. Paper background, no boxes around the text, a live word
/// count and reading time, and a check before unsaved writing is thrown away.
///
/// Pops with a map of the fields ({title, subtitle, body, signoff}) on Done,
/// or null when the writer leaves without saving.
class WritingScreen extends StatefulWidget {
  const WritingScreen({
    super.key,
    required this.kind,
    this.title = '',
    this.subtitle = '',
    this.body = '',
    this.signoff = '',
    this.heading,
    this.occasion,
    this.paper,
    this.font,
  });

  final WritingKind kind;
  final String title;
  final String subtitle;
  final String body;
  final String signoff;

  /// App bar text, e.g. "Letter" or "Page 3".
  final String? heading;

  /// Picks the "Need a start?" ideas that fit.
  final Occasion? occasion;

  /// Stationery id for letters (see [LetterPaper]).
  final String? paper;

  /// Handwriting id for letters (see [LetterFont]).
  final String? font;

  /// Long enough for a real essay (about 8,000 words), small enough to keep a
  /// keepsake light.
  static const int maxBody = 50000;

  @override
  State<WritingScreen> createState() => _WritingScreenState();
}

class _WritingScreenState extends State<WritingScreen> {
  late final _title = TextEditingController(text: widget.title);
  late final _subtitle = TextEditingController(text: widget.subtitle);
  late final _body = TextEditingController(text: widget.body);
  late final _signoff = TextEditingController(text: widget.signoff);
  final _bodyFocus = FocusNode();
  late LetterPaper _paper = LetterPaper.fromId(widget.paper);
  late LetterFont _font = widget.kind == WritingKind.letter
      ? LetterFont.fromId(widget.font)
      : LetterFont.clean;

  bool get _changed =>
      _paper != LetterPaper.fromId(widget.paper) ||
      (widget.kind == WritingKind.letter &&
          _font != LetterFont.fromId(widget.font)) ||
      _title.text != widget.title ||
      _subtitle.text != widget.subtitle ||
      _body.text != widget.body ||
      _signoff.text != widget.signoff;

  @override
  void initState() {
    super.initState();
    _body.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    _body.dispose();
    _signoff.dispose();
    _bodyFocus.dispose();
    super.dispose();
  }

  Map<String, dynamic> _result() => {
    'title': _title.text.trim(),
    if (widget.kind == WritingKind.essay) 'subtitle': _subtitle.text.trim(),
    // Keep the writer's spacing inside the text; only trim the ends.
    'body': _body.text.trim(),
    if (widget.kind == WritingKind.letter) 'signoff': _signoff.text.trim(),
    if (widget.kind == WritingKind.letter) 'paper': _paper.id,
    if (widget.kind == WritingKind.letter) 'font': _font.id,
  };

  void _done() => Navigator.of(context).pop(_result());

  Future<void> _maybeLeave() async {
    if (!_changed) {
      Navigator.of(context).pop();
      return;
    }
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keep your writing?'),
        content: const Text('You have changes that aren\'t saved yet.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'discard'),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'save'),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (choice == 'save') _done();
    if (choice == 'discard') Navigator.of(context).pop();
  }

  /// Drops [prompt] in where the cursor is (or starts a new paragraph at the
  /// end), then leaves the cursor right after it, ready to continue.
  void _insert(String prompt) {
    final text = _body.text;
    final sel = _body.selection;
    final at = sel.isValid ? sel.end : text.length;
    final before = text.substring(0, at);
    final lead = before.trim().isEmpty
        ? ''
        : (before.endsWith('\n\n')
              ? ''
              : (before.endsWith('\n') ? '\n' : '\n\n'));
    final insert = '$lead$prompt ';
    _body.value = TextEditingValue(
      text: before + insert + text.substring(at),
      selection: TextSelection.collapsed(offset: at + insert.length),
    );
    _bodyFocus.requestFocus();
  }

  Future<void> _showIdeas() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) =>
          _IdeasSheet(prompts: Prompts.forOccasion(widget.occasion)),
    );
    if (picked != null && mounted) _insert(picked);
  }

  Future<void> _choosePaper() async {
    final picked = await showModalBottomSheet<(LetterPaper, LetterFont)>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _StationerySheet(paper: _paper, font: _font),
    );
    if (picked != null && mounted) {
      setState(() {
        _paper = picked.$1;
        _font = picked.$2;
      });
    }
  }

  String get _bodyHint => switch (widget.kind) {
    WritingKind.letter =>
      'Dear ...\n\nWrite it the way you would say it. Leave a blank line '
          'between paragraphs.',
    WritingKind.essay =>
      'Start anywhere. Leave a blank line between paragraphs.',
    WritingKind.page => 'What happens on this page?',
  };

  String get _titleHint => switch (widget.kind) {
    WritingKind.letter => 'Title (optional)',
    WritingKind.essay => 'Essay title',
    WritingKind.page => 'Chapter title (optional)',
  };

  @override
  Widget build(BuildContext context) {
    final words = Reading.words(_body.text);
    final left = WritingScreen.maxBody - _body.text.length;
    const bare = InputDecoration(
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      filled: false,
      isDense: true,
      contentPadding: EdgeInsets.zero,
      counterText: '',
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _maybeLeave();
      },
      // The whole writing space is the chosen paper.
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _paper.color,
          image: DecorationImage(
            image: AssetImage(_paper.texture),
            repeat: ImageRepeat.repeat,
            scale: 1 / PaperTextures.tileScale,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Close',
              onPressed: _maybeLeave,
            ),
            title: Text(widget.heading ?? ''),
            actions: [
              if (widget.kind == WritingKind.letter)
                IconButton(
                  onPressed: _choosePaper,
                  tooltip: 'Choose paper',
                  icon: const Icon(Icons.style_outlined),
                ),
              TextButton(onPressed: _done, child: const Text('Done')),
              const SizedBox(width: AppSpacing.xs),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: CustomPaint(
                    painter: _paper.dots
                        ? DotGridPainter(color: _paper.edge)
                        : null,
                    child: GestureDetector(
                      // Tapping empty paper below the text puts the cursor in it.
                      behavior: HitTestBehavior.translucent,
                      onTap: () => _bodyFocus.requestFocus(),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.gutter,
                          AppSpacing.md,
                          AppSpacing.gutter,
                          AppSpacing.xxxl,
                        ),
                        children: [
                          TextField(
                            controller: _title,
                            style: _font.title,
                            maxLength: 120,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: bare.copyWith(
                              hintText: _titleHint,
                              hintStyle: _font.title.copyWith(
                                color: _paper.faintInk,
                              ),
                            ),
                          ),
                          if (widget.kind == WritingKind.essay) ...[
                            const SizedBox(height: AppSpacing.xs),
                            TextField(
                              controller: _subtitle,
                              style: AppTypography.bodyLarge.copyWith(
                                color: AppColors.inkSoft,
                              ),
                              maxLength: 160,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: bare.copyWith(
                                hintText: 'A line under the title (optional)',
                                hintStyle: AppTypography.bodyLarge.copyWith(
                                  color: _paper.faintInk,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.md),
                          Container(height: 1, color: _paper.edge),
                          const SizedBox(height: AppSpacing.md),
                          TextField(
                            controller: _body,
                            focusNode: _bodyFocus,
                            autofocus: widget.body.isEmpty,
                            maxLines: null,
                            minLines: 12,
                            maxLength: WritingScreen.maxBody,
                            keyboardType: TextInputType.multiline,
                            textCapitalization: TextCapitalization.sentences,
                            style: _font.body,
                            decoration: bare.copyWith(
                              hintText: _bodyHint,
                              hintMaxLines: 4,
                              hintStyle: _font.body.copyWith(
                                color: _paper.faintInk,
                              ),
                            ),
                          ),
                          if (widget.kind == WritingKind.letter) ...[
                            const SizedBox(height: AppSpacing.lg),
                            Align(
                              alignment: Alignment.centerRight,
                              child: SizedBox(
                                width: 220,
                                child: TextField(
                                  controller: _signoff,
                                  maxLength: 60,
                                  textAlign: TextAlign.right,
                                  style: AppTypography.eyebrow.copyWith(
                                    fontSize: 24,
                                    color: _paper.signature,
                                  ),
                                  decoration: bare.copyWith(
                                    hintText: 'Sign-off, like "With love"',
                                    hintStyle: AppTypography.body.copyWith(
                                      color: _paper.faintInk,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.xxs,
                    AppSpacing.xs,
                    AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: _paper.edge)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        words == 0
                            ? 'No words yet'
                            : '$words ${words == 1 ? 'word' : 'words'}'
                                  '  ·  ${Reading.minutesLabel(_body.text)}',
                        style: AppTypography.caption.copyWith(
                          color: _paper.softInk,
                        ),
                      ),
                      const Spacer(),
                      if (left < 2000)
                        Text(
                          '$left left',
                          style: AppTypography.caption.copyWith(
                            color: left < 200
                                ? AppColors.error
                                : _paper.softInk,
                          ),
                        )
                      else
                        TextButton.icon(
                          onPressed: _showIdeas,
                          icon: const Icon(Icons.lightbulb_outline, size: 18),
                          label: const Text('Need a Start?'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A short list of ways to begin, with the thinking mascot.
class _IdeasSheet extends StatelessWidget {
  const _IdeasSheet({required this.prompts});

  final List<String> prompts;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.lg,
          AppSpacing.gutter,
          AppSpacing.xl,
        ),
        children: [
          Row(
            children: [
              const Mascot(size: 72, pose: MascotPose.thinking),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Need a start?', style: AppTypography.heading),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Tap one and finish the sentence your way.',
                      style: AppTypography.body,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final (i, p) in prompts.indexed)
            RiseIn(
              index: i,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Pressable(
                  child: Material(
                    color: AppColors.giftPaper,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      side: BorderSide(color: AppColors.giftEdge),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => Navigator.pop(context, p),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        child: Text(
                          p.endsWith(':') ? p : '$p ...',
                          style: AppTypography.eyebrow.copyWith(
                            fontSize: 22,
                            color: AppColors.ink,
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

/// Paper and handwriting, chosen together, with live previews.
class _StationerySheet extends StatefulWidget {
  const _StationerySheet({required this.paper, required this.font});

  final LetterPaper paper;
  final LetterFont font;

  @override
  State<_StationerySheet> createState() => _StationerySheetState();
}

class _StationerySheetState extends State<_StationerySheet> {
  late LetterPaper _paper = widget.paper;
  late LetterFont _font = widget.font;

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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Paper and handwriting', style: AppTypography.heading),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'They will read your letter just like this.',
              style: AppTypography.body,
            ),
            const SizedBox(height: AppSpacing.md),
            // Live preview of the choice.
            AnimatedSwitcher(
              duration: Motion.of(context, Motion.medium),
              child: PaperSheet.of(
                _paper,
                key: ValueKey((_paper, _font)),
                fold: 16,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dear you,',
                        style: _font.title.copyWith(
                          fontSize: _font.title.fontSize! * 0.8,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'I keep thinking about that day by the lake.',
                        style: _font.body,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Paper', style: AppTypography.label),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                for (final p in LetterPaper.values)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxs,
                      ),
                      child: GestureDetector(
                        onTap: () => setState(() => _paper = p),
                        child: Pressable(
                          child: Column(
                            children: [
                              AnimatedContainer(
                                duration: d,
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: p == _paper
                                        ? AppColors.accent
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: AspectRatio(
                                  aspectRatio: 0.75,
                                  child: PaperSheet.of(
                                    p,
                                    fold: 10,
                                    padding: EdgeInsets.zero,
                                    child: const SizedBox.expand(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                p.label,
                                maxLines: 1,
                                style: AppTypography.caption.copyWith(
                                  color: p == _paper
                                      ? AppColors.accent
                                      : AppColors.inkSoft,
                                  fontWeight: p == _paper
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Handwriting', style: AppTypography.label),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                for (final f in LetterFont.values)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxs,
                      ),
                      child: GestureDetector(
                        onTap: () => setState(() => _font = f),
                        child: Pressable(
                          child: AnimatedContainer(
                            duration: d,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: f == _font
                                    ? AppColors.accent
                                    : AppColors.hairline,
                                width: f == _font ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Aa',
                                  style: f.title.copyWith(
                                    fontSize: f == LetterFont.hand ? 30 : 22,
                                  ),
                                ),
                                Text(
                                  f.label,
                                  style: AppTypography.caption.copyWith(
                                    color: f == _font
                                        ? AppColors.accent
                                        : AppColors.inkSoft,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Use These',
              onPressed: () => Navigator.pop(context, (_paper, _font)),
            ),
          ],
        ),
      ),
    );
  }
}
