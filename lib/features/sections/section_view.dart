import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/enums.dart';
import '../../data/models/keepsake_section.dart';

/// Read-only rendering of a single section.
///
/// Used by both Preview and (later) the recipient experience, so the creator
/// always sees exactly what will be received - no second implementation.
class SectionView extends StatelessWidget {
  const SectionView({super.key, required this.section});

  final KeepsakeSection section;

  @override
  Widget build(BuildContext context) {
    switch (section.type) {
      case SectionType.letter:
        return _TitledBody(
          title: section.content['title'] as String?,
          body: section.content['body'] as String?,
        );
      case SectionType.memory:
        return _TitledBody(
          title: section.content['title'] as String?,
          body: section.content['body'] as String?,
          date: section.content['date'] as String?,
        );
      case SectionType.customMessage:
        return _TitledBody(body: section.content['body'] as String?);
      case SectionType.question:
        return _Question(prompt: section.content['prompt'] as String?);
      case SectionType.reasons:
        return _Reasons(
          title: section.content['title'] as String?,
          items: (section.content['items'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const [],
        );
      case SectionType.openWhen:
        return _OpenWhen(
          title: section.content['title'] as String?,
          items: (section.content['items'] as List?) ?? const [],
        );
      case SectionType.timeline:
        return _Timeline(
          title: section.content['title'] as String?,
          entries: (section.content['entries'] as List?) ?? const [],
        );
      case SectionType.countdown:
        return _Countdown(
          label: section.content['label'] as String?,
          date: DateTime.tryParse((section.content['date'] as String?) ?? ''),
        );
      default:
        // Unsupported-in-reader types degrade to a quiet label rather than
        // breaking the scroll.
        return Text(section.type.label, style: AppTypography.caption);
    }
  }
}

class _TitledBody extends StatelessWidget {
  const _TitledBody({this.title, this.body, this.date});

  final String? title;
  final String? body;
  final String? date;

  @override
  Widget build(BuildContext context) {
    final t = title?.trim() ?? '';
    final b = body?.trim() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (date != null && date!.isNotEmpty) ...[
          Text(date!, style: AppTypography.caption),
          const SizedBox(height: AppSpacing.xs),
        ],
        if (t.isNotEmpty) ...[
          Text(t, style: AppTypography.heading),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (b.isNotEmpty)
          Text(b, style: AppTypography.bodyLarge.copyWith(height: 1.6)),
      ],
    );
  }
}

class _Question extends StatelessWidget {
  const _Question({this.prompt});

  final String? prompt;

  @override
  Widget build(BuildContext context) {
    final p = prompt?.trim() ?? '';
    if (p.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.only(left: AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: AppColors.accent, width: 2),
        ),
      ),
      child: Text(
        p,
        style: AppTypography.bodyLarge
            .copyWith(height: 1.6, fontStyle: FontStyle.italic),
      ),
    );
  }
}

class _Reasons extends StatelessWidget {
  const _Reasons({this.title, required this.items});

  final String? title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final t = title?.trim() ?? '';
    final visible = items.where((e) => e.trim().isNotEmpty).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (t.isNotEmpty) ...[
          Text(t, style: AppTypography.heading),
          const SizedBox(height: AppSpacing.sm),
        ],
        for (var i = 0; i < visible.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 28,
                  child: Text('${i + 1}.', style: AppTypography.bodyLarge),
                ),
                Expanded(
                  child: Text(
                    visible[i],
                    style: AppTypography.bodyLarge.copyWith(height: 1.6),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _OpenWhen extends StatelessWidget {
  const _OpenWhen({this.title, required this.items});

  final String? title;
  final List<dynamic> items;

  @override
  Widget build(BuildContext context) {
    final t = title?.trim() ?? '';
    final cards = items
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((m) => (m['label'] as String?)?.trim().isNotEmpty ?? false)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (t.isNotEmpty) ...[
          Text(t, style: AppTypography.heading),
          const SizedBox(height: AppSpacing.sm),
        ],
        for (final m in cards)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _OpenWhenCard(
              label: (m['label'] as String?)?.trim() ?? '',
              body: (m['body'] as String?)?.trim() ?? '',
            ),
          ),
      ],
    );
  }
}

class _OpenWhenCard extends StatefulWidget {
  const _OpenWhenCard({required this.label, required this.body});

  final String label;
  final String body;

  @override
  State<_OpenWhenCard> createState() => _OpenWhenCardState();
}

class _OpenWhenCardState extends State<_OpenWhenCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.card,
      child: InkWell(
        onTap: () => setState(() => _open = !_open),
        borderRadius: AppRadius.card,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadius.card,
            border: Border.all(color: AppColors.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Open when ${widget.label}',
                      style: AppTypography.label,
                    ),
                  ),
                  Icon(
                    _open ? Icons.lock_open_outlined : Icons.lock_outline,
                    size: 20,
                    color: AppColors.inkFaint,
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox(width: double.infinity),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    widget.body.isEmpty ? 'A little something.' : widget.body,
                    style: AppTypography.bodyLarge.copyWith(height: 1.6),
                  ),
                ),
                crossFadeState: _open
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 220),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({this.title, required this.entries});

  final String? title;
  final List<dynamic> entries;

  @override
  Widget build(BuildContext context) {
    final t = title?.trim() ?? '';
    final items = entries.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (t.isNotEmpty) ...[
          Text(t, style: AppTypography.heading),
          const SizedBox(height: AppSpacing.md),
        ],
        for (final m in items) _TimelineEntryView(data: m),
      ],
    );
  }
}

class _TimelineEntryView extends StatelessWidget {
  const _TimelineEntryView({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse((data['date'] as String?) ?? '');
    final title = (data['title'] as String?)?.trim() ?? '';
    final body = (data['body'] as String?)?.trim() ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.only(left: AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.accent, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (date != null)
            Text(DateFormat.yMMMMd().format(date), style: AppTypography.eyebrow),
          if (title.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(title, style: AppTypography.heading),
          ],
          if (body.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(body, style: AppTypography.bodyLarge.copyWith(height: 1.6)),
          ],
        ],
      ),
    );
  }
}

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

  String _remaining(DateTime target) {
    final diff = target.difference(DateTime.now());
    if (diff.isNegative) return "It's here.";
    final d = diff.inDays;
    final h = diff.inHours % 24;
    final m = diff.inMinutes % 60;
    if (d > 0) return '$d ${d == 1 ? 'day' : 'days'}, $h hr to go';
    if (h > 0) return '$h hr $m min to go';
    return '$m min to go';
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.label?.trim() ?? '';
    final date = widget.date;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) Text(label, style: AppTypography.heading),
          if (date != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(_remaining(date), style: AppTypography.display),
            const SizedBox(height: AppSpacing.xs),
            Text(
              DateFormat.yMMMMd().add_jm().format(date),
              style: AppTypography.body,
            ),
          ],
        ],
      ),
    );
  }
}
