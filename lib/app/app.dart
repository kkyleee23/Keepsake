import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import 'router.dart';

class KeepsakeApp extends ConsumerWidget {
  const KeepsakeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Keepsake',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      // Keep the phone-first layout centered in a readable column on wide
      // screens (desktop, tablet), instead of stretching edge to edge.
      builder: (context, child) {
        return ColoredBox(
          color: AppColors.paper,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}
