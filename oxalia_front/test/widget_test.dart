import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oxalia_front/core/network/api_client.dart';
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
    child: MaterialApp(home: child),
  );
}

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_BASE_URL=http://localhost:8000');
  });

  group('LoginView', () {
    testWidgets('renders email/password fields and sign-in button', (tester) async {
      await tester.pumpWidget(wrap(const LoginView(), buildViewModel()));

      expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
      expect(find.text('Sign in'), findsWidgets);
    });

    testWidgets('shows validation errors on invalid input', (tester) async {
      await tester.pumpWidget(wrap(const LoginView(), buildViewModel()));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'not-an-email',
      );
      await tester.tap(find.text('Sign in').last);
      await tester.pump();

      expect(find.text('Enter a valid email address'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });
  });

  group('RegisterView', () {
    testWidgets('rejects short passwords and mismatched confirmation', (tester) async {
      await tester.pumpWidget(wrap(const RegisterView(), buildViewModel()));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Full name'),
        'Dr Test',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'doc@oxalia.health',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'short',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm password'),
        'different',
      );
      await tester.tap(find.text('Create account').last);
      await tester.pump();

      expect(
        find.text('Password must be at least 8 characters'),
        findsOneWidget,
      );
      expect(find.text('Passwords do not match'), findsOneWidget);
    });
  });
}
