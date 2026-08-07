import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oxalia_front/core/network/api_client.dart';
import 'package:oxalia_front/core/theme/app_theme.dart';
import 'package:oxalia_front/core/storage/token_storage.dart';
import 'package:oxalia_front/data/repositories/auth_repository.dart';
import 'package:oxalia_front/data/services/auth_service.dart';
import 'package:oxalia_front/features/auth/view/login_view.dart';
import 'package:oxalia_front/features/auth/view/register_view.dart';
import 'package:oxalia_front/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:provider/provider.dart';

/// Builds the real dependency chain. No network call is made as long as
/// no form submission succeeds — validators run purely client-side.
AuthViewModel buildViewModel() {
  final tokenStorage = TokenStorage();
  final repository = AuthRepository(
    authService: AuthService(ApiClient(tokenStorage: tokenStorage)),
    tokenStorage: tokenStorage,
  );
  return AuthViewModel(repository);
}

Widget wrap(Widget child, AuthViewModel viewModel) {
  return ChangeNotifierProvider<AuthViewModel>.value(
    value: viewModel,
    child: MaterialApp(theme: AppTheme.dark, home: child),
  );
}

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_BASE_URL=http://localhost:8000');
  });

  group('LoginView', () {
    testWidgets('renders email/password fields and sign-in button', (tester) async {
      await tester.pumpWidget(wrap(const LoginView(), buildViewModel()));

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('EMAIL'), findsOneWidget);
      expect(find.text('PASSWORD'), findsOneWidget);
      // AnimatedButton stacks the label twice (normal + selected states).
      expect(find.text('Sign In'), findsNWidgets(2));
    });

    testWidgets('shows validation errors on invalid input', (tester) async {
      await tester.pumpWidget(wrap(const LoginView(), buildViewModel()));

      await tester.enterText(find.byType(TextFormField).at(0), 'not-an-email');
      await tester.tap(find.text('Sign In').first);
      // pumpAndSettle: AnimatedButton runs a 400ms sweep on tap.
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email address'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });
  });

  group('RegisterView', () {
    testWidgets('rejects short passwords and mismatched confirmation', (tester) async {
      await tester.pumpWidget(wrap(const RegisterView(), buildViewModel()));

      // Field order: full name, email, password, confirm password.
      await tester.enterText(find.byType(TextFormField).at(0), 'Dr Test');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'doc@oxalia.health',
      );
      await tester.enterText(find.byType(TextFormField).at(2), 'short');
      await tester.pump();
      await tester.enterText(find.byType(TextFormField).at(3), 'different');

      // Strength checklist grows the form — scroll the submit button on-screen.
      await tester.ensureVisible(find.text('Create Account').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create Account').first);
      await tester.pumpAndSettle();

      expect(
        find.text('Password must be at least 8 characters'),
        findsOneWidget,
      );
      expect(find.text('Passwords do not match'), findsOneWidget);
    });
  });
}
