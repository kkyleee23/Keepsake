import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/keepsake_section.dart';
import '../../shared/widgets/primary_button.dart';

class _Item {
  _Item({String label = '', String body = ''})
      : label = TextEditingController(text: label),
        body = TextEditingController(text: body);
  final TextEditingController label;
  final TextEditingController body;

  void dispose() {
    label.dispose();
    body.dispose();
  }
}

/// Editor for an "Open When" collection: labelled notes the recipient opens one
/// at a time ("When you miss me", "When you had a bad day", ...).
class OpenWhenEditorScreen extends StatefulWidget {
  const OpenWhenEditorScreen({super.key, required this.section});

  final KeepsakeSection section;

  @override
  State<OpenWhenEditorScreen> createState() => _OpenWhenEditorScreenState();
}

class _OpenWhenEditorScreenState extends State<OpenWhenEditorScreen> {
  late final TextEditingController _title;
  final List<_Item> _items = [];

  @override
  void initState() {
    super.initState();
    final c = widget.section.content;
    _title = TextEditingController(text: c['title'] as String? ?? '');
    final raw = (c['items'] as List?) ?? const [];
    for (final e in raw) {
      final m = Map<String, dynamic>.from(e as Map);
      _items.add(_Item(
        label: m['label'] as String? ?? '',
        body: m['body'] as String? ?? '',
      ));
    }
    if (_items.isEmpty) {
      _items.add(_Item(label: 'You miss me'));
    }
  }

  @override
  void dispose() {
    _title.dispose();
    for (final i in _items) {
      i.dispose();
    }
    super.dispose();
  }

  void _save() {
    final items = _items
        .where((i) => i.label.text.trim().isNotEmpty)
        .map((i) => {
              'label': i.label.text.trim(),
              'body': i.body.text.trim(),
            })
        .toList();
    Navigator.of(context).pop({'title': _title.text.trim(), 'items': items});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Open When')),
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
              'Little notes they open when they need them.',
              style: AppTypography.body,
            ),
            const SizedBox(height: AppSpacing.lg),
            for (var i = 0; i < _items.length; i++) ...[
              _ItemCard(
                item: _items[i],
                onRemove: _items.length > 1
                    ? () => setState(() => _items.removeAt(i).dispose())
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            TextButton.icon(
              onPressed: () => setState(() => _items.add(_Item())),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add one'),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(label: 'Save', onPressed: _save),
          ],
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.onRemove});

  final _Item item;
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
              Text('Open when', style: AppTypography.eyebrow),
              const Spacer(),
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
            controller: item.label,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'you miss me'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: item.body,
            minLines: 2,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'What they should read.'),
          ),
        ],
      ),
    );
  }
}
