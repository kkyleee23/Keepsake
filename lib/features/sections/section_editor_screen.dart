import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/enums.dart';
import '../../data/models/keepsake_section.dart';
import '../../shared/widgets/primary_button.dart';

/// Edits one section's content. Pops with the updated content [Map] on save, or
/// null on cancel. The editor screen applies the result to the draft.
///
/// Handles the single-field and simple-list types. Open When and Timeline have
/// their own editors because they manage richer item lists.
class SectionEditorScreen extends StatefulWidget {
  const SectionEditorScreen({super.key, required this.section});

  final KeepsakeSection section;

  @override
  State<SectionEditorScreen> createState() => _SectionEditorScreenState();
}

class _SectionEditorScreenState extends State<SectionEditorScreen> {
  late final TextEditingController _title;
  late final TextEditingController _body;
  late final TextEditingController _prompt;
  final List<TextEditingController> _reasons = [];
  String? _dateLabel; // memory: a human date string
  DateTime? _targetDate; // countdown: the actual moment

  SectionType get _type => widget.section.type;

  @override
  void initState() {
    super.initState();
    final c = widget.section.content;
    _title = TextEditingController(
      text: (c['title'] ?? c['label']) as String? ?? '',
    );
    _body = TextEditingController(text: c['body'] as String? ?? '');
    _prompt = TextEditingController(text: c['prompt'] as String? ?? '');
    _dateLabel = c['date'] as String?;
    _targetDate = DateTime.tryParse((c['date'] as String?) ?? '');
    final items = (c['items'] as List?)?.map((e) => e.toString()).toList() ??
        const <String>[];
    for (final item in items) {
      _reasons.add(TextEditingController(text: item));
    }
    if (_type == SectionType.reasons && _reasons.isEmpty) {
      _reasons.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _prompt.dispose();
    for (final r in _reasons) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 50),
    );
    if (picked != null) {
      setState(() => _dateLabel = DateFormat.yMMMMd().format(picked));
    }
  }

  Future<void> _pickTargetDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: DateTime(now.year + 50),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_targetDate ?? now),
    );
    if (time == null) return;
    setState(() {
      _targetDate =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _save() {
    final content = <String, dynamic>{};
    switch (_type) {
      case SectionType.letter:
        content['title'] = _title.text.trim();
        content['body'] = _body.text.trim();
      case SectionType.memory:
        content['title'] = _title.text.trim();
        content['body'] = _body.text.trim();
        content['date'] = _dateLabel;
      case SectionType.customMessage:
        content['body'] = _body.text.trim();
      case SectionType.question:
        content['prompt'] = _prompt.text.trim();
      case SectionType.reasons:
        content['title'] = _title.text.trim();
        content['items'] = _reasons
            .map((r) => r.text.trim())
            .where((t) => t.isNotEmpty)
            .toList();
      case SectionType.countdown:
        content['label'] = _title.text.trim();
        content['date'] = _targetDate?.toIso8601String();
      default:
        break;
    }
    Navigator.of(context).pop(content);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_type.label)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.md,
            AppSpacing.gutter,
            AppSpacing.xxl,
          ),
          children: [
            ..._fields(),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(label: 'Save', onPressed: _save),
          ],
        ),
      ),
    );
  }

  List<Widget> _fields() {
    switch (_type) {
      case SectionType.letter:
        return [
          _label('Title (Optional)'),
          _line(_title, hint: 'A quick note'),
          const SizedBox(height: AppSpacing.lg),
          _label('Your letter'),
          _multiline(_body, hint: 'Write what you want them to read.'),
        ];
      case SectionType.memory:
        return [
          _label('Title (Optional)'),
          _line(_title, hint: 'The day everything started'),
          const SizedBox(height: AppSpacing.lg),
          _label('Date (Optional)'),
          _PickerRow(
            label: _dateLabel,
            placeholder: 'Pick a date',
            icon: Icons.event_outlined,
            onPick: _pickDate,
          ),
          const SizedBox(height: AppSpacing.lg),
          _label('What happened'),
          _multiline(_body, hint: 'Tell the story.'),
        ];
      case SectionType.customMessage:
        return [
          _label('Message'),
          _multiline(_body, hint: 'Say it your way.'),
        ];
      case SectionType.question:
        return [
          _label('Your question'),
          _multiline(_prompt, hint: 'Ask them something.', minLines: 2),
        ];
      case SectionType.reasons:
        return [
          _label('Title (Optional)'),
          _line(_title, hint: 'Reasons I\'m glad you\'re here'),
          const SizedBox(height: AppSpacing.lg),
          _label('Reasons'),
          const SizedBox(height: AppSpacing.xs),
          ..._reasonFields(),
          const SizedBox(height: AppSpacing.xs),
          TextButton.icon(
            onPressed: () =>
                setState(() => _reasons.add(TextEditingController())),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Add a reason'),
          ),
        ];
      case SectionType.countdown:
        return [
          _label('What is it counting down to?'),
          _line(_title, hint: 'Our anniversary'),
          const SizedBox(height: AppSpacing.lg),
          _label('Date & time'),
          _PickerRow(
            label: _targetDate == null
                ? null
                : DateFormat.yMMMMd().add_jm().format(_targetDate!),
            placeholder: 'Pick a date & time',
            icon: Icons.timer_outlined,
            onPick: _pickTargetDateTime,
          ),
        ];
      default:
        return [
          Text(
            'This section type is coming soon.',
            style: AppTypography.body,
          ),
        ];
    }
  }

  List<Widget> _reasonFields() {
    return [
      for (var i = 0; i < _reasons.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _reasons[i],
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(hintText: 'Reason ${i + 1}'),
                ),
              ),
              if (_reasons.length > 1)
                IconButton(
                  onPressed: () => setState(() {
                    _reasons.removeAt(i).dispose();
                  }),
                  icon: const Icon(Icons.close, color: AppColors.inkFaint),
                  tooltip: 'Remove',
                ),
            ],
          ),
        ),
    ];
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Text(text, style: AppTypography.label),
      );

  Widget _line(TextEditingController c, {String? hint}) => TextField(
        controller: c,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: hint),
      );

  Widget _multiline(TextEditingController c, {String? hint, int minLines = 6}) =>
      TextField(
        controller: c,
        minLines: minLines,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: hint),
      );
}

/// A labelled button that opens a picker and shows the chosen value.
class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.label,
    required this.placeholder,
    required this.icon,
    required this.onPick,
  });

  final String? label;
  final String placeholder;
  final IconData icon;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPick,
      icon: Icon(icon, size: 20),
      label: Align(
        alignment: Alignment.centerLeft,
        child: Text(label == null || label!.isEmpty ? placeholder : label!),
      ),
    );
  }
}
