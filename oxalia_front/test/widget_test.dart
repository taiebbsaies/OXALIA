import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oxalia_front/features/auth/view/login_view.dart';
import 'package:oxalia_front/features/home/view/home_view.dart';

void main() {
  testWidgets('LoginView renders its placeholder content', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginView()));

    expect(find.text('OXALIA'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('HomeView renders its placeholder content', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeView()));

    expect(find.text('My exams'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });
}
