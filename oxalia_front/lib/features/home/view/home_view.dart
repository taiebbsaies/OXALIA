import 'package:flutter/material.dart';

/// Placeholder home screen shown after authentication.
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My exams')),
      body: const Center(child: Text('Home')),
    );
  }
}
