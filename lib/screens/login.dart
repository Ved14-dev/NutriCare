import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../backend/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _loading = false;

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      final user = await AuthService.signInWithGoogle();
      if (user == null) {
        Fluttertoast.showToast(msg: 'Sign-in cancelled');
        } else {
        Fluttertoast.showToast(msg: 'Welcome ${user.displayName ?? ''}');
        // Navigate to dashboard replacing login
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Sign-in failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Welcome to NutriCare', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('Sign in to continue', style: GoogleFonts.inter()),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.login, size: 18),
                    label: Text('Sign in with Google', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    onPressed: _loading ? null : _signIn,
                  ),
                ),
                if (_loading) const Padding(padding: EdgeInsets.only(top: 12), child: CircularProgressIndicator()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
