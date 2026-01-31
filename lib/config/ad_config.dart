import 'package:flutter/foundation.dart';

/// Ad configuration that automatically switches between test and production IDs
class AdConfig {
  // Set this to true when you want to use real ads (deployed to production)
  static const bool useProductionAds =
      kReleaseMode; // Only use real ads in release builds

  // ==================== WEB (AdSense) ====================

  /// AdSense Publisher ID
  static String get webPublisherId {
    if (useProductionAds) {
      return 'ca-pub-8464686587467227'; // Your real Publisher ID
    }
    // Test ID (works for development but shows 400 errors on localhost)
    return 'ca-pub-3940256099942544';
  }

  /// AdSense Ad Slot ID
  static String get webAdSlot {
    if (useProductionAds) {
      // TODO: After AdSense approves your site, create an ad unit and paste the slot ID here
      // Go to: Ads > By ad unit > New ad unit > Display ads > Create
      // Then paste the data-ad-slot number here
      return 'XXXXXXXXXX'; // Replace with your ad slot ID from AdSense
    }
    return '1234567890'; // Test slot
  }

  // ==================== MOBILE (AdMob) ====================

  /// Android App ID
  static const String androidAppId = 'ca-app-pub-3940256099942544~3347511713';

  /// iOS App ID
  static const String iosAppId = 'ca-app-pub-3940256099942544~1458002511';

  /// Banner Ad Unit IDs
  static String get androidBannerId {
    if (useProductionAds) {
      // TODO: Replace with your real Android banner ID
      return 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
    }
    return 'ca-app-pub-3940256099942544/6300978111'; // Test
  }

  static String get iosBannerId {
    if (useProductionAds) {
      // TODO: Replace with your real iOS banner ID
      return 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
    }
    return 'ca-app-pub-3940256099942544/2934735716'; // Test
  }

  /// Interstitial Ad Unit IDs
  static String get androidInterstitialId {
    if (useProductionAds) {
      // TODO: Replace with your real Android interstitial ID
      return 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
    }
    return 'ca-app-pub-3940256099942544/1033173712'; // Test
  }

  static String get iosInterstitialId {
    if (useProductionAds) {
      // TODO: Replace with your real iOS interstitial ID
      return 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
    }
    return 'ca-app-pub-3940256099942544/4411468910'; // Test
  }

  /// Rewarded Ad Unit IDs
  static String get androidRewardedId {
    if (useProductionAds) {
      // TODO: Replace with your real Android rewarded ID
      return 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
    }
    return 'ca-app-pub-3940256099942544/5224354917'; // Test
  }

  static String get iosRewardedId {
    if (useProductionAds) {
      // TODO: Replace with your real iOS rewarded ID
      return 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
    }
    return 'ca-app-pub-3940256099942544/1712485313'; // Test
  }
}
