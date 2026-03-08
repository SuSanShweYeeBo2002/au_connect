# Advertisement Testing Guide

## Current Ad Setup
- **Web Platform**: Adcash (Zone ID: itqfjf7rmz)
- **Mobile Platform**: Google AdMob (currently using test IDs)
- **Ad Widget**: BannerAdWidget (visible on home page)

---

## 🌐 WEB ADS (Adcash) - Testing

### Method 1: Browser Developer Console
1. Open your web app in browser
2. Press `F12` to open Developer Tools
3. Go to **Console** tab
4. Look for these messages:
   - ✅ **Working**: `aclib.runAutoTag()` executes without errors
   - ❌ **Not Working**: "Adcash aclib not loaded yet" or CORS errors
   - ❌ **Not Working**: 404 errors for `acacdn.com` scripts

### Method 2: Network Tab
1. Open Developer Tools (`F12`)
2. Go to **Network** tab
3. Reload the page
4. Filter by "aclib" or "acacdn.com"
5. Check:
   - ✅ Script loads successfully (Status: 200)
   - ✅ Ad requests are being made
   - ❌ 404 or blocked requests indicate issues

### Method 3: Visual Inspection
1. Navigate to Home Page (where `BannerAdWidget` is displayed)
2. Look for:
   - ✅ Ad placeholder with "Advertisement" text
   - ✅ Gray container (728x90 or similar)
   - ⚠️ If only placeholder shows: Ad may be loading or blocked by adblocker
   - ❌ Nothing visible: Widget not rendering

### Method 4: Check Ad Blocker
1. Disable browser ad blocker temporarily
2. Reload the page
3. If ads appear now → Ad blocker was blocking them
4. **Note**: Revenue won't count if users have ad blockers

### Method 5: Check Flutter Console
Run your app with:
```powershell
flutter run -d chrome --web-renderer html
```

Look for console output:
```
✅ Adcash loaded successfully
❌ Adcash error: [error message]
```

---

## 📱 MOBILE ADS (AdMob) - Testing

### For Android/iOS Testing:

1. **Start the app in debug mode:**
```powershell
flutter run -d <device-id>
```

2. **Check Flutter console for:**
```
✅ Banner ad loaded
❌ Banner ad failed to load: [error code]
```

3. **Common Error Codes:**
   - `ERROR_CODE_NO_FILL`: No ads available (normal for test IDs)
   - `ERROR_CODE_NETWORK_ERROR`: Internet connection issue
   - `ERROR_CODE_INTERNAL_ERROR`: AdMob setup issue
   - `ERROR_CODE_INVALID_REQUEST`: Wrong ad unit ID

### Switch to Production Ads:
In `lib/config/ad_config.dart`, the app uses:
- **Test IDs** in debug mode (safe for development)
- **Production IDs** in release builds only

Current status: Using test IDs for development ✅

---

## 🔍 QUICK DIAGNOSIS

### Web Build (Current)
Run these commands:

```powershell
# 1. Build and check for issues
flutter build web

# 2. Serve locally and test
cd build/web
python -m http.server 8000
# Open http://localhost:8000 in browser
```

**Then check:**
1. Open browser at `http://localhost:8000`
2. Open DevTools (F12) → Console
3. Look for Adcash messages
4. Check Network tab for ad script loads

### Verify Ad Widget is Visible
Your ads appear in: `lib/screens/home_page.dart` (lines 794, 796)

---

## ⚠️ COMMON ISSUES & SOLUTIONS

### Issue 1: "Adcash aclib not loaded yet"
**Solution:**
- Script is loading too late
- Check internet connection
- Verify `index.html` has script tag (✅ it does at line 33)

### Issue 2: No ads showing
**Possible causes:**
1. Ad blocker is active → Disable and test
2. Zone ID rejected → Check Adcash dashboard for approval status
3. CORS or CSP blocking → Check browser console for security errors
4. Wrong zone ID → Verify `itqfjf7rmz` is correct in Adcash dashboard

### Issue 3: Gray placeholder only
**This is EXPECTED**:
- Placeholder shows while ad loads
- If it stays gray: No ad to display OR ad blocked

### Issue 4: Console errors in Flutter
**Check for:**
```dart
// In banner_ad_widget.dart line 35
Failed to load banner ad: [error]
```

---

## 📊 VERIFY ADS ARE EARNING REVENUE

### Adcash Dashboard
1. Login to Adcash publisher account
2. Go to **Reports** → **Statistics**
3. Check:
   - **Impressions**: Number of times ad was shown
   - **Clicks**: Number of ad clicks
   - **Revenue**: Money earned
4. **Note**: Stats may take 24-48 hours to update

### AdMob Dashboard (for mobile)
1. Login to https://apps.admob.google.com
2. Check app statistics
3. **Note**: Currently using test IDs, so no real revenue yet

---

## 🚀 PRODUCTION DEPLOYMENT CHECKLIST

Before going live with real ads:

### Web (Adcash):
- [✅] Script added to index.html
- [✅] Zone ID configured: itqfjf7rmz
- [ ] Verify zone is approved in Adcash dashboard
- [ ] Test on multiple browsers (Chrome, Firefox, Safari)
- [ ] Test with and without ad blocker

### Mobile (AdMob):
- [ ] Replace test IDs with real AdMob IDs in `lib/config/ad_config.dart`
- [ ] Set `useProductionAds = true` for release builds
- [ ] Test banner loads on physical devices
- [ ] Submit app to Google Play/App Store
- [ ] Wait for AdMob approval (~24 hours)

---

## 🛠️ ADVANCED DEBUGGING

### Enable Verbose Logging

Add to `lib/widgets/web_banner_ad.dart`:
```dart
print('Adcash container created: ${adContainer.id}');
print('Adcash zone ID: itqfjf7rmz');
print('Adcash script executed');
```

### Test Different Ad Formats
Your current setup supports:
- ✅ Banner ads (728x90)
- ✅ Interstitial ads (full screen)
- Rewarded ads (for mobile)

---

## 📞 SUPPORT

If ads still don't work:
1. Check Adcash support/documentation
2. Verify your publisher account is active
3. Test on different networks (some networks block ads)
4. Try different browsers/devices

**Last Updated**: February 26, 2026
