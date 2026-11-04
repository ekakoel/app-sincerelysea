import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/sincerely_sea_app.dart';
import 'data/local_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final store = LocalAppStore(
    persistence: PreferencesSnapshotPersistence(preferences),
  );
  await store.restore();
  if (!store.restored) {
    store.onboardingComplete =
        preferences.getBool('onboarding_complete') ?? false;
    store.darkMode = preferences.getBool('dark_mode') ?? false;
  }
  store.addListener(() {
    preferences.setBool('onboarding_complete', store.onboardingComplete);
    preferences.setBool('dark_mode', store.darkMode);
  });
  runApp(SincerelySeaApp(store: store));
}

class SincerelySeaApp extends StatelessWidget {
  const SincerelySeaApp({
    super.key,
    required this.store,
    this.splashDuration = const Duration(milliseconds: 1200),
  });

  final LocalAppStore store;
  final Duration splashDuration;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: store,
      child: Consumer<LocalAppStore>(
        builder: (context, store, _) {
          return MaterialApp(
            title: 'SincerelySea',
            debugShowCheckedModeBanner: false,
            theme: AppThemeBridge.light,
            darkTheme: AppThemeBridge.dark,
            themeMode: store.darkMode ? ThemeMode.dark : ThemeMode.light,
            home: AppGate(splashDuration: splashDuration),
          );
        },
      ),
    );
  }
}

class PreferencesSnapshotPersistence implements SnapshotPersistence {
  PreferencesSnapshotPersistence(this.preferences);

  final SharedPreferences preferences;
  static const key = 'local_snapshot_v1';

  @override
  Future<String?> load() async => preferences.getString(key);

  @override
  void save(String raw) {
    preferences.setString(key, raw);
  }
}
