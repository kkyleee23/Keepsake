import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/keepsake_section.dart';
import '../../shared/widgets/primary_button.dart';

class _Entry {
  _Entry({this.date, String title = '', String body = ''})
      : title = TextEditingController(text: title),
        body = TextEditingController(text: body);
  DateTime? date;
  final TextEditingController title;
  final TextEditingController body;

  void dispose() {
    title.dispose();
    body.dispose();
  }
}

/// Editor for a Timeline: dated moments shown in order.
class TimelineEditorScreen extends StatefulWidget {
  const TimelineEditorScreen({super.key, required this.section});

  final KeepsakeSection section;

  @override
  State<TimelineEditorScreen> createState() => _TimelineEditorScreenState();
}

class _TimelineEditorScreenState extends State<TimelineEditorScreen> {
  late final TextEditingController _title;
  final List<_Entry> _entries = [];

  @override
  void initState() {
    super.initState();
    final c = widget.section.content;
    _title = TextEditingController(text: c['title'] as String? ?? '');
    final raw = (c['entries'] as List?) ?? const [];
    for (final e in raw) {
      final m = Map<String, dynamic>.from(e as Map);
      _entries.add(_Entry(
        date: DateTime.tryParse(m['date'] as String? ?? ''),
        title: m['title'] as String? ?? '',
        body: m['body'] as String? ?? '',
      ));
    }
    if (_entries.isEmpty) _entries.add(_Entry());
  }

  @override
  void dispose() {
    _title.dispose();
    for (final e in _entries) {
      e.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(_Entry entry) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: entry.date ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 50),
    );
    if (picked != null) setState(() => entry.date = picked);
  }

  void _save() {
    final entries = _entries
        .where((e) =>
            e.title.text.trim().isNotEmpty || e.body.text.trim().isNotEmpty)
        .map((e) => {
              'date': e.date?.toIso8601String(),
              'title': e.title.text.trim(),
              'body': e.body.text.trim(),
            })
        .toList();
    Navigator.of(context).pop({'title': _title.text.trim(), 'entries': entries});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Timeline')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.md,
            AppSpacing.gutter,
            AppSpacing.xxl,
          ),
          children: [
            TextField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Title (optional)'),
            ),
            const SizedBox(height: AppSpacing.lg),
            for (var i = 0; i < _entries.length; i++) ...[
              _EntryCard(
                entry: _entries[i],
                onPickDate: () => _pickDate(_entries[i]),
                onRemove: _entries.length > 1
                    ? () => setState(() => _entries.removeAt(i).dispose())
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            TextButton.icon(
              onPressed: () => setState(() => _entries.add(_Entry())),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add a moment'),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(label: 'Save', onPressed: _save),
          ],
        ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.entry,
    required this.onPickDate,
    required this.onRemove,
  });

  final _Entry entry;
  final VoidCallback onPickDate;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),
                  onPressed: onPickDate,
                  icon: const Icon(Icons.event_outlined, size: 18),
                  label: Text(
                    entry.date == null
                        ? 'Pick a date'
                        : DateFormat.yMMMMd().format(entry.date!),
                  ),
                ),
              ),
              if (onRemove != null)
                InkWell(
                  onTap: onRemove,
                  child: const Icon(Icons.close,
                      size: 18, color: AppColors.inkFaint),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: entry.title,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'What happened'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: entry.body,
            minLines: 2,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'A little more (optional)'),
          ),
        ],
      ),
    );
  }
}
