import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepsake/core/theme/app_theme.dart';
import 'package:keepsake/features/creation/create_screen.dart';

void main() {
  testWidgets('Create screen offers occasions to start from', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const CreateScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('What is this for?'), findsOneWidget);
    expect(find.text('Birthday'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
