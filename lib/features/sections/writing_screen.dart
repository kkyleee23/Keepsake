import 'package:flutter/material.dart';

import '../../core/text/reading.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

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
  });

  final WritingKind kind;
  final String title;
  final String subtitle;
  final String body;
  final String signoff;

  /// App bar text, e.g. "Letter" or "Page 3".
  final String? heading;

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

  bool get _changed =>
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
        backgroundColor: AppColors.giftPaper,
        appBar: AppBar(
          backgroundColor: AppColors.giftPaper,
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close',
            onPressed: _maybeLeave,
          ),
          title: Text(widget.heading ?? ''),
          actions: [
            TextButton(onPressed: _done, child: const Text('Done')),
            const SizedBox(width: AppSpacing.xs),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gutter,
                  vertical: AppSpacing.sm,
                ),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.giftEdge)),
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
                        '$left characters left',
                        style: AppTypography.caption.copyWith(
                          color: left < 200 ? AppColors.error : null,
                        ),
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
