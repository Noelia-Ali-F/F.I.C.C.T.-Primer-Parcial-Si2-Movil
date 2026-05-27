import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../app_routes.dart';
import '../models/auth_models.dart';
import 'emergency_request_screen.dart';
import 'otp_request_screen.dart';
import 'password_reset_screen.dart';
import '../services/account_lookup_service.dart';
import '../services/fake_auth_service.dart';
import '../services/push_device_registration_service.dart';
import '../utils/login_decoration.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const String _rememberedLoginFileName = 'remembered_login.json';
  static const int _maxLoginAttempts = 3;
  static const Duration _loginLockDuration = Duration(seconds: 30);

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _errorMessage;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  int _failedLoginAttempts = 0;
  DateTime? _loginLockedUntil;
  Timer? _loginLockTimer;

  UserRole get _selectedRole => UserRole.client;
  bool get _isLoginLocked =>
      _loginLockedUntil != null && DateTime.now().isBefore(_loginLockedUntil!);
  int get _remainingLoginAttempts =>
      (_maxLoginAttempts - _failedLoginAttempts).clamp(0, _maxLoginAttempts);
  int get _remainingLockSeconds {
    final lockedUntil = _loginLockedUntil;
    if (lockedUntil == null) {
      return 0;
    }
    final seconds = lockedUntil.difference(DateTime.now()).inSeconds;
    return seconds > 0 ? seconds : 0;
  }

  @override
  void initState() {
    super.initState();
    _loadRememberedLogin();
  }

  @override
  void dispose() {
    _loginLockTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<File> _rememberedLoginFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_rememberedLoginFileName');
  }

  Future<void> _loadRememberedLogin() async {
    try {
      final file = await _rememberedLoginFile();
      if (!await file.exists()) {
        return;
      }

      final rawContent = await file.readAsString();
      final decoded = jsonDecode(rawContent);
      if (decoded is! Map<String, dynamic>) {
        return;
      }

      final remember = decoded['remember_me'] == true;
      final email = decoded['email']?.toString() ?? '';
      final password = decoded['password']?.toString() ?? '';

      if (!mounted || !remember) {
        return;
      }

      setState(() {
        _rememberMe = true;
        _emailController.text = email;
        _passwordController.text = password;
      });
    } catch (_) {
      // Si el archivo guardado está corrupto, continuamos con el login normal.
    }
  }

  Future<void> _persistRememberedLogin() async {
    final file = await _rememberedLoginFile();

    if (!_rememberMe) {
      if (await file.exists()) {
        await file.delete();
      }
      return;
    }

    await file.writeAsString(
      jsonEncode({
        'remember_me': true,
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
      }),
    );
  }

  Future<void> _handleRememberChanged(bool? value) async {
    final shouldRemember = value ?? false;

    setState(() => _rememberMe = shouldRemember);

    if (!shouldRemember) {
      try {
        await _persistRememberedLogin();
      } catch (_) {
        // Ignoramos errores de limpieza local para no bloquear la UI.
      }
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    // El bloqueo es puramente del lado móvil para frenar intentos repetidos en la UI.
    if (_isLoginLocked) {
      setState(() {
        _errorMessage =
            'Has superado los $_maxLoginAttempts intentos. Intenta de nuevo en $_remainingLockSeconds s.';
      });
      return;
    }

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
      setState(() =>
          _errorMessage = 'La contraseña debe tener al menos 6 caracteres.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final accountLookup =
        await AccountLookupService.findAccountTypeByEmail(email);

    if (!mounted) {
      return;
    }

    if (accountLookup.hasMatch &&
        accountLookup.accountType != _selectedRole &&
        accountLookup.accountType != UserRole.admin) {
      setState(() {
        _isLoading = false;
        _errorMessage = accountLookup.accountType == UserRole.client
            ? 'Ese correo pertenece a un cliente.'
            : 'Este acceso móvil es solo para clientes.';
      });
      return;
    }

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

    if (result.requiresPasswordChange) {
      _resetLoginAttemptState();
      final user = result.user!;
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.passwordReset,
        arguments: PasswordResetArgs(
          email: user.email,
          accountType: user.role,
          isRequiredChange: true,
        ),
      );
      return;
    }

    if (!result.isSuccess) {
      // Cada fallo consume un intento y puede disparar el bloqueo temporal.
      _registerFailedLoginAttempt();
      return;
    }

    // Un login correcto limpia el contador y el tiempo de bloqueo.
    _resetLoginAttemptState();

    try {
      await _persistRememberedLogin();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo guardar la preferencia de Recordar.'),
          ),
        );
      }
    }

    if (!mounted) {
      return;
    }

    final user = result.user!;
    await PushDeviceRegistrationService.updateCurrentClientUserId(
      user.role == UserRole.client ? user.id : null,
    );

    if (user.role != UserRole.client) {
      setState(() {
        _errorMessage = 'Este acceso es solo para clientes.';
      });
      return;
    }

    if (user.role == UserRole.client) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => EmergencyRequestScreen(
            args: EmergencyRequestArgs(
              user: user,
              clientId: user.id,
            ),
          ),
        ),
      );
      return;
    }

    final routeName = switch (user.role) {
      UserRole.client => AppRoutes.clientHome,
      UserRole.workshop => AppRoutes.workshopHome,
      UserRole.admin => AppRoutes.dashboard,
    };

    Navigator.of(context).pushReplacementNamed(routeName, arguments: user);
  }

  void _registerFailedLoginAttempt() {
    final nextAttempts = _failedLoginAttempts + 1;
    if (nextAttempts >= _maxLoginAttempts) {
      _startLoginLock();
      return;
    }

    setState(() {
      _failedLoginAttempts = nextAttempts;
      final remaining = _maxLoginAttempts - nextAttempts;
      _errorMessage =
          '${_errorMessage ?? 'No se pudo iniciar sesión.'} Intentos restantes: $remaining.';
    });
  }

  void _startLoginLock() {
    _loginLockTimer?.cancel();
    final lockedUntil = DateTime.now().add(_loginLockDuration);
    setState(() {
      _failedLoginAttempts = _maxLoginAttempts;
      _loginLockedUntil = lockedUntil;
      _errorMessage =
          'Has superado los $_maxLoginAttempts intentos. Intenta de nuevo en ${_loginLockDuration.inSeconds} s.';
    });

    // El timer solo refresca el mensaje visual mientras dura el enfriamiento.
    _loginLockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (!_isLoginLocked) {
        timer.cancel();
        setState(() {
          _failedLoginAttempts = 0;
          _loginLockedUntil = null;
          if (_errorMessage != null &&
              _errorMessage!
                  .contains('Has superado los $_maxLoginAttempts intentos')) {
            _errorMessage = null;
          }
        });
        return;
      }

      setState(() {
        _errorMessage =
            'Has superado los $_maxLoginAttempts intentos. Intenta de nuevo en $_remainingLockSeconds s.';
      });
    });
  }

  void _resetLoginAttemptState() {
    _loginLockTimer?.cancel();
    _failedLoginAttempts = 0;
    _loginLockedUntil = null;
  }

  Future<void> _openForgotPasswordFlow() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Ingresa tu correo antes de recuperar la contraseña.';
      });
      return;
    }

    if (!emailPattern.hasMatch(email)) {
      setState(() => _errorMessage = 'Ingresa un correo válido.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final accountLookup =
        await AccountLookupService.findAccountTypeByEmail(email);

    if (!mounted) {
      return;
    }

    setState(() => _isLoading = false);

    if (accountLookup.hasMatch &&
        accountLookup.accountType != _selectedRole &&
        accountLookup.accountType != UserRole.admin) {
      setState(() {
        _errorMessage = accountLookup.accountType == UserRole.client
            ? 'Ese correo pertenece a un cliente.'
            : 'La recuperación desde esta app está disponible solo para clientes.';
      });
      return;
    }

    Navigator.of(context).pushNamed(
      AppRoutes.otpRequest,
      arguments: OtpRequestArgs(
        email: email,
        accountType: _selectedRole,
      ),
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
                            'Acceso móvil para clientes con emergencias vehiculares.',
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.4,
                              color: Color(0xFF55637C),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7DB),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFE7D28A),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    Icons.person_rounded,
                                    color: const Color(0xFF123F78),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Esta vista de emergencias vehiculares está disponible únicamente para clientes.',
                                    style: const TextStyle(
                                      color: Color(0xFF55637C),
                                      height: 1.35,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          if (!_isLoginLocked && _failedLoginAttempts > 0)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                'Intentos disponibles: $_remainingLoginAttempts de $_maxLoginAttempts',
                                style: const TextStyle(
                                  color: Color(0xFF123F78),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
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
                          Row(
                            children: [
                              Transform.translate(
                                offset: const Offset(-10, 0),
                                child: Checkbox(
                                  value: _rememberMe,
                                  activeColor: const Color(0xFF123F78),
                                  onChanged: _isLoading
                                      ? null
                                      : (value) =>
                                          _handleRememberChanged(value),
                                ),
                              ),
                              const Expanded(
                                child: Text(
                                  'Recordar',
                                  style: TextStyle(
                                    color: Color(0xFF123F78),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
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
                              onPressed: (_isLoading || _isLoginLocked)
                                  ? null
                                  : _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF123F78),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
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
                              onPressed:
                                  _isLoading ? null : _openForgotPasswordFlow,
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
