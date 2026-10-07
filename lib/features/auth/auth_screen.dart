import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/remote/auth_service.dart';
import '../../shared/widgets/brand.dart';
import '../../shared/widgets/primary_button.dart';

/// The creator gate. Recipients never see this; they open share links directly.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _signUp = false;
  bool _obscure = true;
  bool _busy = false;
  String? _error;
  String? _info;

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _validate() {
    final email = _email.text.trim();
    if (!email.contains('@') || !email.contains('.')) {
      return 'Enter a valid email.';
    }
    if (_password.text.length < 6) {
      return 'Password needs at least 6 characters.';
    }
    if (_signUp && _name.text.trim().isEmpty) {
      return 'Add your name so they know who it is from.';
    }
    return null;
  }

  Future<void> _submit() async {
    final problem = _validate();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    final auth = ref.read(authServiceProvider);

    if (_signUp) {
      final res = await auth.signUp(
        email: _email.text,
        password: _password.text,
        displayName: _name.text,
      );
      if (!mounted) return;
      if (!res.ok) {
        setState(() {
          _busy = false;
          _error = res.error ?? 'Could not create your account.';
        });
      } else if (res.needsConfirmation) {
        setState(() {
          _busy = false;
          _signUp = false;
          _info = 'Account created. Check your email to confirm, then sign in.';
        });
      }
      // If a session was created, the router redirect takes it from here.
    } else {
      final error = await auth.signIn(
        email: _email.text,
        password: _password.text,
      );
      if (!mounted) return;
      if (error != null) {
        setState(() {
          _busy = false;
          _error = error;
        });
      }
    }
  }

  Future<void> _forgotPassword() async {
    var target = _email.text.trim();
    if (target.isEmpty) {
      final controller = TextEditingController();
      target = await showDialog<String>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.surface,
              title: Text('Reset your password', style: AppTypography.heading),
              content: TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'you@example.com'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                  child: const Text('Send link'),
                ),
              ],
            ),
          ) ??
          '';
    }
    if (target.isEmpty || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    final err = await ref.read(authServiceProvider).sendPasswordReset(target);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (err != null) {
        _error = err;
      } else {
        _info = 'Password reset link sent. Check your email.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.xxl,
            AppSpacing.gutter,
            AppSpacing.xl,
          ),
          children: [
            const Wordmark(height: 30),
            const SizedBox(height: AppSpacing.xl),
            Text(
              _signUp ? 'Create your account' : 'Welcome back',
              style: AppTypography.display,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _signUp
                  ? 'So your keepsakes are saved and only yours.'
                  : 'Sign in to pick up where you left off.',
              style: AppTypography.bodyLarge.copyWith(color: AppColors.inkSoft),
            ),
            const SizedBox(height: AppSpacing.xl),

            if (_signUp) ...[
              _Field(
                label: 'Your name',
                controller: _name,
                hint: 'Kyle',
                textCapitalization: TextCapitalization.words,
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            _Field(
              label: 'Email',
              controller: _email,
              hint: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: AppSpacing.lg),
            _Field(
              label: 'Password',
              controller: _password,
              hint: 'At least 6 characters',
              obscure: _obscure,
              onToggleObscure: () => setState(() => _obscure = !_obscure),
            ),
            if (!_signUp)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _busy ? null : _forgotPassword,
                  child: const Text('Forgot password?'),
                ),
              ),

            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              _Banner(text: _error!, color: AppColors.error),
            ],
            if (_info != null) ...[
              const SizedBox(height: AppSpacing.md),
              _Banner(text: _info!, color: AppColors.accent),
            ],

            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: _signUp ? 'Create account' : 'Sign in',
              loading: _busy,
              onPressed: _submit,
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                          _signUp = !_signUp;
                          _error = null;
                          _info = null;
                        }),
                child: Text(
                  _signUp
                      ? 'Already have an account? Sign in'
                      : "New here? Create an account",
                ),
              ),
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
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.obscure = false,
    this.onToggleObscure,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool obscure;
  final VoidCallback? onToggleObscure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.label),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: onToggleObscure == null
                ? null
                : IconButton(
                    onPressed: onToggleObscure,
                    icon: Icon(
                      obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppColors.inkFaint,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: AppTypography.body.copyWith(color: AppColors.ink),
      ),
    );
  }
}
