import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/media/photo_codec.dart';
import '../../data/models/keepsake_section.dart';
import '../../shared/widgets/brand.dart';
import '../../shared/widgets/primary_button.dart';

class _Photo {
  _Photo({required this.id, required this.data, String caption = ''})
    : bytes = PhotoCodec.decode(data),
      caption = TextEditingController(text: caption);

  final String id;
  final String data;
  final Uint8List? bytes;
  final TextEditingController caption;
}

/// Editor for a Photos section: pick a few photos and give each a short
/// caption. Photos are shrunk on the device before they're saved.
class PhotoEditorScreen extends StatefulWidget {
  const PhotoEditorScreen({
    super.key,
    required this.section,
    required this.otherPhotos,
  });

  final KeepsakeSection section;

  /// Photos already used by other sections of this keepsake, so the
  /// per-keepsake limit holds across sections.
  final int otherPhotos;

  @override
  State<PhotoEditorScreen> createState() => _PhotoEditorScreenState();
}

class _PhotoEditorScreenState extends State<PhotoEditorScreen> {
  late final TextEditingController _title;
  final List<_Photo> _photos = [];
  bool _busy = false;
  String? _error;

  int get _room =>
      PhotoCodec.maxPerKeepsake - widget.otherPhotos - _photos.length;

  @override
  void initState() {
    super.initState();
    final c = widget.section.content;
    _title = TextEditingController(text: c['title'] as String? ?? '');
    for (final e in (c['photos'] as List?) ?? const []) {
      final m = Map<String, dynamic>.from(e as Map);
      final data = m['data'] as String?;
      if (data == null) continue;
      _photos.add(
        _Photo(
          id: m['id'] as String? ?? const Uuid().v4(),
          data: data,
          caption: m['caption'] as String? ?? '',
        ),
      );
    }
  }

  @override
  void dispose() {
    _title.dispose();
    for (final p in _photos) {
      p.caption.dispose();
    }
    super.dispose();
  }

  Future<void> _add() async {
    if (_room <= 0) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final room = _room;
    try {
      final picked = await ImagePicker().pickMultiImage(
        limit: room > 1 ? room : null,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      var skipped = picked.length > room ? 1 : 0;
      for (final file in picked.take(room)) {
        final encoded = await PhotoCodec.encode(await file.readAsBytes());
        if (encoded == null) {
          skipped++;
          continue;
        }
        if (!mounted) return;
        setState(
          () => _photos.add(_Photo(id: const Uuid().v4(), data: encoded)),
        );
      }
      if (skipped > 0 && mounted) {
        setState(
          () => _error =
              "Some photos couldn't be added. A keepsake "
              'holds up to ${PhotoCodec.maxPerKeepsake}.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              "Couldn't open your photos. Check that "
              'Keepsake is allowed to use them.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _remove(int i) {
    setState(() => _photos.removeAt(i).caption.dispose());
  }

  void _save() {
    Navigator.of(context).pop({
      'title': _title.text.trim(),
      'photos': [
        for (final p in _photos)
          {'id': p.id, 'data': p.data, 'caption': p.caption.text.trim()},
      ],
    });
  }

  @override
  Widget build(BuildContext context) {
    final full = _room <= 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Photos')),
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
            if (_photos.isEmpty && !_busy)
              _EmptyPicker(onAdd: _add)
            else
              for (var i = 0; i < _photos.length; i++) ...[
                _PhotoRow(photo: _photos[i], onRemove: () => _remove(i)),
                const SizedBox(height: AppSpacing.sm),
              ],
            if (_busy)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                _error!,
                style: AppTypography.body.copyWith(color: AppColors.error),
              ),
            ],
            if (_photos.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              OutlinedButton.icon(
                onPressed: full || _busy ? null : _add,
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
                label: Text(full ? 'Photo Limit Reached' : 'Add Photos'),
              ),
            ],
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Up to ${PhotoCodec.maxPerKeepsake} photos per keepsake. '
              'They are resized on your phone and location data is removed.',
              style: AppTypography.caption,
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(label: 'Save', onPressed: _busy ? null : _save),
          ],
        ),
      ),
    );
  }
}

class _EmptyPicker extends StatelessWidget {
  const _EmptyPicker({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.card,
        side: BorderSide(color: AppColors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onAdd,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Mascot(size: 96, pose: MascotPose.photo),
              const SizedBox(height: AppSpacing.sm),
              Text('Add a few photos', style: AppTypography.heading),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'They show up as little instant prints, each with a caption.',
                style: AppTypography.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: 'Choose Photos',
                icon: Icons.photo_library_outlined,
                onPressed: onAdd,
                expand: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoRow extends StatelessWidget {
  const _PhotoRow({required this.photo, required this.onRemove});

  final _Photo photo;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: SizedBox.square(
              dimension: 72,
              child: photo.bytes == null
                  ? const ColoredBox(color: AppColors.surfaceAlt)
                  : Image.memory(photo.bytes!, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: photo.caption,
              maxLength: 80,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Caption (optional)',
                counterText: '',
              ),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            tooltip: 'Remove photo',
            icon: const Icon(Icons.close, color: AppColors.inkFaint),
          ),
        ],
      ),
    );
  }
}
