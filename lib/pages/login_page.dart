import 'package:flutter/material.dart';
import 'package:todo_lisha/services/auth_services.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Smart Todo',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 60),
              Image.asset(
                'assets/images/todo_logo.png', // Optional logo
                height: 120,
              ),
              const SizedBox(height: 60),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 24,
                  ),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.grey),
                  ),
                ),
                icon: Image.asset(
                  'assets/images/google_logo.png',
                  height: 24,
                  width: 24,
                ),
                label: const Text(
                  'Sign in with Google',
                  style: TextStyle(fontSize: 16),
                ),
                onPressed: () => AuthServices().signInWithGoogle(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
