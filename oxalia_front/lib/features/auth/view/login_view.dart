import 'package:flutter/material.dart';

/// Placeholder login screen — real form wired to AuthViewModel next sprint.
class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OXALIA')),
      body: const Center(child: Text('Sign in')),
    );
  }
}
