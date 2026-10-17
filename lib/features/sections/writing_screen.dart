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

  bool get _changed =>
      _paper != LetterPaper.fromId(widget.paper) ||
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
    final picked = await showModalBottomSheet<LetterPaper>(
      context: context,
      builder: (ctx) => _PaperSheetPicker(current: _paper),
    );
    if (picked != null && mounted) setState(() => _paper = picked);
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
      child: Scaffold(
        backgroundColor: _paper.color,
        appBar: AppBar(
          backgroundColor: _paper.color,
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
                          style: AppTypography.title,
                          maxLength: 120,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: bare.copyWith(
                            hintText: _titleHint,
                            hintStyle: AppTypography.title.copyWith(
                              color: AppColors.inkFaint,
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
                                color: AppColors.inkFaint,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        Container(height: 1, color: AppColors.giftEdge),
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
                          style: AppTypography.bodyLarge.copyWith(height: 1.7),
                          decoration: bare.copyWith(
                            hintText: _bodyHint,
                            hintMaxLines: 4,
                            hintStyle: AppTypography.bodyLarge.copyWith(
                              height: 1.7,
                              color: AppColors.inkFaint,
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
                                ),
                                decoration: bare.copyWith(
                                  hintText: 'Sign-off, like "With love"',
                                  hintStyle: AppTypography.body.copyWith(
                                    color: AppColors.inkFaint,
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
                      style: AppTypography.caption,
                    ),
                    const Spacer(),
                    if (left < 2000)
                      Text(
                        '$left left',
                        style: AppTypography.caption.copyWith(
                          color: left < 200 ? AppColors.error : null,
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

/// Four little sheets of stationery to choose from.
class _PaperSheetPicker extends StatelessWidget {
  const _PaperSheetPicker({required this.current});

  final LetterPaper current;

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
            Text('Choose the paper', style: AppTypography.heading),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'They will read your letter on it.',
              style: AppTypography.body,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                for (final p in LetterPaper.values)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxs,
                      ),
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, p),
                        child: Pressable(
                          child: Column(
                            children: [
                              AnimatedContainer(
                                duration: Motion.of(context, Motion.short),
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: p == current
                                        ? AppColors.accent
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: AspectRatio(
                                  aspectRatio: 0.75,
                                  child: PaperSheet.of(
                                    p,
                                    fold: 12,
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        for (final w in const [0.7, 0.9, 0.5])
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 6,
                                            ),
                                            child: FractionallySizedBox(
                                              widthFactor: w,
                                              child: Container(
                                                height: 3,
                                                decoration: BoxDecoration(
                                                  color: p.edge,
                                                  borderRadius:
                                                      BorderRadius.circular(2),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                p.label,
                                style: AppTypography.body.copyWith(
                                  fontWeight: p == current
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: p == current
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
