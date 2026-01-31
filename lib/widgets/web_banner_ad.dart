import 'package:flutter/material.dart';
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
import '../config/ad_config.dart';

/// Web-specific banner ad widget using Google AdSense
/// This widget creates an AdSense ad unit for Flutter web
class WebBannerAd extends StatefulWidget {
  final String? adSlot;
  final double width;
  final double height;

  const WebBannerAd({
    super.key,
    this.adSlot, // Uses AdConfig if not provided
    this.width = 728,
    this.height = 90,
  });

  @override
  State<WebBannerAd> createState() => _WebBannerAdState();
}

class _WebBannerAdState extends State<WebBannerAd> {
  final String viewType =
      'adsense-banner-${DateTime.now().millisecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    _registerAdWidget();
  }

  void _registerAdWidget() {
    // Register the view factory for the ad
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final adContainer = html.DivElement()
        ..style.width = '${widget.width}px'
        ..style.height = '${widget.height}px'
        ..style.border = '0';

      // Create the INS element programmatically (bypasses Flutter's HTML sanitizer)
      final adElement = html.Element.tag('ins')
        ..className = 'adsbygoogle'
        ..setAttribute('data-ad-client', AdConfig.webPublisherId)
        ..setAttribute('data-ad-slot', widget.adSlot ?? AdConfig.webAdSlot)
        ..style.display = 'inline-block'
        ..style.width = '${widget.width}px'
        ..style.height = '${widget.height}px';

      adContainer.append(adElement);

      // Push ad after a short delay to ensure it's in the DOM
      Future.delayed(const Duration(milliseconds: 100), () {
        try {
          // Trigger AdSense ad loading
          final script = html.ScriptElement()
            ..text = '(adsbygoogle = window.adsbygoogle || []).push({});';
          adContainer.append(script);
        } catch (e) {
          print('AdSense error: $e');
        }
      });

      return adContainer;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border.all(color: Colors.grey[400]!, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          // Placeholder/Loading indicator
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.ads_click, size: 40, color: Colors.grey[400]),
                SizedBox(height: 8),
                Text(
                  'Advertisement',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                SizedBox(height: 4),
                Text(
                  'Loading...',
                  style: TextStyle(color: Colors.grey[500], fontSize: 10),
                ),
              ],
            ),
          ),
          // Actual ad
          HtmlElementView(viewType: viewType),
        ],
      ),
    );
  }
}

/// Responsive web banner ad that adjusts to screen size
class ResponsiveWebBannerAd extends StatelessWidget {
  const ResponsiveWebBannerAd({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Choose ad size based on screen width
    if (screenWidth >= 970) {
      // Large leaderboard (970x90)
      return const WebBannerAd(width: 970, height: 90);
    } else if (screenWidth >= 728) {
      // Leaderboard (728x90)
      return const WebBannerAd(width: 728, height: 90);
    } else if (screenWidth >= 468) {
      // Banner (468x60)
      return const WebBannerAd(width: 468, height: 60);
    } else {
      // Mobile banner (320x50)
      return const WebBannerAd(width: 320, height: 50);
    }
  }
}
