import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../../routing/app_router.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';

/// App introduction: plays first.json once while the session check runs
/// in the background, then moves on. A loader overlays the animation
/// while the auth status is still being resolved.
class IntroView extends StatefulWidget {
  const IntroView({super.key});

  @override
  State<IntroView> createState() => _IntroViewState();
}

class _IntroViewState extends State<IntroView> with TickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _fallbackTimer;
  bool _animationFinished = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _animationFinished = true;
          _tryNavigate();
        }
      });
    // Safety net: never trap the user if the animation fails to load.
    _fallbackTimer = Timer(const Duration(seconds: 12), () {
      _animationFinished = true;
      _tryNavigate();
    });
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Navigates once BOTH conditions are met: the animation has finished
  /// and the session check has answered. Authenticated users aiming at
  /// /login are bounced to /home by the router's redirect.
  void _tryNavigate() {
    if (_navigated || !mounted || !_animationFinished) return;
    final status = context.read<AuthViewModel>().status;
    if (status == AuthStatus.unknown) return;
    _navigated = true;
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthViewModel>().status;

    // The session check may have answered after the animation completed;
    // retry navigation once the frame is built.
    if (_animationFinished && status != AuthStatus.unknown) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryNavigate());
    }

    final dimension = MediaQuery.sizeOf(context).shortestSide * 0.85;
    final sessionCheckRunning = status == AuthStatus.unknown;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          _animationFinished = true;
          _tryNavigate(); // tap to skip, still waits for the session check
        },
        child: Stack(
          children: [
            Center(
              child: SizedBox(
                width: dimension,
                height: dimension,
                child: Lottie.asset(
                  'assets/animations/first.json',
                  controller: _controller,
                  fit: BoxFit.contain,
                  onLoaded: (composition) {
                    _controller.duration = composition.duration;
                    _controller.forward();
                  },
                ),
              ),
            ),
            if (sessionCheckRunning)
              const Positioned(
                left: 0,
                right: 0,
                bottom: 48,
                child: Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF2DD4BF),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
