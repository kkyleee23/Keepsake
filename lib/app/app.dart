import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import 'router.dart';
import '../shared/widgets/gift_art.dart';
import '../shared/widgets/paper.dart';

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
        // Around the column (tablets, desktop) the same stone paper, with a
        // hairline on each side so the column reads as a sheet on a table.
        return DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.paper,
            image: paperImage(PaperTextures.stone),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  border: MediaQuery.sizeOf(context).width > 480
                      ? const Border.symmetric(
                          vertical: BorderSide(color: AppColors.hairline),
                        )
                      : null,
                ),
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }
}
