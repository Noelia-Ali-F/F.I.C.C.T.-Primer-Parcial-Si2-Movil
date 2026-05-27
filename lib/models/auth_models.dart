enum UserRole { client, workshop, admin }

class FakeAuthUser {
  const FakeAuthUser({
    required this.email,
    required this.status,
    required this.role,
    required this.displayName,
    this.password = '',
    this.phone,
    this.id,
    this.accessToken,
    this.tokenType,
  });

  final String email;
  final String password;
  final String status;
  final UserRole role;
  final String displayName;
  final String? phone;
  final int? id;
  final String? accessToken;
  final String? tokenType;

  FakeAuthUser copyWith({
    String? email,
    String? password,
    String? status,
    UserRole? role,
    String? displayName,
    String? phone,
    int? id,
    String? accessToken,
    String? tokenType,
  }) {
    return FakeAuthUser(
      email: email ?? this.email,
      password: password ?? this.password,
      status: status ?? this.status,
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      id: id ?? this.id,
      accessToken: accessToken ?? this.accessToken,
      tokenType: tokenType ?? this.tokenType,
    );
  }
}

class AuthResult {
  const AuthResult._({
    this.user,
    this.errorMessage,
    this.requiresPasswordChange = false,
  });

  final FakeAuthUser? user;
  final String? errorMessage;
  final bool requiresPasswordChange;

  bool get isSuccess => user != null && !requiresPasswordChange;

  factory AuthResult.success(FakeAuthUser user) => AuthResult._(user: user);

  factory AuthResult.passwordChangeRequired(FakeAuthUser user) =>
      AuthResult._(
        user: user,
        requiresPasswordChange: true,
      );

  factory AuthResult.failure(String message) =>
      AuthResult._(errorMessage: message);
}
