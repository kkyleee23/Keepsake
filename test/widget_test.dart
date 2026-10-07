import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepsake/app/app.dart';

void main() {
  testWidgets('Home renders the focal headline and create action',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: KeepsakeApp()));
    await tester.pumpAndSettle();

    expect(find.text('Make something\nworth keeping.'), findsOneWidget);
    expect(find.text('Create a Keepsake'), findsOneWidget);
  });
}
