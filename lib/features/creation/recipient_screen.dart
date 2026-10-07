import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/enums.dart';
import '../keepsakes/application/keepsakes_controller.dart';
import '../../shared/widgets/primary_button.dart';
import 'keepsake_factory.dart';

/// Second step: who it's for. Creates the draft and hands off to the editor.
class RecipientScreen extends ConsumerStatefulWidget {
  const RecipientScreen({super.key, required this.occasion});

  final Occasion occasion;

  @override
  ConsumerState<RecipientScreen> createState() => _RecipientScreenState();
}

class _RecipientScreenState extends ConsumerState<RecipientScreen> {
  final _recipient = TextEditingController();
  final _sender = TextEditingController();
  final _note = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _recipient.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _recipient.dispose();
    _sender.dispose();
    _note.dispose();
    super.dispose();
  }

  bool get _canStart => _recipient.text.trim().isNotEmpty;

  Future<void> _start() async {
    if (!_canStart) return;
    setState(() => _saving = true);

    final draft = KeepsakeFactory.newDraft(occasion: widget.occasion).copyWith(
      recipientName: _recipient.text.trim(),
      senderName: _sender.text.trim(),
      coverNote: _note.text.trim().isEmpty ? null : _note.text.trim(),
    );
    await ref.read(keepsakesControllerProvider.notifier).upsert(draft);

    if (!mounted) return;
    context.pushReplacement('/editor/${draft.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.occasion.label} keepsake')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.md,
            AppSpacing.gutter,
            AppSpacing.xxl,
          ),
          children: [
            Text("Who's it for?", style: AppTypography.displaySmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Just a name to start. You can change any of this later.',
              style: AppTypography.bodyLarge.copyWith(color: AppColors.inkSoft),
            ),
            const SizedBox(height: AppSpacing.xl),

            _Field(
              label: "Their name",
              controller: _recipient,
              hint: 'Jamie',
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.lg),
            _Field(
              label: 'Your name (Optional)',
              controller: _sender,
              hint: 'Kyle',
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.lg),
            _Field(
              label: 'A line for the cover (Optional)',
              controller: _note,
              hint: 'A little something for your birthday.',
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Start',
              loading: _saving,
              onPressed: _canStart ? _start : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.maxLines = 1,
    this.textInputAction,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.label),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller,
          maxLines: maxLines,
          textInputAction: textInputAction,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}
