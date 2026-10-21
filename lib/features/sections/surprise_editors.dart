import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/keepsake_section.dart';
import '../../data/models/surprises.dart';
import '../../shared/widgets/primary_button.dart';
import 'surprises_view.dart';

/// Writes a secret for the recipient to scratch off.
class ScratchEditorScreen extends StatefulWidget {
  const ScratchEditorScreen({super.key, required this.section});

  final KeepsakeSection section;

  @override
  State<ScratchEditorScreen> createState() => _ScratchEditorScreenState();
}

class _ScratchEditorScreenState extends State<ScratchEditorScreen> {
  late final ScratchContent _start = ScratchContent.fromJson(
    widget.section.content,
  );
  late final _title = TextEditingController(text: _start.title);
  late final _hint = TextEditingController(text: _start.hint);
  late final _secret = TextEditingController(text: _start.secret);

  @override
  void initState() {
    super.initState();
    for (final c in [_title, _hint, _secret]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _hint.dispose();
    _secret.dispose();
    super.dispose();
  }

  ScratchContent get _content => ScratchContent(
    title: _title.text.trim(),
    hint: _hint.text.trim(),
    secret: _secret.text.trim(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scratch to Reveal')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.md,
            AppSpacing.gutter,
            AppSpacing.xxl,
          ),
          children: [
            Text(
              'Hide something under gold foil. They scratch it off with a '
              'finger to find out.',
              style: AppTypography.body,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _title,
              maxLength: ScratchContent.maxTitle,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'A line above it (optional)',
                hintText: 'Guess where we’re going',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _secret,
              maxLength: ScratchContent.maxSecret,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'The secret',
                hintText: 'Two tickets to Lisbon. We leave in May.',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _hint,
              maxLength: ScratchContent.maxHint,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Printed on the foil (optional)',
                hintText: 'Scratch here',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('How it looks', style: AppTypography.label),
            const SizedBox(height: AppSpacing.xs),
            // The real card, so they can try it themselves.
            ScratchCard(content: _content, key: ValueKey(_content.secret)),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Save',
              onPressed: _secret.text.trim().isEmpty
                  ? null
                  : () => Navigator.of(context).pop(_content.toJson()),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fills a jar with little notes.
class JarEditorScreen extends StatefulWidget {
  const JarEditorScreen({super.key, required this.section});

  final KeepsakeSection section;

  @override
  State<JarEditorScreen> createState() => _JarEditorScreenState();
}

class _JarEditorScreenState extends State<JarEditorScreen> {
  late final NoteJar _start = NoteJar.fromJson(widget.section.content);
  late final _title = TextEditingController(text: _start.title);
  late final List<TextEditingController> _notes = [
    for (final n in _start.notes) TextEditingController(text: n),
    if (_start.notes.isEmpty) TextEditingController(),
  ];

  @override
  void dispose() {
    _title.dispose();
    for (final c in _notes) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final jar = NoteJar(
      title: _title.text.trim(),
      notes: [
        for (final c in _notes)
          if (c.text.trim().isNotEmpty) c.text.trim(),
      ],
    );
    Navigator.of(context).pop(jar.toJson());
  }

  @override
  Widget build(BuildContext context) {
    final full = _notes.length >= NoteJar.maxNotes;
    final filled = _notes.where((c) => c.text.trim().isNotEmpty).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Jar of Notes')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.md,
            AppSpacing.gutter,
            AppSpacing.xxl,
          ),
          children: [
            Text(
              'Little folded notes in a jar. They tap the jar and one '
              'tumbles out, then another.',
              style: AppTypography.body,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _title,
              maxLength: NoteJar.maxTitle,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'On the label (optional)',
                hintText: 'Things I love about you',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(child: Text('Notes', style: AppTypography.label)),
                Text(
                  '$filled of ${NoteJar.maxNotes}',
                  style: AppTypography.caption,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            for (var i = 0; i < _notes.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.xs,
                    AppSpacing.xs,
                    AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: jarNoteColors[i % jarNoteColors.length],
                    borderRadius: AppRadius.card,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _notes[i],
                          maxLength: NoteJar.maxNote,
                          minLines: 1,
                          maxLines: 3,
                          onChanged: (_) => setState(() {}),
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            hintText: 'The way you hum when you cook.',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            counterText: '',
                          ),
                        ),
                      ),
                      if (_notes.length > 1)
                        IconButton(
                          tooltip: 'Take this note out',
                          icon: const Icon(
                            Icons.close,
                            size: 18,
                            color: AppColors.inkSoft,
                          ),
                          onPressed: () =>
                              setState(() => _notes.removeAt(i).dispose()),
                        ),
                    ],
                  ),
                ),
              ),
            TextButton.icon(
              onPressed: full
                  ? null
                  : () => setState(() => _notes.add(TextEditingController())),
              icon: const Icon(Icons.add, size: 20),
              label: Text(full ? 'The jar is full' : 'Add a Note'),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(label: 'Save', onPressed: filled == 0 ? null : _save),
          ],
        ),
      ),
    );
  }
}
