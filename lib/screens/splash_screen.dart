import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();

    // Wait for Firebase auth state
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    if (authProvider.isLoggedIn) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_giftcard, size: 100, color: Colors.amber[400])
                .animate()
                .scale(duration: 800.ms, curve: Curves.elasticOut)
                .then()
                .shake(duration: 500.ms),
            const SizedBox(height: 30),
            Text(
              'Mystery Box',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: Colors.amber[400],
                letterSpacing: 2,
              ),
            ).animate().fadeIn(duration: 600.ms, delay: 400.ms),
            const SizedBox(height: 10),
            Text(
              'Unwrap the Magic!',
              style: TextStyle(
                fontSize: 18,
                color: Colors.purple[200],
              ),
            ).animate().fadeIn(duration: 600.ms, delay: 800.ms),
            const SizedBox(height: 50),
            CircularProgressIndicator(color: Colors.amber[400])
                .animate()
                .fadeIn(duration: 400.ms, delay: 1200.ms),
          ],
        ),
      ),
    );
  }
}