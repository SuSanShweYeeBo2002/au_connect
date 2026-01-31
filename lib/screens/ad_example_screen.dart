import 'package:flutter/material.dart';
import '../widgets/banner_ad_widget.dart';
import '../services/ad_service.dart';

/// Example of how to integrate ads in your screens
///
/// This file demonstrates 3 types of ads:
/// 1. Banner Ads - Small ads at bottom of screen
/// 2. Interstitial Ads - Full-screen ads between content
/// 3. Rewarded Ads - Watch video for rewards

class AdExampleScreen extends StatefulWidget {
  const AdExampleScreen({super.key});

  @override
  State<AdExampleScreen> createState() => _AdExampleScreenState();
}

class _AdExampleScreenState extends State<AdExampleScreen> {
  final AdService _adService = AdService();

  @override
  void initState() {
    super.initState();
    // Pre-load interstitial and rewarded ads
    _adService.loadInterstitialAd();
    _adService.loadRewardedAd();
  }

  @override
  void dispose() {
    _adService.dispose();
    super.dispose();
  }

  void _showInterstitialAd() {
    _adService.showInterstitialAd(context: context);
  }

  void _showRewardedAd() {
    _adService.showRewardedAd(
      onUserEarnedReward: (amount, type) {
        // User watched the ad and earned a reward
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You earned $amount $type!'),
            backgroundColor: Colors.green,
          ),
        );
        // Here you can give the user in-app currency, unlock features, etc.
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ad Integration Example')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Ad Integration Examples',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Banner Ad Example
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '1. Banner Ad',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Banner ads are small rectangular ads shown at top/bottom of screen.\n'
                          'Best for: Continuous visibility without interrupting user experience.',
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Usage in your screens:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(8),
                          color: Colors.grey[200],
                          child: const Text(
                            'Column(\n'
                            '  children: [\n'
                            '    Expanded(child: YourContent()),\n'
                            '    BannerAdWidget(),\n'
                            '  ],\n'
                            ')',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Interstitial Ad Example
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '2. Interstitial Ad',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Full-screen ads shown at natural breaks in your app flow.\n'
                          'Best for: Between levels, after completing tasks, or when navigating.',
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _showInterstitialAd,
                          icon: const Icon(Icons.fullscreen),
                          label: const Text('Show Interstitial Ad'),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Usage:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(8),
                          color: Colors.grey[200],
                          child: const Text(
                            '// Load in initState()\n'
                            'AdService().loadInterstitialAd();\n\n'
                            '// Show when needed\n'
                            'AdService().showInterstitialAd();',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Rewarded Ad Example
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '3. Rewarded Ad',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Video ads that give users rewards for watching.\n'
                          'Best for: Premium features, extra lives, in-app currency.',
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _showRewardedAd,
                          icon: const Icon(Icons.card_giftcard),
                          label: const Text('Watch Ad for Reward'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Usage:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(8),
                          color: Colors.grey[200],
                          child: const Text(
                            '// Load in initState()\n'
                            'AdService().loadRewardedAd();\n\n'
                            '// Show with callback\n'
                            'AdService().showRewardedAd(\n'
                            '  onUserEarnedReward: (amount, type) {\n'
                            '    // Give user rewards\n'
                            '  },\n'
                            ');',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Tips
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.lightbulb, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              'Best Practices',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '• Load ads early (in initState) for better user experience',
                        ),
                        const Text(
                          '• Don\'t show interstitial ads too frequently (max every 60-90 seconds)',
                        ),
                        const Text(
                          '• Place banner ads naturally - bottom of lists or screen',
                        ),
                        const Text(
                          '• Use rewarded ads for optional premium features',
                        ),
                        const Text(
                          '• Test with real devices, not just emulator',
                        ),
                        const Text(
                          '• Replace test IDs with real AdMob IDs before release',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Banner ad at bottom
          const BannerAdWidget(),
        ],
      ),
    );
  }
}
