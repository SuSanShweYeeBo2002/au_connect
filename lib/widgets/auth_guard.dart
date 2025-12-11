import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/signin_page.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.instance.isLoggedIn(),
      builder: (context, snapshot) {
        // Show loading while checking auth status
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Color(0xFFE3F2FD),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school, size: 64, color: Color(0xFF0288D1)),
                  SizedBox(height: 16),
                  Text(
                    'AU Connect',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 32),
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF0288D1),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // If user is logged in, show the protected content
        if (snapshot.hasData && snapshot.data == true) {
          return child;
        }

        // If not logged in, redirect to sign in page
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/signin');
        });

        // Show loading while redirecting
        return Scaffold(
          backgroundColor: Color(0xFFE3F2FD),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.security, size: 64, color: Color(0xFF0288D1)),
                SizedBox(height: 16),
                Text(
                  'Redirecting to Sign In...',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                SizedBox(height: 16),
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0288D1)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Alternative auth guard that directly returns SignInPage if not authenticated
class AuthGuardDirect extends StatelessWidget {
  final Widget child;

  const AuthGuardDirect({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.instance.isLoggedIn(),
      builder: (context, snapshot) {
        // Show loading while checking auth status
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Color(0xFFE3F2FD),
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0288D1)),
              ),
            ),
          );
        }

        // If user is logged in, show the protected content
        if (snapshot.hasData && snapshot.data == true) {
          return child;
        }

        // If not logged in, show sign in page directly
        return SignInPage();
      },
    );
  }
}
