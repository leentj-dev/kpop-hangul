import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'config/app_config.dart';
import 'screens/feed_screen.dart';

/// Shared entrypoint used by every flavor. Set [appConfig] first, then call.
void bootstrap(AppConfig config) {
  appConfig = config;
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appConfig.appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: appConfig.seedColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const FeedScreen(),
    );
  }
}
