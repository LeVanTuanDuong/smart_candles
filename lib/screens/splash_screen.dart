import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import '../services/auth_service.dart';
import '../services/ai_inference_service.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const SplashScreen({
    super.key,
    required this.nextScreen,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _progress = 0.0;
  String _status = 'Dang khoi tao...';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      _setProgress('Dang khoi tao Firebase...', 0.1);
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      _setProgress('Dang chuan bi tai khoan...', 0.25);
      // Wrap AuthService initialization in try-catch
      try {
        await AuthService().initialize();
      } catch (authError, authStack) {
        debugPrint('⚠️ AuthService initialization warning: $authError');
        debugPrint('Stack: $authStack');
        // Continue anyway - user can still use app and login later
      }

      _setProgress('Dang nap bo suy luan...', 0.45);
      await AiInferenceService().initialize(
        onProgress: (progress) {
          _setProgress('Dang nap bo suy luan...', 0.45 + (0.5 * progress));
        },
      );
      _setProgress('Dang nap bo suy luan...', 0.95);

      _setProgress('Hoan tat.', 1.0);
      if (!mounted) return;

      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;

      // Add safety check and error handling for navigation
      try {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => widget.nextScreen),
        );
      } catch (navError, navStack) {
        debugPrint('Navigation error: $navError');
        debugPrint('Stack: $navStack');
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Loi dieu huong: $navError';
        });
      }
    } catch (e, stackTrace) {
      debugPrint('═══════════════════════════════════════');
      debugPrint('Splash Screen Initialization Error:');
      debugPrint('Error: $e');
      debugPrint('Stack trace:');
      debugPrint('$stackTrace');
      debugPrint('═══════════════════════════════════════');

      if (!mounted) return;
      setState(() {
        _errorMessage = 'Khoi tao that bai:\n$e\n\nVui long thu lai.';
      });
    }
  }

  void _setProgress(String status, double progress) {
    if (!mounted) return;
    setState(() {
      _status = status;
      _progress = progress.clamp(0.0, 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    size: 72,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Smart Candles',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_errorMessage == null) ...[
                    LinearProgressIndicator(
                      value: _progress,
                      minHeight: 6,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _status,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${(_progress * 100).round()}%',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ] else ...[
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                          _progress = 0.0;
                          _status = 'Dang thu lai...';
                        });
                        _initializeApp();
                      },
                      child: const Text('Thu lai'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
