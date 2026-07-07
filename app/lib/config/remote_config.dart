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

/// Fetch + activate Remote Config, then publish the ad flag. Never throws —
/// on any failure the app keeps the current (default) value.
Future<void> initRemoteConfig() async {
  try {
    final rc = FirebaseRemoteConfig.instance;
    await rc.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(hours: 1),
    ));
    await rc.setDefaults(const {_adsEnabledKey: true, _feedAdIntervalKey: 8});
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
}
