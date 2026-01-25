import 'dart:async';
import 'package:flutter/material.dart';
import 'screens/auth_gate.dart';
import 'screens/splash_screen.dart';

void main() {
  // Set up global error handlers first (before any Flutter initialization)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('═══════════════════════════════════════');
    debugPrint('Flutter Error Caught:');
    debugPrint('${details.exception}');
    debugPrint('Stack trace:');
    debugPrint('${details.stack}');
    debugPrint('═══════════════════════════════════════');
  };

  // Run app in error zone to catch async errors
  runZonedGuarded(
    () async {
      // Ensure Flutter is initialized INSIDE the zone
      WidgetsFlutterBinding.ensureInitialized();
      runApp(const MyApp());
    },
    (error, stackTrace) {
      debugPrint('═══════════════════════════════════════');
      debugPrint('Uncaught Error:');
      debugPrint('$error');
      debugPrint('Stack trace:');
      debugPrint('$stackTrace');
      debugPrint('═══════════════════════════════════════');
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Candles - Nến Thông Minh',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          primary: Colors.purple[600],
          secondary: Colors.amber[600]!,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: SplashScreen(
        nextScreen: const AuthGate(),
      ),
    );
  }
}
