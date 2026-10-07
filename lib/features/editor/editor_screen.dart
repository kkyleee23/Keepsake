import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/enums.dart';
import '../../data/models/keepsake.dart';
import '../../data/models/keepsake_section.dart';
import '../../data/providers.dart';
import '../creation/keepsake_factory.dart';
import '../keepsakes/application/keepsakes_controller.dart';
import '../sections/open_when_editor_screen.dart';
import '../sections/section_display.dart';
import '../sections/section_editor_screen.dart';
import '../sections/timeline_editor_screen.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/primary_button.dart';

/// The assembly surface: the creator builds a Keepsake here.
///
/// Feels like putting together a gift, not filling a form. Every change
/// autosaves to the local draft so nothing is lost.
class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key, required this.keepsakeId});

  final String keepsakeId;

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  Keepsake? _draft;
  bool _loading = true;

  /// Section types that have a working editor today - so the Add sheet never
  /// offers a dead end.
  static const _addable = [
    SectionType.letter,
    SectionType.memory,
    SectionType.openWhen,
    SectionType.reasons,
    SectionType.timeline,
    SectionType.question,
    SectionType.countdown,
    SectionType.customMessage,
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final k = await ref.read(keepsakeRepositoryProvider).getById(widget.keepsakeId);
    if (!mounted) return;
    setState(() {
      _draft = k;
      _loading = false;
    });
  }

  Future<void> _persist(Keepsake next) async {
    setState(() => _draft = next);
    await ref.read(keepsakesControllerProvider.notifier).upsert(next);
  }

  List<KeepsakeSection> _renumbered(List<KeepsakeSection> list) {
    return [
      for (var i = 0; i < list.length; i++) list[i].copyWith(position: i),
    ];
  }

  Future<void> _addSection(SectionType type) async {
    final draft = _draft!;
    final section = KeepsakeFactory.newSection(type, draft.sections.length);
    await _persist(draft.copyWith(
      sections: [...draft.orderedSections, section],
      updatedAt: DateTime.now(),
    ));
    await _openSection(section);
  }

  Future<void> _openSection(KeepsakeSection section) async {
    final content = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => _editorFor(section)),
    );
    if (content == null) return;
    final draft = _draft!;
    final updated = draft.orderedSections
        .map((s) => s.id == section.id
            ? s.copyWith(content: content, updatedAt: DateTime.now())
            : s)
        .toList();
    await _persist(draft.copyWith(sections: updated, updatedAt: DateTime.now()));
  }

  Future<void> _deleteSection(KeepsakeSection section) async {
    final draft = _draft!;
    final next = _renumbered(
      draft.orderedSections.where((s) => s.id != section.id).toList(),
    );
    await _persist(draft.copyWith(sections: next, updatedAt: DateTime.now()));
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    final draft = _draft!;
    final list = [...draft.orderedSections];
    // ReorderableListView.onReorder reports the pre-removal index.
    if (newIndex > oldIndex) newIndex -= 1;
    final moved = list.removeAt(oldIndex);
    list.insert(newIndex, moved);
    await _persist(
        draft.copyWith(sections: _renumbered(list), updatedAt: DateTime.now()));
  }

  Future<void> _rename() async {
    final draft = _draft!;
    final controller = TextEditingController(text: draft.title);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Name this keepsake', style: AppTypography.heading),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'A title just for you'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await _persist(draft.copyWith(title: result, updatedAt: DateTime.now()));
    }
  }

  void _openAddSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter,
                  AppSpacing.lg, AppSpacing.gutter, AppSpacing.xs),
              child: Text('Add something', style: AppTypography.heading),
            ),
            for (final type in _addable)
              ListTile(
                leading: Icon(_iconFor(type), color: AppColors.inkSoft),
                title: Text(type.label, style: AppTypography.bodyLarge),
                onTap: () {
                  Navigator.pop(ctx);
                  _addSection(type);
                },
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final draft = _draft;
    if (draft == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.error_outline,
          title: "Can't find this keepsake",
          message: 'It may have been deleted.',
          actionLabel: 'Go home',
          onAction: () => context.go('/home'),
        ),
      );
    }

    final sections = draft.orderedSections;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit'),
        actions: [
          TextButton(
            onPressed: draft.hasContent
                ? () => context.push('/preview/${draft.id}')
                : null,
            child: const Text('Preview'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.md,
            AppSpacing.gutter,
            AppSpacing.xxl,
          ),
          children: [
            _CoverCard(keepsake: draft, onRename: _rename),
            const SizedBox(height: AppSpacing.lg),
            if (sections.isEmpty)
              _FirstSectionPrompt(onAdd: _openAddSheet)
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: sections.length,
                // ignore: deprecated_member_use
                onReorder: _reorder,
                itemBuilder: (context, index) {
                  final s = sections[index];
                  return _SectionCard(
                    key: ValueKey(s.id),
                    section: s,
                    index: index,
                    onTap: () => _openSection(s),
                    onDelete: () => _deleteSection(s),
                  );
                },
              ),
            const SizedBox(height: AppSpacing.md),
            if (sections.isNotEmpty)
              OutlinedButton.icon(
                onPressed: _openAddSheet,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add something'),
              ),
            if (draft.hasContent) ...[
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: draft.isPublished ? 'Update & re-share' : 'Publish',
                icon: Icons.ios_share,
                onPressed: () => context.push('/delivery/${draft.id}'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _editorFor(KeepsakeSection section) {
    switch (section.type) {
      case SectionType.openWhen:
        return OpenWhenEditorScreen(section: section);
      case SectionType.timeline:
        return TimelineEditorScreen(section: section);
      default:
        return SectionEditorScreen(section: section);
    }
  }

  static IconData _iconFor(SectionType type) {
    switch (type) {
      case SectionType.letter:
        return Icons.mail_outline;
      case SectionType.memory:
        return Icons.auto_stories_outlined;
      case SectionType.openWhen:
        return Icons.lock_outline;
      case SectionType.reasons:
        return Icons.format_list_numbered;
      case SectionType.timeline:
        return Icons.timeline_outlined;
      case SectionType.question:
        return Icons.help_outline;
      case SectionType.countdown:
        return Icons.timer_outlined;
      case SectionType.customMessage:
        return Icons.chat_bubble_outline;
      default:
        return Icons.add;
    }
  }
}

class _CoverCard extends StatelessWidget {
  const _CoverCard({required this.keepsake, required this.onRename});

  final Keepsake keepsake;
  final VoidCallback onRename;

  @override
  Widget build(BuildContext context) {
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
          Text(keepsake.occasion.label.toUpperCase(),
              style: AppTypography.caption),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(keepsake.title, style: AppTypography.displaySmall),
              ),
              IconButton(
                onPressed: onRename,
                icon: const Icon(Icons.edit_outlined, color: AppColors.inkSoft),
                tooltip: 'Rename',
              ),
            ],
          ),
          if (keepsake.recipientName.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text('For ${keepsake.recipientName}', style: AppTypography.body),
          ],
          if (keepsake.coverNote != null &&
              keepsake.coverNote!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(keepsake.coverNote!,
                style: AppTypography.body.copyWith(fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    super.key,
    required this.section,
    required this.index,
    required this.onTap,
    required this.onDelete,
  });

  final KeepsakeSection section;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final preview = SectionDisplay.preview(section);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.card,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.card,
              border: Border.all(color: AppColors.hairline),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.only(right: AppSpacing.sm),
                    child: Icon(Icons.drag_indicator,
                        color: AppColors.inkFaint),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(section.type.label, style: AppTypography.caption),
                      const SizedBox(height: 2),
                      Text(
                        preview.isEmpty ? 'Tap to write' : preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyLarge.copyWith(
                          color: preview.isEmpty
                              ? AppColors.inkFaint
                              : AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.inkFaint),
                  tooltip: 'Remove',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FirstSectionPrompt extends StatelessWidget {
  const _FirstSectionPrompt({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        children: [
          Text(
            'Start with a letter, a memory, or a few reasons.',
            style: AppTypography.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Add something',
            icon: Icons.add,
            onPressed: onAdd,
            expand: false,
          ),
        ],
      ),
    );
  }
}
