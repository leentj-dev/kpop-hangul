import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/remote_config.dart';
import '../utils/ads.dart';

/// A native AdMob ad rendered with a platform template, styled to blend into
/// the app's dark card UI. Auto-refreshes and hides entirely when ads are
/// disabled via Remote Config. Used both in the song feed and under the
/// word deck so the ad reads like part of the content, not a banner.
class NativeAdCard extends StatefulWidget {
  final TemplateType templateType;
  final Duration refreshInterval;
  const NativeAdCard({
    super.key,
    this.templateType = TemplateType.small,
    this.refreshInterval = const Duration(seconds: 60),
  });

  @override
  State<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends State<NativeAdCard> {
  NativeAd? _ad;
  bool _loaded = false;
  Timer? _refreshTimer;

  double get _height =>
      widget.templateType == TemplateType.medium ? 340 : 110;

  NativeTemplateStyle get _style => NativeTemplateStyle(
        templateType: widget.templateType,
        mainBackgroundColor: const Color(0xFF14101B),
        cornerRadius: 14,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: const Color(0xFF7C3AED),
          size: 14,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: const Color(0xFF14101B),
          size: 15,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFFA79FB8),
          backgroundColor: const Color(0xFF14101B),
          size: 13,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFF7C7490),
          backgroundColor: const Color(0xFF14101B),
          size: 12,
        ),
      );

  @override
  void initState() {
    super.initState();
    _loadAd();
    _refreshTimer =
        Timer.periodic(widget.refreshInterval, (_) => _loadAd());
  }

  void _loadAd() {
    NativeAd(
      adUnitId: Ads.nativeUnitId,
      request: const AdRequest(),
      nativeTemplateStyle: _style,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          final old = _ad;
          setState(() {
            _ad = ad as NativeAd;
            _loaded = true;
          });
          old?.dispose();
        },
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    ).load();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: adsEnabledNotifier,
      builder: (context, enabled, _) {
        if (!enabled || !_loaded || _ad == null) {
          return const SizedBox.shrink();
        }
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          height: _height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF251E30)),
          ),
          clipBehavior: Clip.antiAlias,
          child: AdWidget(ad: _ad!),
        );
      },
    );
  }
}
