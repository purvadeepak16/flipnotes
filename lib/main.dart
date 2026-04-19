import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart' as app_auth;
import 'screens/auth/auth_wrapper.dart';
import 'screens/main_navigation_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (!e.toString().contains('duplicate-app')) {
      rethrow;
    }
  }

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const FlipNotesApp());
}

class FlipNotesApp extends StatelessWidget {
  const FlipNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => app_auth.AuthProvider()),
      ],
      child: MaterialApp(
        title: 'FlipNotes',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const AuthWrapper(),
          '/home': (context) => const MainNavigationScreen(),
        },
      ),
    );
  }
}
