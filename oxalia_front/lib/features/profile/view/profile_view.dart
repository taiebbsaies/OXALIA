import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:password_strength_checker/password_strength_checker.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/utils/oxalia_password_strength.dart';
import '../../../shared/widgets/field_label.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final user = context.watch<AuthViewModel>().currentUser;
    final themeController = context.watch<ThemeController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── Identity card ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: palette.teal,
                  child: Icon(Icons.person, color: palette.onAccent, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'Clinician',
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Appearance ─────────────────────────────────────────────────
          const SizedBox(height: 32),
          Text(
            'APPEARANCE',
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          AnimatedToggleSwitch<ThemeMode>.rolling(
            current: themeController.mode,
            values: const [ThemeMode.system, ThemeMode.light, ThemeMode.dark],
            onChanged: (mode) => context.read<ThemeController>().setMode(mode),
            iconBuilder: (mode, foreground) => Icon(
              switch (mode) {
                ThemeMode.system => Icons.brightness_auto,
                ThemeMode.light => Icons.light_mode,
                ThemeMode.dark => Icons.dark_mode,
              },
              color: foreground ? palette.onAccent : palette.textSecondary,
            ),
            height: 48,
            indicatorSize: const Size.fromWidth(56),
            style: ToggleStyle(
              backgroundColor: palette.surface,
              borderColor: palette.border,
              borderRadius: BorderRadius.circular(14),
              indicatorBorderRadius: BorderRadius.circular(10),
            ),
            styleBuilder: (mode) => ToggleStyle(indicatorColor: palette.teal),
          ),
          const SizedBox(height: 8),
          Text(
            switch (themeController.mode) {
              ThemeMode.system => 'Following your phone theme automatically',
              ThemeMode.light => 'Light theme',
              ThemeMode.dark => 'Dark theme',
            },
            style: TextStyle(color: palette.hint, fontSize: 12),
          ),

          const SizedBox(height: 32),
          Text(
            'TELEGRAM',
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          const _LinkTelegramCard(),

          // ── Security ───────────────────────────────────────────────────
          const SizedBox(height: 32),
          Text(
            'SECURITY',
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          const _ChangePasswordCard(),

          // ── Sign out ───────────────────────────────────────────────────
          const SizedBox(height: 40),
          OutlinedButton.icon(
            onPressed: () => context.read<AuthViewModel>().logout(),
            icon: Icon(Icons.logout, color: palette.error),
            label: Text(
              'Sign out',
              style: TextStyle(color: palette.error),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              side: BorderSide(color: palette.error.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _LinkTelegramCard extends StatefulWidget {
  const _LinkTelegramCard();

  @override
  State<_LinkTelegramCard> createState() => _LinkTelegramCardState();
}

class _LinkTelegramCardState extends State<_LinkTelegramCard> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    final existing = context.read<AuthViewModel>().currentUser?.telegramUserId;
    if (existing != null) {
      _controller.text = existing;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final viewModel = context.read<AuthViewModel>();
    final raw = _controller.text.trim();
    final success = await viewModel.linkTelegram(
      telegramUserId: raw.isEmpty ? null : raw,
    );
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            raw.isEmpty
                ? 'Telegram unlinked.'
                : 'Telegram linked. Send X-rays to the OXALIA bot with the patient name as caption.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final viewModel = context.watch<AuthViewModel>();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Link Telegram',
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Open Telegram, search @userinfobot, send any message, then paste the numeric Id here. '
            'You chat with the OXALIA bot as a normal contact — you do not create a bot.',
            style: TextStyle(color: palette.textSecondary, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Telegram user id',
              hintText: '123456789',
            ),
            onChanged: (_) => viewModel.clearTelegramError(),
          ),
          if (viewModel.telegramError != null) ...[
            const SizedBox(height: 8),
            Text(
              viewModel.telegramError!,
              style: TextStyle(color: palette.error, fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Save Telegram id',
            isLoading: viewModel.isLinkingTelegram,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

// ── Change-password card ─────────────────────────────────────────────────────

class _ChangePasswordCard extends StatefulWidget {
  const _ChangePasswordCard();

  @override
  State<_ChangePasswordCard> createState() => _ChangePasswordCardState();
}

class _ChangePasswordCardState extends State<_ChangePasswordCard> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _strengthNotifier = ValueNotifier<OxaliaPasswordStrength?>(null);

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_onNewPasswordChanged);
  }

  void _onNewPasswordChanged() {
    _strengthNotifier.value =
        OxaliaPasswordStrength.calculate(text: _newPasswordController.text);
    setState(() {});
  }

  @override
  void dispose() {
    _newPasswordController.removeListener(_onNewPasswordChanged);
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmController.dispose();
    _strengthNotifier.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final viewModel = context.read<AuthViewModel>();
    final success = await viewModel.changePassword(
      oldPassword: _oldPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    if (!mounted) return;

    if (success) {
      _formKey.currentState!.reset();
      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmController.clear();
      _strengthNotifier.value = null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final viewModel = context.watch<AuthViewModel>();
    final newPassword = _newPasswordController.text;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.lock_outline, color: palette.teal, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Change Password',
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Current password
            const FieldLabel('CURRENT PASSWORD'),
            TextFormField(
              controller: _oldPasswordController,
              obscureText: _obscureOld,
              style: TextStyle(color: palette.textPrimary),
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureOld
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscureOld = !_obscureOld),
                ),
              ),
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Current password is required'
                  : null,
            ),
            const SizedBox(height: 20),

            // New password
            const FieldLabel('NEW PASSWORD'),
            TextFormField(
              controller: _newPasswordController,
              obscureText: _obscureNew,
              style: TextStyle(color: palette.textPrimary),
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNew
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscureNew = !_obscureNew),
                ),
              ),
              validator: OxaliaPasswordStrength.validatePolicy,
            ),
            if (newPassword.isNotEmpty) ...[
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
                  animationDuration: const Duration(milliseconds: 400),
                ),
              ),
              const SizedBox(height: 12),
              _PasswordRulesChecklist(password: newPassword),
            ],
            const SizedBox(height: 20),

            // Confirm password
            const FieldLabel('CONFIRM NEW PASSWORD'),
            TextFormField(
              controller: _confirmController,
              obscureText: _obscureConfirm,
              style: TextStyle(color: palette.textPrimary),
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your new password';
                }
                if (value != _newPasswordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),

            // API error
            if (viewModel.changePasswordError != null) ...[
              const SizedBox(height: 12),
              Text(
                viewModel.changePasswordError!,
                style: TextStyle(color: palette.error, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Update Password',
              isLoading: viewModel.isChangingPassword,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Password rules checklist (mirrors register_view.dart) ────────────────────

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
      ('One special character', OxaliaPasswordStrength.hasSpecial(password)),
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
                        fontWeight:
                            ok ? FontWeight.w600 : FontWeight.w400,
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
