import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';
import 'web_banner_ad.dart';

/// Universal banner ad widget that works on both mobile and web
/// - On mobile (Android/iOS): Shows Google AdMob ads
/// - On web: Shows Google AdSense ads
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _loadBannerAd();
    }
  }

  void _loadBannerAd() {
    _bannerAd = AdService().createBannerAd()
      ..load()
          .then((_) {
            setState(() {
              _isAdLoaded = true;
            });
          })
          .catchError((error) {
            print('Failed to load banner ad: $error');
          });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Web platform - use AdSense
    if (kIsWeb) {
      return const ResponsiveWebBannerAd();
    }

    // Mobile platform - use AdMob
    if (!_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
