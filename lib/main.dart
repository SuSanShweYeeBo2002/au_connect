import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'screens/signin_page.dart';
import 'screens/signup_page.dart';
import 'screens/main_tab_page.dart';
import 'screens/reset_password_page.dart';
import 'widgets/auth_guard.dart';
import 'widgets/global_zoom_wrapper.dart';
import 'services/auth_service.dart';
import 'config/api_config.dart';
import 'config/theme_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Log API configuration
  ApiConfig.logConfig();

  // Initialize Google Mobile Ads SDK
  if (!kIsWeb) {
    await MobileAds.instance.initialize();
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  late AppLinks _appLinks;
  StreamSubscription? _deepLinkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinkListener();
  }

  void _initDeepLinkListener() {
    // Deep links only work on mobile platforms (Android/iOS)
    if (kIsWeb) {
      print('Deep linking not supported on web platform');
      return;
    }

    _appLinks = AppLinks();

    // Handle deep links when app is already running
    _deepLinkSubscription = _appLinks.uriLinkStream.listen(
      (Uri? uri) {
        if (uri != null) {
          _handleDeepLink(uri);
        }
      },
      onError: (err) {
        print('Deep link error: $err');
      },
    );

    // Handle initial deep link when app is opened from closed state
    _handleInitialDeepLink();
  }

  Future<void> _handleInitialDeepLink() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      print('Error getting initial deep link: $e');
    }
  }

  void _handleDeepLink(Uri uri) {
    print('Deep link received: $uri');

    // Handle auconnect://signin
    if (uri.scheme == 'auconnect' && uri.host == 'signin') {
      // Navigate to signin page
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/signin',
        (route) => false,
      );

      // Show success message
      Future.delayed(Duration(milliseconds: 500), () {
        final context = navigatorKey.currentContext;
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Email verified successfully! You can now sign in.',
                    ),
                  ),
                ],
              ),
              duration: Duration(seconds: 4),
              backgroundColor: Colors.green[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      });
    }
    // Handle password reset deep link: auconnect://reset-password?token=xxx
    else if (uri.scheme == 'auconnect' && uri.host == 'reset-password') {
      final token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        // Navigate to reset password page
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => ResetPasswordPage(token: token),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _deepLinkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'AU Connect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      builder: (context, child) {
        // Wrap the entire app with global zoom functionality
        // minScale: 1.0 means no zoom out (like Facebook) - prevents white space
        return GlobalZoomInteractiveWrapper(
          minScale: 1.0, // Changed from 0.7 - no zoom out beyond actual size
          maxScale: 2.5, // Can still zoom in up to 2.5x
          child: child ?? Container(),
        );
      },
      home: FutureBuilder<bool>(
        future: AuthService.instance.isLoggedIn(),
        builder: (context, snapshot) {
          // Show loading while checking auth status
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              backgroundColor: AppTheme.primaryBeige,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.school, size: 64, color: AppTheme.brownPrimary),
                    SizedBox(height: 16),
                    Text(
                      'AU CONNECT',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 32),
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.brownPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // If user is logged in, go to main page, otherwise go to signin
          if (snapshot.hasData && snapshot.data == true) {
            return MainTabPage();
          } else {
            return SignInPage();
          }
        },
      ),
      routes: {
        '/signin': (context) => SignInPage(),
        '/signup': (context) => SignUpPage(),
        '/main': (context) => AuthGuardDirect(child: MainTabPage()),
        '/home': (context) =>
            AuthGuardDirect(child: MyHomePage(title: 'Flutter Demo Home Page')),
      },
      onGenerateRoute: (settings) {
        // Handle /reset-password?token=xxx from email links
        if (settings.name?.startsWith('/reset-password') == true) {
          final uri = Uri.parse(settings.name!);
          final token = uri.queryParameters['token'] ?? '';
          if (token.isNotEmpty) {
            return MaterialPageRoute(
              builder: (context) => ResetPasswordPage(token: token),
            );
          }
        }
        return null;
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
