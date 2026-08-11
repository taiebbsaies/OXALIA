import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'core/notifications/notification_inbox.dart';
import 'core/notifications/push_notification_service.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/theme_controller.dart';
import 'data/repositories/admin_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/exam_repository.dart';
import 'data/services/admin_service.dart';
import 'data/services/auth_service.dart';
import 'data/services/exam_service.dart';
import 'features/auth/viewmodel/auth_viewmodel.dart';
import 'routing/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(tokenStorage: tokenStorage);
  final authRepository = AuthRepository(
    authService: AuthService(apiClient),
    tokenStorage: tokenStorage,
  );
  final examRepository = ExamRepository(examService: ExamService(apiClient));
  final adminRepository = AdminRepository(adminService: AdminService(apiClient));
  final notificationInbox = NotificationInbox();
  await notificationInbox.load();

  final pushNotifications = PushNotificationService(
    apiClient,
    inbox: notificationInbox,
  );
  final authViewModel = AuthViewModel(
    authRepository,
    pushNotifications: pushNotifications,
  );
  final themeController = ThemeController();

  await pushNotifications.initialize();

  late final GoRouter router;
  router = buildRouter(authViewModel);
  pushNotifications.onOpenExam = (examId) {
    router.go(AppRoutes.examDetail(examId));
  };

  runApp(
    MultiProvider(
      providers: [
        Provider<TokenStorage>.value(value: tokenStorage),
        Provider<ApiClient>.value(value: apiClient),
        Provider<AuthRepository>.value(value: authRepository),
        Provider<ExamRepository>.value(value: examRepository),
        Provider<AdminRepository>.value(value: adminRepository),
        ChangeNotifierProvider<NotificationInbox>.value(value: notificationInbox),
        Provider<PushNotificationService>.value(value: pushNotifications),
        ChangeNotifierProvider<AuthViewModel>.value(value: authViewModel),
        ChangeNotifierProvider<ThemeController>.value(value: themeController),
      ],
      child: OxaliaApp(router: router),
    ),
  );

  // Validate any persisted session after the first frame; the router's
  // redirect reacts to the resulting status change automatically.
  await authViewModel.checkAuthStatus();
}
