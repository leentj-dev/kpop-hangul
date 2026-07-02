import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'screens/feed_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(const KpopHangulApp());
}

class KpopHangulApp extends StatelessWidget {
  const KpopHangulApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'K-pop Hangul',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF0ABFC),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const FeedScreen(),
    );
  }
}
