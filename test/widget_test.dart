import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sincerelysea/data/local_store.dart';
import 'package:sincerelysea/main.dart';

Future<void> _boot(WidgetTester tester, LocalAppStore store) async {
  store.markSplashSeen();
  store.completeOnboarding();
  await tester.pumpWidget(
    SincerelySeaApp(store: store, splashDuration: Duration.zero),
  );
  await tester.pump();
}

void main() {
  testWidgets('splash yields to onboarding', (tester) async {
    final store = LocalAppStore();
    await tester.pumpWidget(
      SincerelySeaApp(
        store: store,
        splashDuration: const Duration(milliseconds: 20),
      ),
    );
    expect(find.text('Stories in every stitch'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 30));
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('SincerelySea Community'), findsOneWidget);
  });

  testWidgets('skip opens the home feed with a short caption', (tester) async {
    final store = LocalAppStore();
    store.markSplashSeen();
    await tester.pumpWidget(
      SincerelySeaApp(store: store, splashDuration: Duration.zero),
    );
    await tester.pump();
    await tester.tap(find.text('Skip'));
    await tester.pump();
    expect(find.text('Jane, on the...read more'), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
  });

  testWidgets('home fits a narrow phone', (tester) async {
    final store = LocalAppStore();
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _boot(tester, store);
    expect(tester.takeException(), isNull);
    expect(find.text('Jane, on the...read more'), findsOneWidget);
  });

  testWidgets('preview account reaches a verified collection', (tester) async {
    final store = LocalAppStore();
    await _boot(tester, store);
    await tester.tap(find.text('Profile'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('sign-in-cta')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('email')),
      LocalAppStore.fixtureEmail,
    );
    await tester.enterText(
      find.byKey(const Key('password')),
      LocalAppStore.fixturePassword,
    );
    await tester.tap(find.byKey(const Key('sign-in')));
    await tester.pumpAndSettle();
    expect(find.text('Ayu Putri'), findsOneWidget);
    await tester.tap(find.text('Collection'));
    await tester.pumpAndSettle();
    expect(find.text('Jane Medium'), findsWidgets);
    expect(find.textContaining('Verified'), findsWidgets);
  });
}
