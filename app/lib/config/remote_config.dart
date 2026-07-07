import 'dart:io';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Whether ads should be shown. Driven by the Firebase Remote Config key
/// `ads_enabled`; defaults to true so ads still show if Remote Config is
/// unreachable. UI widgets listen to this and hide ad slots when it's false.
final adsEnabledNotifier = ValueNotifier<bool>(true);

/// How many songs appear between feed ads. Driven by `feed_ad_interval`.
final feedAdIntervalNotifier = ValueNotifier<int>(8);

const _adsEnabledKey = 'ads_enabled';
const _feedAdIntervalKey = 'feed_ad_interval';
const _nativeUnitAndroidKey = 'native_ad_unit_android';
const _nativeUnitIosKey = 'native_ad_unit_ios';

// Remote-overridable native ad unit IDs (empty = use the built-in test id).
// NOTE: only the ad *unit* IDs are remote-configurable. The AdMob *App ID*
// is read from AndroidManifest/Info.plist at startup and needs a rebuild.
String _nativeUnitAndroid = '';
String _nativeUnitIos = '';

/// The remote-config override for the native ad unit id, or null to fall
/// back to the built-in test id.
String? nativeAdUnitOverride() {
  final v = Platform.isIOS ? _nativeUnitIos : _nativeUnitAndroid;
  return v.isEmpty ? null : v;
}

/// Fetch + activate Remote Config, then publish the ad flag. Never throws —
/// on any failure the app keeps the current (default) value.
Future<void> initRemoteConfig() async {
  try {
    final rc = FirebaseRemoteConfig.instance;
    await rc.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(hours: 1),
    ));
    await rc.setDefaults(const {
      _adsEnabledKey: true,
      _feedAdIntervalKey: 8,
      _nativeUnitAndroidKey: '',
      _nativeUnitIosKey: '',
    });
    await rc.fetchAndActivate();
    _publish(rc);

    // Pick up changes pushed while the app is open.
    rc.onConfigUpdated.listen((event) async {
      await rc.activate();
      _publish(rc);
    });
  } on Exception {
    // Keep the defaults.
  }
}

void _publish(FirebaseRemoteConfig rc) {
  adsEnabledNotifier.value = rc.getBool(_adsEnabledKey);
  final interval = rc.getInt(_feedAdIntervalKey);
  // Guard against a bad/zero value making every row an ad.
  feedAdIntervalNotifier.value = interval >= 2 ? interval : 8;
  _nativeUnitAndroid = rc.getString(_nativeUnitAndroidKey);
  _nativeUnitIos = rc.getString(_nativeUnitIosKey);
}
