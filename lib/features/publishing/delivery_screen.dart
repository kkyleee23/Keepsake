import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/enums.dart';
import '../../data/models/keepsake.dart';
import '../../data/providers.dart';
import '../keepsakes/application/keepsakes_controller.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/primary_button.dart';

/// Choose how and when a keepsake opens, then publish it.
class DeliveryScreen extends ConsumerStatefulWidget {
  const DeliveryScreen({super.key, required this.keepsakeId});

  final String keepsakeId;

  @override
  ConsumerState<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends ConsumerState<DeliveryScreen> {
  Keepsake? _keepsake;
  bool _loading = true;
  bool _publishing = false;

  DeliveryMode _mode = DeliveryMode.immediately;
  DateTime? _openAt;
  bool _usePin = false;
  final _pin = TextEditingController();
  bool _useExpiry = false;
  DateTime? _expiresAt;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final k =
        await ref.read(keepsakeRepositoryProvider).getById(widget.keepsakeId);
    if (!mounted) return;
    setState(() {
      _keepsake = k;
      _mode = k?.delivery.mode ?? DeliveryMode.immediately;
      _openAt = k?.delivery.openAt;
      _expiresAt = k?.privacy.expiresAt;
      _useExpiry = _expiresAt != null;
      _loading = false;
    });
  }

  bool get _valid {
    if (_mode == DeliveryMode.scheduled && _openAt == null) return false;
    if (_usePin && _pin.text.trim().length < 4) return false;
    if (_useExpiry && _expiresAt == null) return false;
    return true;
  }

  Future<DateTime?> _pickDateTime(DateTime? initial) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: DateTime(now.year + 50),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial ?? now),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _publish() async {
    final k = _keepsake;
    if (k == null || !_valid) return;
    final backend = ref.read(keepsakeBackendProvider);
    if (!backend.isAvailable) return;

    setState(() => _publishing = true);
    try {
      final updated = k.copyWith(
        delivery: DeliverySettings(mode: _mode, openAt: _openAt),
        privacy: k.privacy.copyWith(unlisted: true, expiresAt: _expiresAt),
      );
      final pin = _usePin ? _pin.text.trim() : null;
      final token = await backend.publish(updated, pin: pin);

      // Persist locally as published - without the PIN (server holds the hash).
      final local = updated.copyWith(
        status: KeepsakeStatus.published,
        shareToken: token,
        publishedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await ref.read(keepsakesControllerProvider.notifier).upsert(local);

      if (!mounted) return;
      context.pushReplacement('/published/${k.id}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _publishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't publish. $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final k = _keepsake;
    if (k == null) {
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

    final backendReady = ref.read(keepsakeBackendProvider).isAvailable;

    return Scaffold(
      appBar: AppBar(title: const Text('Deliver')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.md,
            AppSpacing.gutter,
            AppSpacing.xxl,
          ),
          children: [
            Text('When should it open?', style: AppTypography.displaySmall),
            const SizedBox(height: AppSpacing.lg),
            _Choice(
              label: 'Open immediately',
              selected: _mode == DeliveryMode.immediately,
              onTap: () => setState(() => _mode = DeliveryMode.immediately),
            ),
            _Choice(
              label: 'Open at a date & time',
              selected: _mode == DeliveryMode.scheduled,
              onTap: () => setState(() => _mode = DeliveryMode.scheduled),
            ),
            if (_mode == DeliveryMode.scheduled) ...[
              const SizedBox(height: AppSpacing.xs),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await _pickDateTime(_openAt);
                  if (picked != null) setState(() => _openAt = picked);
                },
                icon: const Icon(Icons.event_outlined, size: 20),
                label: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(_openAt == null
                      ? 'Pick a date & time'
                      : DateFormat.yMMMMd().add_jm().format(_openAt!)),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xl),
            Text('Privacy', style: AppTypography.heading),
            const SizedBox(height: AppSpacing.sm),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              // ignore: deprecated_member_use
              activeColor: AppColors.accent,
              title: Text('Require a PIN', style: AppTypography.bodyLarge),
              subtitle: Text('They enter it to open.',
                  style: AppTypography.caption),
              value: _usePin,
              onChanged: (v) => setState(() => _usePin = v),
            ),
            if (_usePin)
              TextField(
                controller: _pin,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: '4–6 digits',
                  counterText: '',
                ),
              ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              // ignore: deprecated_member_use
              activeColor: AppColors.accent,
              title: Text('Set an expiry', style: AppTypography.bodyLarge),
              subtitle: Text('The link stops working after this.',
                  style: AppTypography.caption),
              value: _useExpiry,
              onChanged: (v) => setState(() {
                _useExpiry = v;
                if (!v) _expiresAt = null;
              }),
            ),
            if (_useExpiry)
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await _pickDateTime(_expiresAt);
                  if (picked != null) setState(() => _expiresAt = picked);
                },
                icon: const Icon(Icons.timer_off_outlined, size: 20),
                label: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(_expiresAt == null
                      ? 'Pick an expiry'
                      : DateFormat.yMMMMd().add_jm().format(_expiresAt!)),
                ),
              ),

            const SizedBox(height: AppSpacing.xl),
            if (!backendReady)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.card,
                  border: Border.all(color: AppColors.hairline),
                ),
                child: Text(
                  'Sharing isn’t set up yet. Add your Supabase keys to publish '
                  'and send keepsakes.',
                  style: AppTypography.body,
                ),
              )
            else
              PrimaryButton(
                label: 'Publish',
                loading: _publishing,
                onPressed: _valid ? _publish : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: selected ? AppColors.surfaceAlt : AppColors.surface,
        borderRadius: AppRadius.card,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.card,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: AppRadius.card,
              border: Border.all(
                color: selected ? AppColors.accent : AppColors.hairline,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? AppColors.accent : AppColors.inkFaint,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(label, style: AppTypography.bodyLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
