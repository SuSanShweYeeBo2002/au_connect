import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../widgets/web_interstitial_ad.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // Track last interstitial ad time to prevent spam
  DateTime? _lastInterstitialTime;

  // Test Ad Unit IDs (Replace with your real AdMob IDs in production)
  static const String _androidBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _iosBannerAdUnitId =
      'ca-app-pub-3940256099942544/2934735716';
  static const String _androidInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _iosInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/4411468910';
  static const String _androidRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _iosRewardedAdUnitId =
      'ca-app-pub-3940256099942544/1712485313';

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _isInterstitialAdReady = false;
  bool _isRewardedAdReady = false;

  // Get Banner Ad Unit ID based on platform
  static String get bannerAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) {
      return _androidBannerAdUnitId;
    } else if (Platform.isIOS) {
      return _iosBannerAdUnitId;
    }
    return '';
  }

  // Get Interstitial Ad Unit ID based on platform
  static String get interstitialAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) {
      return _androidInterstitialAdUnitId;
    } else if (Platform.isIOS) {
      return _iosInterstitialAdUnitId;
    }
    return '';
  }

  // Get Rewarded Ad Unit ID based on platform
  static String get rewardedAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) {
      return _androidRewardedAdUnitId;
    } else if (Platform.isIOS) {
      return _iosRewardedAdUnitId;
    }
    return '';
  }

  // Create Banner Ad
  BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('Banner ad loaded');
        },
        onAdFailedToLoad: (ad, error) {
          print('Banner ad failed to load: $error');
          ad.dispose();
        },
      ),
    );
  }

  // Load Interstitial Ad
  void loadInterstitialAd() {
    if (kIsWeb) return;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          print('Interstitial ad loaded');

          // Set up full screen content callback
          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
                onAdDismissedFullScreenContent: (ad) {
                  print('Interstitial ad dismissed');
                  ad.dispose();
                  _isInterstitialAdReady = false;
                  loadInterstitialAd(); // Load next ad
                },
                onAdFailedToShowFullScreenContent: (ad, error) {
                  print('Interstitial ad failed to show: $error');
                  ad.dispose();
                  _isInterstitialAdReady = false;
                  loadInterstitialAd(); // Load next ad
                },
              );
        },
        onAdFailedToLoad: (error) {
          print('Interstitial ad failed to load: $error');
          _isInterstitialAdReady = false;
        },
      ),
    );
  }

  // Show Interstitial Ad (works on both mobile and web)
  void showInterstitialAd({BuildContext? context}) {
    // Rate limiting: Don't show more than once per minute
    if (_lastInterstitialTime != null) {
      final difference = DateTime.now().difference(_lastInterstitialTime!);
      if (difference.inSeconds < 60) {
        print(
          'Interstitial ad rate limited (wait ${60 - difference.inSeconds}s)',
        );
        return;
      }
    }

    if (kIsWeb) {
      // Web platform - show AdSense interstitial
      if (context != null) {
        WebInterstitialAd.show(context);
        _lastInterstitialTime = DateTime.now();
      } else {
        print('Context required for web interstitial ads');
      }
    } else {
      // Mobile platform - show AdMob interstitial
      if (_isInterstitialAdReady && _interstitialAd != null) {
        _interstitialAd!.show();
        _lastInterstitialTime = DateTime.now();
      } else {
        print('Interstitial ad not ready');
        loadInterstitialAd(); // Try loading again
      }
    }
  }

  // Load Rewarded Ad
  void loadRewardedAd() {
    if (kIsWeb) return;

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdReady = true;
          print('Rewarded ad loaded');

          // Set up full screen content callback
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              print('Rewarded ad dismissed');
              ad.dispose();
              _isRewardedAdReady = false;
              loadRewardedAd(); // Load next ad
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('Rewarded ad failed to show: $error');
              ad.dispose();
              _isRewardedAdReady = false;
              loadRewardedAd(); // Load next ad
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('Rewarded ad failed to load: $error');
          _isRewardedAdReady = false;
        },
      ),
    );
  }

  // Show Rewarded Ad (mobile only - not commonly supported on web)
  void showRewardedAd({
    required Function(int amount, String type) onUserEarnedReward,
  }) {
    if (kIsWeb) {
      print('Rewarded ads not available on web platform');
      return;
    }

    if (_isRewardedAdReady && _rewardedAd != null) {
      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          print('User earned reward: ${reward.amount} ${reward.type}');
          onUserEarnedReward(reward.amount.toInt(), reward.type);
        },
      );
    } else {
      print('Rewarded ad not ready');
      loadRewardedAd(); // Try loading again
    }
  }

  // Check if interstitial ad is ready
  bool get isInterstitialAdReady => _isInterstitialAdReady;

  // Check if rewarded ad is ready
  bool get isRewardedAdReady => _isRewardedAdReady;

  // Dispose ads
  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}
