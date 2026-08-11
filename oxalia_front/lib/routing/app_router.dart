import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/notifications/notification_inbox.dart';
import '../data/repositories/admin_repository.dart';
import '../data/repositories/exam_repository.dart';
import '../features/admin/view/admin_dashboard_view.dart';
import '../features/admin/view/admin_users_view.dart';
import '../features/admin/viewmodel/admin_dashboard_viewmodel.dart';
import '../features/admin/viewmodel/admin_users_viewmodel.dart';
import '../features/analysis/view/new_analysis_view.dart';
import '../features/analysis/viewmodel/analysis_viewmodel.dart';
import '../features/auth/view/login_view.dart';
import '../features/auth/view/register_view.dart';
import '../features/auth/viewmodel/auth_viewmodel.dart';
import '../features/exam_detail/view/exam_detail_view.dart';
import '../features/exam_detail/viewmodel/exam_detail_viewmodel.dart';
import '../features/history/view/history_view.dart';
import '../features/history/viewmodel/history_viewmodel.dart';
import '../features/home/view/home_view.dart';
import '../features/home/viewmodel/home_viewmodel.dart';
import '../features/intro/view/intro_view.dart';
import '../features/navigation/view/main_shell.dart';
import '../features/notifications/view/notifications_view.dart';
import '../features/profile/view/profile_view.dart';

/// Route paths. Views never hardcode strings — they navigate via these.
abstract final class AppRoutes {
  static const String intro = '/intro';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String history = '/history';
  static const String profile = '/profile';
  static const String notifications = '/notifications';
  static const String newAnalysis = '/exams/new';
  static const String admin = '/admin';
  static const String adminUsers = '/admin/users';
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
          if (onPublicRoute || onIntro) return AppRoutes.home;
          final onAdminRoute = state.matchedLocation.startsWith(AppRoutes.admin);
          if (onAdminRoute && authViewModel.currentUser?.role != 'admin') {
            return AppRoutes.home;
          }
          return null;
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
      // Full-screen capture flow, pushed on top of the tab shell.
      // A fresh ViewModel per navigation guarantees no stale exam state.
      GoRoute(
        path: AppRoutes.newAnalysis,
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => AnalysisViewModel(
            context.read<ExamRepository>(),
            notificationInbox: context.read<NotificationInbox>(),
          ),
          child: const NewAnalysisView(),
        ),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsView(),
      ),
      GoRoute(
        path: AppRoutes.adminUsers,
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => AdminUsersViewModel(
            context.read<AdminRepository>(),
            currentUserId: context.read<AuthViewModel>().currentUser!.id,
          )..load(),
          child: const AdminUsersView(),
        ),
      ),
      GoRoute(
        path: '/exams/:examId',
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => ExamDetailViewModel(
            context.read<ExamRepository>(),
            state.pathParameters['examId']!,
          )..load(),
          child: const ExamDetailView(),
        ),
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
                builder: (context, state) => ChangeNotifierProvider(
                  create: (_) =>
                      HomeViewModel(context.read<ExamRepository>())..load(),
                  child: const HomeView(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.history,
                builder: (context, state) => ChangeNotifierProvider(
                  create: (_) =>
                      HistoryViewModel(context.read<ExamRepository>())
                        ..load(),
                  child: const HistoryView(),
                ),
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
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.admin,
                builder: (context, state) => ChangeNotifierProvider(
                  create: (_) =>
                      AdminDashboardViewModel(context.read<AdminRepository>())..load(),
                  child: const AdminDashboardView(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
