import 'package:flutter/material.dart';

import 'target_language.dart';

/// Per-flavor configuration. The engine (feed, player, word cards, ads,
/// remote updates) is shared; only these values change between apps.
class AppConfig {
  final String appTitle;
  final String logoAsset;
  final Color seedColor;

  /// Base URL for the song manifest + files (GitHub raw, no backend).
  final String remoteBase;

  /// The language being learned.
  final TargetLanguage target;

  const AppConfig({
    required this.appTitle,
    required this.logoAsset,
    required this.seedColor,
    required this.remoteBase,
    required this.target,
  });
}

/// Set once by the flavor entrypoint (main*.dart) before runApp().
late AppConfig appConfig;

/// K-pop → Korean (the original, live app).
const kpopConfig = AppConfig(
  appTitle: 'K-pop Hangul',
  logoAsset: 'assets/icon/icon.png',
  seedColor: Color(0xFFF0ABFC),
  remoteBase:
      'https://raw.githubusercontent.com/leentj-dev/kpop-hangul/main/app/assets/songs',
  target: KoreanTarget(),
);

/// J-pop → Japanese (future flavor; content pack TBD).
const jpopConfig = AppConfig(
  appTitle: 'J-pop Kana',
  logoAsset: 'assets/icon/icon.png',
  seedColor: Color(0xFFF9A8D4),
  remoteBase:
      'https://raw.githubusercontent.com/leentj-dev/kpop-hangul/main/app/assets/songs',
  target: JapaneseTarget(),
);

/// Latin → Spanish (future flavor; content pack TBD).
const esConfig = AppConfig(
  appTitle: 'Latin Español',
  logoAsset: 'assets/icon/icon.png',
  seedColor: Color(0xFFFCD34D),
  remoteBase:
      'https://raw.githubusercontent.com/leentj-dev/kpop-hangul/main/app/assets/songs',
  target: RomanTarget('es-ES'),
);
