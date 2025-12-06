// lib/features/splash/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Keep splash visible briefly for branding / firebase init
    await Future.delayed(const Duration(milliseconds: 800));
    // Let go_router's redirect handle navigation (go to /onboarding or /home)
    if (!mounted) return;
    context.go('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Eventra', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold))),
    );
  }
}
