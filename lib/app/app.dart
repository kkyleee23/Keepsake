import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import 'router.dart';

class KeepsakeApp extends StatelessWidget {
  const KeepsakeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Keepsake',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
      // Keep the phone-first layout centered in a readable column on wide
      // screens (desktop web), instead of stretching edge to edge.
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
