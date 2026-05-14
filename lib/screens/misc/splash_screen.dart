import 'dart:async';
import 'package:sheryan/core/theme/app_colors.dart';
import 'package:sheryan/main.dart';
import 'package:flutter/material.dart';
import 'package:sheryan/l10n/app_localizations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const StartupRouter()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo-splash.png',
              fit: BoxFit.contain,
              width: MediaQuery.of(context).size.width * 0.8,
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              color: Color(0xFFDC2626), // AppColors.primaryRed
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}