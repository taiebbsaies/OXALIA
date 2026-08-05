import 'package:go_router/go_router.dart';

import '../features/auth/view/login_view.dart';
import '../features/auth/view/register_view.dart';
import '../features/auth/viewmodel/auth_viewmodel.dart';
import '../features/history/view/history_view.dart';
import '../features/home/view/home_view.dart';
import '../features/intro/view/intro_view.dart';
import '../features/navigation/view/main_shell.dart';
import '../features/profile/view/profile_view.dart';

/// Route paths. Views never hardcode strings — they navigate via these.
abstract final class AppRoutes {
  static const String intro = '/intro';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String history = '/history';
  static const String profile = '/profile';
  static const String examUpload = '/exams/upload';
  static String examDetail(String examId) => '/exams/$examId';
}

const _publicRoutes = {AppRoutes.login, AppRoutes.register};

/// The router depends on the AuthViewModel: any auth state change
/// re-evaluates [redirect] and moves the user automatically.
GoRouter buildRouter(AuthViewModel authViewModel) {
  // The intro animation plays once per app launch, before the login screen.
  var introShown = false;

  return GoRouter(
    initialLocation: AppRoutes.intro,
    refreshListenable: authViewModel,
    redirect: (context, state) {
      final status = authViewModel.status;
      final onPublicRoute = _publicRoutes.contains(state.matchedLocation);
      final onIntro = state.matchedLocation == AppRoutes.intro;

      switch (status) {
        case AuthStatus.unknown:
          // Session check runs while the intro animation plays.
          return onIntro ? null : AppRoutes.intro;
        case AuthStatus.unauthenticated:
          // Being on the intro marks it as shown, otherwise the redirect
          // would bounce the view's own "intro finished" navigation to
          // /login back to /intro forever.
          if (onIntro) {
            introShown = true;
            return null;
          }
          if (!introShown) {
            introShown = true;
            return AppRoutes.intro;
          }
          return onPublicRoute ? null : AppRoutes.login;
        case AuthStatus.authenticated:
          return (onPublicRoute || onIntro) ? AppRoutes.home : null;
      }
    },
    routes: [
      GoRoute(
        path: AppRoutes.intro,
        builder: (context, state) => const IntroView(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterView(),
      ),
      // Main tabs share a persistent bottom navigation bar.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeView(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.history,
                builder: (context, state) => const HistoryView(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileView(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
