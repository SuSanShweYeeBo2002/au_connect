import 'package:flutter/material.dart';
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;

/// Web-specific banner ad widget using Adcash
class WebBannerAd extends StatefulWidget {
  final double width;
  final double height;

  const WebBannerAd({super.key, this.width = 300, this.height = 250});

  @override
  State<WebBannerAd> createState() => _WebBannerAdState();
}

class _WebBannerAdState extends State<WebBannerAd> {
  final String viewType =
      'adcash-banner-${DateTime.now().millisecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    _registerAdWidget();
  }

  void _registerAdWidget() {
    // Register the view factory for the ad
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final adContainer = html.DivElement()
        ..id = 'adcash-container-$viewId'
        ..style.width = '${widget.width}px'
        ..style.height = '${widget.height}px'
        ..style.border = '0'
        ..style.display = 'block'
        ..style.overflow = 'hidden';

      // Create container div for banner
      final bannerDiv = html.DivElement()..id = 'adcash-banner-$viewId';
      adContainer.append(bannerDiv);

      // Load Adcash library and run banner
      Future.delayed(const Duration(milliseconds: 500), () {
        try {
          // Load aclib.js
          final aclibScript = html.ScriptElement()
            ..id = 'aclib'
            ..type = 'text/javascript'
            ..src = '//acdcdn.com/script/aclib.js';

          // Only add if not already added
          if (html.document.getElementById('aclib') == null) {
            html.document.head!.append(aclibScript);
          }

          // Run Banner after library loads
          Future.delayed(const Duration(milliseconds: 800), () {
            final bannerScript = html.ScriptElement()
              ..type = 'text/javascript'
              ..text = '''
                try {
                  if (typeof aclib !== 'undefined') {
                    aclib.runBanner({
                      zoneId: '11025390'
                    });
                    console.log('Adcash Banner loaded for zone 11025390');
                  } else {
                    console.error('aclib not loaded');
                  }
                } catch (e) {
                  console.error('Adcash Banner error:', e);
                }
              ''';
            bannerDiv.append(bannerScript);
          });
        } catch (e) {
          print('Adcash setup error: $e');
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
                  'Powered by Adcash',
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
