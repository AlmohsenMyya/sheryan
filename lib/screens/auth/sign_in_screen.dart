
import 'package:sheryan/core/theme/app_colors.dart';
import 'package:sheryan/providers/auth/auth_provider.dart';
import 'package:sheryan/screens/auth/sign_up_screen.dart';
import 'package:sheryan/screens/home/home_screen.dart';
import 'package:sheryan/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  final AuthService _auth = AuthService();

  
Future<void> _login() async {
  final l10n = AppLocalizations.of(context)!;
  if (_email.text.trim().isEmpty || _password.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.loginEnterEmailPassword)));
    return;
  }

  setState(() => _loading = true);

  try {
    // 1) Attempt login via AuthService
    final ok = await _auth.loginUser(_email.text.trim(), _password.text);
    if (!ok) throw Exception('Invalid credentials or login failed');

    // 2) Wait a short moment for Firebase Auth to update currentUser
    await Future.delayed(const Duration(milliseconds: 300));

    // 3) Ensure currentUser exists
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Auth succeeded but currentUser is null');

    // 4) Verify that users/{uid} document exists in Firestore (retry a few times)
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    DocumentSnapshot<Map<String, dynamic>>? doc;
    var tries = 0;
    while (tries < 6) {
      doc = await docRef.get();
      if (doc.exists) break;
      await Future.delayed(const Duration(milliseconds: 300));
      tries++;
    }
    if (doc == null || !doc.exists) {
      throw Exception('User profile not found in Firestore. Please contact support.');
    }

    // 5) Set role in provider so Home shows correct dashboard
    final roleValue = (doc.data()?['role'] as String?) ?? 'user';
    ref.read(roleProvider.notifier).setRoleFromString(roleValue);

    // 6) Navigate to Home and clear back stack
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  } catch (e, st) {
    debugPrint('Login error: $e\n$st');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.loginFailed(e.toString()))));
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Image.asset(
                    'assets/logo.png',
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  l10n.welcomeBack,
                  style: theme.textTheme.displayMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.loginToAccount,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                // email
                TextField(
                  controller: _email,
                  decoration: InputDecoration(
                    hintText: l10n.email,
                    prefixIcon: const Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 12),
                // password
                TextField(
                  controller: _password,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    hintText: l10n.password,
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(l10n.login),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SignupScreen(
                          role: ref.read(roleProvider),
                        ),
                      ),
                    ),
                    child: Text(
                      l10n.dontHaveAccountSignUp,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
