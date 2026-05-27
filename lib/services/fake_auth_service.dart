import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../config/api_config.dart';
import '../models/auth_models.dart';

class FakeAuthService {
  static final List<FakeAuthUser> _users = [
    FakeAuthUser(
      email: 'cliente@emergencias.bo',
      password: 'cliente123',
      status: 'active',
      role: UserRole.client,
      displayName: 'Cliente A1',
    ),
    FakeAuthUser(
      email: 'juan@gmail.com',
      password: 'acb123*',
      status: 'pending',
      role: UserRole.workshop,
      displayName: 'Juan',
    ),
    FakeAuthUser(
      email: 'taller@emergencias.bo',
      password: 'taller123',
      status: 'active',
      role: UserRole.workshop,
      displayName: 'Taller A2',
    ),
    FakeAuthUser(
      email: 'admin@emergencias.bo',
      password: 'admin123',
      status: 'active',
      role: UserRole.admin,
      displayName: 'Administrador A3',
    ),
    FakeAuthUser(
      email: 'suspendido@emergencias.bo',
      password: 'suspendido123',
      status: 'suspended',
      role: UserRole.client,
      displayName: 'Usuario suspendido',
    ),
  ];

  static Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    FakeAuthUser? localUser;
    for (final item in _users) {
      if (item.email == normalizedEmail) {
        localUser = item;
        break;
      }
    }

    final backendResult = await _signInWithBackend(
      email: normalizedEmail,
      password: password,
    );
    if (backendResult.isSuccess) {
      return backendResult;
    }
    if (backendResult.requiresPasswordChange) {
      return backendResult;
    }

    // Solo usamos fallback local para accesos demo no-client o cuando el backend
    // no pudo responder. Un error real del backend debe verse tal cual en la app.
    if (backendResult.errorMessage?.isNotEmpty ?? false) {
      if (localUser != null && localUser.role != UserRole.client) {
        await Future<void>.delayed(const Duration(milliseconds: 250));

        if (localUser.password != password) {
          return AuthResult.failure('Correo o contraseña incorrectos');
        }

        if (localUser.role == UserRole.workshop && password == 'acb123*') {
          return AuthResult.passwordChangeRequired(localUser);
        }

        if (localUser.status != 'active') {
          return AuthResult.failure('El taller todavía no fue habilitado por el administrador.');
        }

        return AuthResult.success(localUser);
      }

      return backendResult;
    }

    if (localUser == null) {
      return AuthResult.failure(
        'No se pudo conectar con el servicio de inicio de sesión.',
      );
    }

    await Future<void>.delayed(const Duration(milliseconds: 250));

    if (localUser.password != password) {
      return AuthResult.failure('Correo o contraseña incorrectos');
    }

    if (localUser.role == UserRole.workshop && password == 'acb123*') {
      return AuthResult.passwordChangeRequired(localUser);
    }

    if (localUser.status != 'active') {
      return AuthResult.failure('El taller todavía no fue habilitado por el administrador.');
    }

    return AuthResult.success(localUser);
  }

  static Future<bool> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final normalizedEmail = email.trim().toLowerCase();
    final index = _users.indexWhere((item) => item.email == normalizedEmail);
    if (index == -1) {
      return false;
    }

    final currentUser = _users[index];
    _users[index] = currentUser.copyWith(
      password: newPassword,
      status: currentUser.role == UserRole.workshop ? 'active' : currentUser.status,
    );
    return true;
  }

  static Future<AuthResult> _signInWithBackend({
    required String email,
    required String password,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    // POST /api/auth/login
    // El backend espera credenciales en JSON y responde usuario + tokens.
    final uri = Uri.http(ApiConfig.backendAuthority, ApiConfig.loginPath);

    try {
      final request = await client.postUrl(uri).timeout(
            const Duration(seconds: 10),
          );
      request.headers.contentType = ContentType.json;
      request.add(
        // Payload mínimo requerido por el backend para autenticar.
        utf8.encode(
          jsonEncode({
            'email': email,
            'password': password,
          }),
        ),
      );

      final response =
          await request.close().timeout(const Duration(seconds: 10));
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 401) {
        return AuthResult.failure('Correo o contraseña incorrectos');
      }

      if (response.statusCode == 403) {
        return AuthResult.failure('Cuenta suspendida');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return AuthResult.failure(_extractMessage(responseBody));
      }

      // Se toma del backend el usuario autenticado y los tokens de acceso.
      final decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) {
        return AuthResult.failure('Respuesta inválida del backend.');
      }

      final role = _parseRole(decoded['role']?.toString());
      if (role == null) {
        return AuthResult.failure(
          'No se pudo validar el tipo de cuenta devuelto por el backend.',
        );
      }
      final user = FakeAuthUser(
        id: decoded['id'] as int?,
        email: decoded['email']?.toString() ?? email,
        status: decoded['status']?.toString() ?? 'active',
        role: role,
        displayName: decoded['full_name']?.toString() ?? email,
        phone: decoded['phone']?.toString(),
        accessToken: decoded['access_token']?.toString(),
        tokenType: decoded['token_type']?.toString(),
      );

      final requiresPasswordChange =
          decoded['requires_password_change'] == true;
      if (requiresPasswordChange) {
        return AuthResult.passwordChangeRequired(user);
      }

      if (user.status != 'active') {
        return AuthResult.failure(
          'Cuenta suspendida',
        );
      }

      return AuthResult.success(user);
    } on SocketException {
      return AuthResult.failure('');
    } on TimeoutException {
      return AuthResult.failure('');
    } catch (_) {
      return AuthResult.failure('');
    } finally {
      client.close(force: true);
    }
  }

  static UserRole? _parseRole(String? role) {
    return switch (role) {
      'client' => UserRole.client,
      'cliente' => UserRole.client,
      'workshop' => UserRole.workshop,
      'taller' => UserRole.workshop,
      'admin' => UserRole.admin,
      'administrador' => UserRole.admin,
      _ => null,
    };
  }

  static String _extractMessage(String responseBody) {
    if (responseBody.trim().isEmpty) {
      return 'No se pudo iniciar sesión.';
    }

    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];
        if (detail is String && detail.trim().isNotEmpty) {
          return detail.trim();
        }
      }
    } catch (_) {
      return responseBody.trim();
    }

    return responseBody.trim();
  }
}
