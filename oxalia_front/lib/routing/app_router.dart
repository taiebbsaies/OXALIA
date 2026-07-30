import 'package:go_router/go_router.dart';

import '../features/auth/view/login_view.dart';
import '../features/home/view/home_view.dart';

/// Route paths. Views never hardcode strings — they navigate via these.
abstract final class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String examUpload = '/exams/upload';
  static String examDetail(String examId) => '/exams/$examId';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.login,
  routes: [
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginView(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeView(),
    ),
  ],
);
