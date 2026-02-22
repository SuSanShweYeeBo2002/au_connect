import 'package:flutter/material.dart';

/// Stub for WebInterstitialAd on non-web platforms
/// This does nothing on mobile - ads are handled by AdMob
class WebInterstitialAd {
  static void show(BuildContext? context) {
    // Do nothing on mobile platforms
    print('WebInterstitialAd.show() called on mobile - using AdMob instead');
  }
}

/// Stub widget version for consistency
class WebInterstitialAdWidget extends StatelessWidget {
  const WebInterstitialAdWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
