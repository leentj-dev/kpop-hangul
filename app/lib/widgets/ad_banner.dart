import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../utils/ads.dart';

/// A self-contained banner that loads its own ad and reserves space for it.
class AdBanner extends StatefulWidget {
  final AdSize size;
  const AdBanner({super.key, this.size = AdSize.mediumRectangle});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _ad = BannerAd(
      adUnitId: Ads.bannerUnitId,
      size: widget.size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      height: widget.size.height.toDouble(),
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: _loaded && _ad != null
          ? SizedBox(
              width: _ad!.size.width.toDouble(),
              height: _ad!.size.height.toDouble(),
              child: AdWidget(ad: _ad!),
            )
          : const SizedBox.shrink(),
    );
  }
}

/// Ad wrapped in a bordered card with an "AD" label — the shared look used
/// for both the feed list and the space below the word deck.
class AdCard extends StatelessWidget {
  const AdCard({super.key});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: onSurface.withValues(alpha: 0.1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Text(
              'AD',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: onSurface.withValues(alpha: 0.35),
              ),
            ),
          ),
          const Center(child: AdBanner(size: AdSize.banner)),
        ],
      ),
    );
  }
}
