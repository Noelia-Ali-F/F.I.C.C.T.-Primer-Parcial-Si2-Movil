import '../models/auth_models.dart';

class FakeAuthService {
  static const List<FakeAuthUser> _users = [
    FakeAuthUser(
      email: 'cliente@emergencias.bo',
      password: 'cliente123',
      status: 'active',
      role: UserRole.client,
      displayName: 'Cliente A1',
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
    await Future<void>.delayed(const Duration(milliseconds: 650));

    final normalizedEmail = email.trim().toLowerCase();
    FakeAuthUser? user;
    for (final item in _users) {
      if (item.email == normalizedEmail) {
        user = item;
        break;
      }
    }

    if (user == null) {
      return AuthResult.failure('Usuario no registrado.');
    }

    if (user.password != password) {
      return AuthResult.failure('Usuario o contraseña incorrectos.');
    }

    if (user.status != 'active') {
      return AuthResult.failure('Cuenta suspendida.');
    }

    return AuthResult.success(user);
  }
}
