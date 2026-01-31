import 'package:flutter/material.dart';
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;

/// Web-specific interstitial ad using AdSense
/// Shows a full-screen overlay ad on web
class WebInterstitialAd {
  static bool _isShowing = false;

  /// Show a full-screen interstitial ad on web
  static void show(BuildContext context) {
    if (_isShowing) return;
    _isShowing = true;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const _WebInterstitialAdDialog(),
    ).then((_) {
      _isShowing = false;
    });
  }
}

class _WebInterstitialAdDialog extends StatefulWidget {
  const _WebInterstitialAdDialog();

  @override
  State<_WebInterstitialAdDialog> createState() =>
      _WebInterstitialAdDialogState();
}

class _WebInterstitialAdDialogState extends State<_WebInterstitialAdDialog> {
  final String viewType =
      'adsense-interstitial-${DateTime.now().millisecondsSinceEpoch}';
  int _countdown = 5;

  @override
  void initState() {
    super.initState();
    _registerAdWidget();
    _startCountdown();
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && _countdown > 0) {
        setState(() => _countdown--);
        return true;
      }
      return false;
    });
  }

  void _registerAdWidget() {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final adContainer = html.DivElement()
        ..style.width = '100%'
        ..style.height = '600px'
        ..style.display = 'flex'
        ..style.justifyContent = 'center'
        ..style.alignItems = 'center';

      // Large rectangle ad (336x280) or other interstitial format
      final adElement = html.Element.html('''
          <ins class="adsbygoogle"
               style="display:inline-block;width:336px;height:280px"
               data-ad-client="ca-pub-3940256099942544"
               data-ad-slot="1234567890"></ins>
        ''');

      adContainer.append(adElement);

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
    return Dialog(
      backgroundColor: Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close button (enabled after countdown)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Advertisement',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                _countdown > 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Close in $_countdown',
                          style: const TextStyle(fontSize: 14),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Close',
                      ),
              ],
            ),
            const SizedBox(height: 20),
            // Ad container
            Flexible(
              child: SizedBox(
                width: 336,
                height: 600,
                child: HtmlElementView(viewType: viewType),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
