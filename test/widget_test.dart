import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepsake/app/app.dart';
import 'package:keepsake/data/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Home renders the focal headline and create action',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const KeepsakeApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Make something\nworth keeping.'), findsOneWidget);
    expect(find.text('Create a Keepsake'), findsOneWidget);
  });
}
