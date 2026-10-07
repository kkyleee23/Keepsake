import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/enums.dart';
import '../../data/models/keepsake_section.dart';

/// Read-only rendering of a single section.
///
/// Used by both Preview and (later) the recipient experience, so the creator
/// always sees exactly what will be received — no second implementation.
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
