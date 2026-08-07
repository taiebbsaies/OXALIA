import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:password_strength_checker/password_strength_checker.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/oxalia_password_strength.dart';
import '../../../routing/app_router.dart';
import '../../../shared/widgets/ecg_line.dart';
import '../../../shared/widgets/field_label.dart';
import '../../../shared/widgets/primary_button.dart';
import '../viewmodel/auth_viewmodel.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _strengthNotifier = ValueNotifier<OxaliaPasswordStrength?>(null);
  bool _obscurePassword = true;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    _strengthNotifier.value = OxaliaPasswordStrength.calculate(
      text: _passwordController.text,
    );
    setState(() {});
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _strengthNotifier.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final viewModel = context.read<AuthViewModel>();
    final success = await viewModel.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _fullNameController.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created. Please sign in.')),
      );
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AuthViewModel>();
    final palette = context.palette;
    final password = _passwordController.text;

    return Scaffold(
      body: Stack(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.6),
                radius: 1.2,
                colors: [palette.glow, palette.background],
              ),
            ),
            child: const SizedBox.expand(),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 32),
                        Text(
                          'Create Medical Account',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Join the OXALIA 2D platform',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: palette.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 32),
                        const FieldLabel('FULL NAME'),
                        TextFormField(
                          controller: _fullNameController,
                          textCapitalization: TextCapitalization.words,
                          style: TextStyle(color: palette.textPrimary),
                          decoration: const InputDecoration(
                            hintText: 'Dr. Jane Doe',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? 'Full name is required'
                                  : null,
                        ),
                        const SizedBox(height: 20),
                        const FieldLabel('EMAIL'),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          style: TextStyle(color: palette.textPrimary),
                          decoration: const InputDecoration(
                            hintText: 'doctor@hospital.com',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty) return 'Email is required';
                            if (!_emailRegex.hasMatch(email)) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        const FieldLabel('PASSWORD'),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: TextStyle(color: palette.textPrimary),
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                          validator: OxaliaPasswordStrength.validatePolicy,
                        ),
                        if (password.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          PasswordStrengthChecker<OxaliaPasswordStrength>(
                            strength: _strengthNotifier,
                            configuration: PasswordStrengthCheckerConfiguration(
                              height: 8,
                              inactiveBorderColor: palette.border,
                              borderColor: palette.border,
                              hasBorder: false,
                              externalBorderRadius: BorderRadius.circular(8),
                              internalBorderRadius: BorderRadius.circular(8),
                              statusMargin: const EdgeInsets.only(top: 8),
                              animationDuration:
                                  const Duration(milliseconds: 400),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _PasswordRulesChecklist(password: password),
                        ],
                        const SizedBox(height: 20),
                        const FieldLabel('CONFIRM PASSWORD'),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscurePassword,
                          style: TextStyle(color: palette.textPrimary),
                          decoration: const InputDecoration(
                            hintText: '••••••••',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        if (viewModel.errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              viewModel.errorMessage!,
                              style: TextStyle(color: palette.error),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          label: 'Create Account',
                          isLoading: viewModel.isLoading,
                          onPressed: _submit,
                        ),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: () => context.go(AppRoutes.login),
                          child: Text(
                            'Already have an account? Sign in',
                            style: TextStyle(
                              color: palette.teal,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(child: EcgLine()),
          ),
        ],
      ),
    );
  }
}

class _PasswordRulesChecklist extends StatelessWidget {
  const _PasswordRulesChecklist({required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final rules = <(String, bool)>[
      ('At least 8 characters', OxaliaPasswordStrength.hasMinLength(password)),
      ('One uppercase letter', OxaliaPasswordStrength.hasUppercase(password)),
      ('One lowercase letter', OxaliaPasswordStrength.hasLowercase(password)),
      ('One number', OxaliaPasswordStrength.hasDigit(password)),
      (
        'One special character',
        OxaliaPasswordStrength.hasSpecial(password),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          for (final (label, ok) in rules)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Icon(
                    ok ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 16,
                    color: ok ? palette.teal : palette.hint,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: ok ? palette.textPrimary : palette.textSecondary,
                        fontSize: 12,
                        fontWeight: ok ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
