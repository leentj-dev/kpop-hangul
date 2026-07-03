import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'config/app_config.dart';
import 'config/theme_controller.dart';
import 'screens/feed_screen.dart';

/// Shared entrypoint used by every flavor. Set [appConfig] first, then call.
void bootstrap(AppConfig config) {
  appConfig = config;
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  loadThemeMode();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  ThemeData _theme(Brightness brightness) => ThemeData(
        brightness: brightness,
        scaffoldBackgroundColor:
            brightness == Brightness.dark ? Colors.black : Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: appConfig.seedColor,
          brightness: brightness,
        ),
        useMaterial3: true,
      );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) => MaterialApp(
        title: appConfig.appTitle,
        debugShowCheckedModeBanner: false,
        themeMode: mode,
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        home: const FeedScreen(),
      ),
    );
  }
}
