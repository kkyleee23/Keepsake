import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/remote/auth_service.dart';
import '../../shared/widgets/primary_button.dart';

/// Edit the signed-in creator's display name (shown on keepsake covers).
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _name;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
      text: ref.read(authServiceProvider).displayName ?? '',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Add a name.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await ref.read(authServiceProvider).updateDisplayName(_name.text);
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _busy = false;
        _error = err;
      });
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.read(authServiceProvider).email ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.md,
            AppSpacing.gutter,
            AppSpacing.xxl,
          ),
          children: [
            Text('Your name', style: AppTypography.label),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'Kyle'),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'This is how you appear on a keepsake cover, "Made for you by ...".',
              style: AppTypography.caption,
            ),
            if (email.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text('Email', style: AppTypography.label),
              const SizedBox(height: AppSpacing.xs),
              Text(email, style: AppTypography.bodyLarge),
            ],
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_error!,
                  style: AppTypography.body.copyWith(color: AppColors.error)),
            ],
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(label: 'Save', loading: _busy, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
