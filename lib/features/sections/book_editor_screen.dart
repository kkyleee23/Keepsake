import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/text/reading.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/keepsake_section.dart';
import '../../shared/widgets/brand.dart';
import '../../shared/widgets/motion.dart';
import '../../shared/widgets/primary_button.dart';
import 'writing_screen.dart';

class _Page {
  _Page({required this.id, this.title = '', this.body = ''});

  final String id;
  String title;
  String body;

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'body': body};
}

/// Editor for a Book: a title, an optional dedication, and pages written one
/// at a time in the full-screen writer. The recipient turns them like a book.
class BookEditorScreen extends StatefulWidget {
  const BookEditorScreen({super.key, required this.section});

  final KeepsakeSection section;

  /// Enough for a small book without making the keepsake heavy.
  static const int maxPages = 40;

  @override
  State<BookEditorScreen> createState() => _BookEditorScreenState();
}

class _BookEditorScreenState extends State<BookEditorScreen> {
  late final TextEditingController _title;
  late final TextEditingController _dedication;
  final List<_Page> _pages = [];

  @override
  void initState() {
    super.initState();
    final c = widget.section.content;
    _title = TextEditingController(text: c['title'] as String? ?? '');
    _dedication = TextEditingController(text: c['dedication'] as String? ?? '');
    for (final e in (c['pages'] as List?) ?? const []) {
      final m = Map<String, dynamic>.from(e as Map);
      _pages.add(
        _Page(
          id: m['id'] as String? ?? const Uuid().v4(),
          title: m['title'] as String? ?? '',
          body: m['body'] as String? ?? '',
        ),
      );
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _dedication.dispose();
    super.dispose();
  }

  Future<void> _edit(_Page page, int number) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      Motion.route(
        context,
        WritingScreen(
          kind: WritingKind.page,
          heading: 'Page $number',
          title: page.title,
          body: page.body,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      page.title = result['title'] as String? ?? '';
      page.body = result['body'] as String? ?? '';
    });
  }

  Future<void> _addPage() async {
    if (_pages.length >= BookEditorScreen.maxPages) return;
    final page = _Page(id: const Uuid().v4());
    await _edit(page, _pages.length + 1);
    if (!mounted) return;
    if (page.title.isNotEmpty || page.body.isNotEmpty) {
      setState(() => _pages.add(page));
    }
  }

  void _move(int from, int to) {
    if (to < 0 || to >= _pages.length) return;
    setState(() => _pages.insert(to, _pages.removeAt(from)));
  }

  Future<void> _remove(int i) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove page ${i + 1}?'),
        content: const Text('Its writing will be gone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (yes == true && mounted) setState(() => _pages.removeAt(i));
  }

  void _save() {
    Navigator.of(context).pop({
      'title': _title.text.trim(),
      'dedication': _dedication.text.trim(),
      'pages': [for (final p in _pages) p.toJson()],
    });
  }

  @override
  Widget build(BuildContext context) {
    final full = _pages.length >= BookEditorScreen.maxPages;
    final words = _pages.fold<int>(0, (n, p) => n + Reading.words(p.body));
    return Scaffold(
      appBar: AppBar(title: const Text('Book')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.md,
            AppSpacing.gutter,
            AppSpacing.xxl,
          ),
          children: [
            Text('Title', style: AppTypography.label),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _title,
              maxLength: 80,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'The Book of Us',
                counterText: '',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Dedication (Optional)', style: AppTypography.label),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _dedication,
              maxLength: 200,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'For Mia, who reads the last page first.',
                counterText: '',
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(child: Text('Pages', style: AppTypography.heading)),
                if (_pages.isNotEmpty)
                  Text(
                    '$words words  ·  ${_pages.length} '
                    '${_pages.length == 1 ? 'page' : 'pages'}',
                    style: AppTypography.caption,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_pages.isEmpty)
              _NoPages(onAdd: _addPage)
            else
              for (var i = 0; i < _pages.length; i++)
                RiseIn(
                  key: ValueKey(_pages[i].id),
                  index: i,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _PageTile(
                      number: i + 1,
                      page: _pages[i],
                      onTap: () => _edit(_pages[i], i + 1),
                      onUp: i == 0 ? null : () => _move(i, i - 1),
                      onDown: i == _pages.length - 1
                          ? null
                          : () => _move(i, i + 1),
                      onRemove: () => _remove(i),
                    ),
                  ),
                ),
            if (_pages.isNotEmpty)
              OutlinedButton.icon(
                onPressed: full ? null : _addPage,
                icon: const Icon(Icons.note_add_outlined, size: 20),
                label: Text(full ? 'Page Limit Reached' : 'Add a Page'),
              ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(label: 'Save', onPressed: _save),
          ],
        ),
      ),
    );
  }
}

class _NoPages extends StatelessWidget {
  const _NoPages({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        children: [
          const Mascot(size: 96, pose: MascotPose.typing),
          const SizedBox(height: AppSpacing.sm),
          Text('Write the first page', style: AppTypography.heading),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'A story, a year of letters, the chapters of your friendship. '
            'They turn each page like a real book.',
            style: AppTypography.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Start Writing',
            icon: Icons.edit_outlined,
            onPressed: onAdd,
            expand: false,
          ),
        ],
      ),
    );
  }
}

class _PageTile extends StatelessWidget {
  const _PageTile({
    required this.number,
    required this.page,
    required this.onTap,
    required this.onUp,
    required this.onDown,
    required this.onRemove,
  });

  final int number;
  final _Page page;
  final VoidCallback onTap;
  final VoidCallback? onUp;
  final VoidCallback? onDown;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final firstLine = page.body.trim().split('\n').first;
    return Material(
      color: AppColors.giftPaper,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.card,
        side: BorderSide(color: AppColors.giftEdge),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.xs,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  '$number',
                  style: AppTypography.eyebrow.copyWith(fontSize: 26),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      page.title.isEmpty ? 'Untitled page' : page.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.label,
                    ),
                    if (firstLine.isNotEmpty)
                      Text(
                        firstLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body,
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onUp,
                tooltip: 'Move up',
                icon: const Icon(Icons.arrow_upward, size: 18),
              ),
              IconButton(
                onPressed: onDown,
                tooltip: 'Move down',
                icon: const Icon(Icons.arrow_downward, size: 18),
              ),
              IconButton(
                onPressed: onRemove,
                tooltip: 'Remove page',
                icon: const Icon(
                  Icons.close,
                  size: 18,
                  color: AppColors.inkFaint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
