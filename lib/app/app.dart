import 'package:flutter/material.dart';

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
    );
  }
}
