import 'package:flutter/material.dart';

import '../app_routes.dart';
import '../models/auth_models.dart';
import '../services/fake_auth_service.dart';
import '../utils/login_decoration.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController(
    text: 'cliente@emergencias.bo',
  );
  final TextEditingController _passwordController = TextEditingController(
    text: 'cliente123',
  );

  String? _errorMessage;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Completa todos los campos.');
      return;
    }

    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(email)) {
      setState(() => _errorMessage = 'Ingresa un correo válido.');
      return;
    }

    if (password.length < 6) {
      setState(() => _errorMessage = 'La contraseña debe tener al menos 6 caracteres.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await FakeAuthService.signIn(
      email: email,
      password: password,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      _errorMessage = result.errorMessage;
    });

    if (!result.isSuccess) {
      return;
    }

    final user = result.user!;
    final routeName = switch (user.role) {
      UserRole.client => AppRoutes.clientHome,
      UserRole.workshop => AppRoutes.workshopHome,
      UserRole.admin => AppRoutes.dashboard,
    };

    Navigator.of(context).pushReplacementNamed(routeName, arguments: user);
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EMERGENCIAS\nVEHICULARES',
                            style: TextStyle(
                              fontSize: 34,
                              height: 0.98,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Conecta con talleres cercanos mediante IA',
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.4,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
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
                          Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: const Color(0x14D8AD20),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.car_repair_rounded,
                                  color: Color(0xFF123F78),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Inicia sesión',
                                  style: TextStyle(
                                    fontSize: 24,
                                    height: 1.05,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF123F78),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Accede a tu cuenta para continuar con la asistencia.',
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.4,
                              color: Color(0xFF55637C),
                            ),
                          ),
                          const SizedBox(height: 28),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: loginDecoration(
                              hintText: 'Correo electrónico',
                              icon: Icons.mail_outline_rounded,
                            ),
                            onChanged: (_) {
                              if (_errorMessage != null) {
                                setState(() => _errorMessage = null);
                              }
                            },
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: loginDecoration(
                              hintText: 'Contraseña',
                              icon: Icons.lock_outline_rounded,
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: const Color(0xFF123F78),
                                ),
                              ),
                            ),
                            onChanged: (_) {
                              if (_errorMessage != null) {
                                setState(() => _errorMessage = null);
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
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
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _isLoading ? null : _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF123F78),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Iniciar Sesión',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.center,
                            child: TextButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Flujo de recuperación en construcción.'),
                                  ),
                                );
                              },
                              child: const Text(
                                '¿Olvidaste tu contraseña?',
                                style: TextStyle(color: Color(0xFF123F78)),
                              ),
                            ),
                          ),
                          const Divider(height: 18),
                          Align(
                            alignment: Alignment.center,
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pushNamed(
                                AppRoutes.registration,
                              ),
                              child: const Text(
                                'Registrarse como cliente',
                                style: TextStyle(color: Color(0xFF123F78)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7DB),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFFFE082)),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Accesos de prueba',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF123F78),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text('Cliente: cliente@emergencias.bo / cliente123'),
                                Text('Taller: taller@emergencias.bo / taller123'),
                                Text('Administrador: admin@emergencias.bo / admin123'),
                                Text('Suspendido: suspendido@emergencias.bo / suspendido123'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
