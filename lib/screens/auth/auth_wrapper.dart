import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../main_navigation_screen.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF6BBCBE)),
            ),
          );
        }

        final authProvider =
            context.watch<app_auth.AuthProvider>();

        if (authProvider.status == app_auth.AuthStatus.initial ||
            authProvider.status == app_auth.AuthStatus.loading &&
                snapshot.data != null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF6BBCBE)),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return const MainNavigationScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
