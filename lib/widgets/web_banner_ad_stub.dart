import 'package:flutter/material.dart';

/// Stub for WebBannerAd on non-web platforms
/// This widget does nothing on mobile - ads are handled by AdMob
class WebBannerAd extends StatelessWidget {
  final String? adSlot;
  final double width;
  final double height;

  const WebBannerAd({
    super.key,
    this.adSlot,
    this.width = 728,
    this.height = 90,
  });

  @override
  Widget build(BuildContext context) {
    // Return empty container on mobile platforms
    return const SizedBox.shrink();
  }
}
