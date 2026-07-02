import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob configuration.
///
/// These are Google's official TEST ad unit IDs — they show test ads and are
/// safe to ship during development. Before release, register the app in AdMob
/// and replace [bannerUnitId] (and the App ID in AndroidManifest.xml /
/// Info.plist) with the real values. Real ads only serve after AdMob approval.
class Ads {
  Ads._();

  static const _testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const _testBannerIos = 'ca-app-pub-3940256099942544/2934735716';

  /// Insert an ad after every N songs in the feed.
  static const feedInterval = 8;

  /// Insert an ad after every N word cards.
  static const cardInterval = 6;

  static String get bannerUnitId =>
      Platform.isIOS ? _testBannerIos : _testBannerAndroid;

  static BannerAd createBanner({AdSize size = AdSize.mediumRectangle}) {
    return BannerAd(
      adUnitId: bannerUnitId,
      size: size,
      request: const AdRequest(),
      listener: const BannerAdListener(),
    );
  }
}
