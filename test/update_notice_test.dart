import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepsake/data/providers.dart';
import 'package:keepsake/data/remote/update_check.dart';
import 'package:keepsake/features/update/update_notice.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> show(WidgetTester t, Widget child, UpdateInfo info) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        updateInfoProvider.overrideWith((ref) async => info),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );
  await t.pumpAndSettle();
}

const newer = UpdateInfo(
  urgency: UpdateUrgency.optional,
  versionName: '1.0.4',
  note: 'A newer Keepsake is ready.',
  url: 'https://keepsake-ph.vercel.app/download',
);

const tooOld = UpdateInfo(
  urgency: UpdateUrgency.required_,
  versionName: '2.0.0',
  note: 'This one is too old to keep going.',
  url: 'https://keepsake-ph.vercel.app/download',
);

void main() {
  group('the card on Home', () {
    testWidgets('says nothing when there is nothing to say', (t) async {
      await show(t, const UpdateNotice(), UpdateInfo.none);
      expect(find.byType(Card), findsNothing);
      expect(find.text('Get It'), findsNothing);
    });

    testWidgets('offers the newer one, and a way out', (t) async {
      await show(t, const UpdateNotice(), newer);
      expect(find.text('A newer Keepsake is ready'), findsOneWidget);
      expect(find.text('Get It'), findsOneWidget);
      expect(find.text('Not Now'), findsOneWidget);
    });

    testWidgets('put away once, and it stays away', (t) async {
      await show(t, const UpdateNotice(), newer);
      await t.tap(find.text('Not Now'));
      await t.pumpAndSettle();
      expect(find.text('Get It'), findsNothing);
    });

    testWidgets('leaves the blocking one to the gate', (t) async {
      await show(t, const UpdateNotice(), tooOld);
      expect(find.text('Get It'), findsNothing);
    });
  });

  group('the gate in front of everything', () {
    testWidgets('stays out of the way normally', (t) async {
      await show(t, const UpdateGate(child: Text('the app')), UpdateInfo.none);
      expect(find.text('the app'), findsOneWidget);
    });

    testWidgets('a newer build alone does not block anyone', (t) async {
      await show(t, const UpdateGate(child: Text('the app')), newer);
      expect(find.text('the app'), findsOneWidget);
    });

    testWidgets('a build that is too old cannot be used', (t) async {
      await show(t, const UpdateGate(child: Text('the app')), tooOld);
      expect(find.text('the app'), findsNothing);
      expect(find.text('Time for the new Keepsake'), findsOneWidget);
      expect(find.text('Get the New Version'), findsOneWidget);
      // No way past it, on purpose.
      expect(find.text('Not Now'), findsNothing);
      // And it says what happens to their work.
      expect(find.textContaining('drafts stay'), findsOneWidget);
    });
  });
}
