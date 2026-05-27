import 'package:flutter/material.dart';

import '../app_routes.dart';
import '../models/auth_models.dart';
import '../services/password_reset_service.dart';
import '../utils/login_decoration.dart';

class PasswordResetArgs {
  const PasswordResetArgs({
    this.email,
    this.accountType = UserRole.client,
    this.isRequiredChange = false,
  });

  final String? email;
  final UserRole accountType;
  final bool isRequiredChange;
}

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({
    super.key,
    this.args,
  });

  final PasswordResetArgs? args;

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String? _errorMessage;
  bool _isSaving = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String get _email => widget.args?.email?.trim().toLowerCase() ?? '';
  bool get _isWorkshopAccount => widget.args?.accountType == UserRole.workshop;
  bool get _isRequiredChange => widget.args?.isRequiredChange == true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (_email.isEmpty) {
      setState(() {
        _errorMessage =
            'Ingresa tu correo en login antes de recuperar la contraseña.';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _errorMessage = 'La contraseña debe tener al menos 6 caracteres.';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = 'Las contraseñas no coinciden.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final result = await PasswordResetService.resetPassword(
      email: _email,
      newPassword: password,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isSaving = false);

    if (!result.isSuccess) {
      setState(() {
        _errorMessage =
            result.errorMessage ?? 'No se encontró una cuenta para $_email.';
      });
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Contraseña actualizada. Inicia sesión con la nueva clave.'),
      ),
    );

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFD8AD20),
              Color(0xFFF0C630),
              Color(0xFFF8D74E),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ResetTopBar(
                        onBack: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(height: 20),
                      const _ResetHero(),
                      const SizedBox(height: 22),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x160B285A),
                              blurRadius: 24,
                              offset: Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Restablecer contraseña',
                              style: TextStyle(
                                fontSize: 28,
                                height: 1.05,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF123F78),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _email.isEmpty
                                  ? 'Define una nueva contraseña segura para volver a ingresar a tu cuenta.'
                                  : _isRequiredChange
                                      ? 'Tu cuenta usa una contraseña temporal. Debes cambiarla para activar el acceso.'
                                  : _isWorkshopAccount
                                      ? 'Estás recuperando la cuenta de taller $_email. Este flujo aplica cuando el taller todavía usa su contraseña temporal inicial.'
                                      : 'Estás recuperando la cuenta de $_email. Define una nueva contraseña segura para continuar.',
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.45,
                                color: Color(0xFF55637C),
                              ),
                            ),
                            const SizedBox(height: 18),
                            _PasswordTips(
                              isWorkshopAccount: _isWorkshopAccount,
                            ),
                            const SizedBox(height: 22),
                            _PasswordField(
                              controller: _passwordController,
                              label: 'Nueva contraseña',
                              obscureText: _obscurePassword,
                              onToggleVisibility: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              onChanged: () {
                                if (_errorMessage != null) {
                                  setState(() => _errorMessage = null);
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            _PasswordField(
                              controller: _confirmPasswordController,
                              label: 'Confirmar contraseña',
                              obscureText: _obscureConfirmPassword,
                              onToggleVisibility: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                              onChanged: () {
                                if (_errorMessage != null) {
                                  setState(() => _errorMessage = null);
                                }
                              },
                            ),
                            const SizedBox(height: 18),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: _errorMessage == null
                                  ? const SizedBox.shrink()
                                  : Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF0EF),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: const Color(0xFFFFC7C2),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.error_outline_rounded,
                                            color: Color(0xFFD14130),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              _errorMessage!,
                                              style: const TextStyle(
                                                color: Color(0xFFD14130),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 22),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _isSaving ? null : _submit,
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF123F78),
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Guardar nueva contraseña',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.center,
                                child: TextButton(
                                  onPressed: _isSaving
                                    ? null
                                    : _isRequiredChange
                                        ? () => Navigator.of(context)
                                            .pushNamedAndRemoveUntil(
                                              AppRoutes.login,
                                              (route) => false,
                                            )
                                        : () => Navigator.of(context).pop(),
                                child: const Text(
                                  'Volver al login',
                                  style: TextStyle(color: Color(0xFF123F78)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ResetTopBar extends StatelessWidget {
  const _ResetTopBar({
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          decoration: const BoxDecoration(
            color: Color(0x26FFFFFF),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF123F78),
            ),
          ),
        ),
        const Spacer(),
        const Text(
          'Seguridad',
          style: TextStyle(
            color: Color(0xFF123F78),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ResetHero extends StatelessWidget {
  const _ResetHero();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 220,
        height: 150,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 220,
              height: 130,
              decoration: BoxDecoration(
                color: const Color(0x30FFFFFF),
                borderRadius: BorderRadius.circular(34),
              ),
            ),
            Positioned(
              left: 18,
              bottom: 12,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFF123F78),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ),
            Positioned(
              right: 16,
              top: 14,
              child: Container(
                width: 112,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Cuenta protegida',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF123F78),
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Actualiza tu clave y vuelve a ingresar con normalidad.',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.35,
                        color: Color(0xFF55637C),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Positioned(
              right: 38,
              bottom: 18,
              child: _MiniLockCard(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniLockCard extends StatelessWidget {
  const _MiniLockCard();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 74,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 74,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEE),
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          Positioned(
            top: 0,
            child: Container(
              width: 32,
              height: 26,
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF123F78),
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          const Positioned(
            bottom: 12,
            child: Icon(
              Icons.key_rounded,
              color: Color(0xFFD8AD20),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordTips extends StatelessWidget {
  const _PasswordTips({
    required this.isWorkshopAccount,
  });

  final bool isWorkshopAccount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7DB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7D28A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.verified_user_rounded,
            color: Color(0xFF123F78),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isWorkshopAccount
                  ? 'Para talleres este flujo solo funciona si la cuenta sigue usando la contraseña temporal inicial y ya fue habilitada.'
                  : 'Para clientes puedes restablecer la contraseña con tu correo. La nueva clave debe tener al menos 6 caracteres.',
              style: TextStyle(
                color: Color(0xFF55637C),
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscureText,
    required this.onToggleVisibility,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final VoidCallback onToggleVisibility;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      onChanged: (_) => onChanged(),
      decoration: loginDecoration(
        hintText: label,
        icon: Icons.lock_outline_rounded,
        suffixIcon: IconButton(
          onPressed: onToggleVisibility,
          icon: Icon(
            obscureText
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            color: const Color(0xFF123F78),
          ),
        ),
      ),
    );
  }
}
