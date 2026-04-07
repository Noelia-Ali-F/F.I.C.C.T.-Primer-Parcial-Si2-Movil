enum UserRole { client, workshop, admin }

class FakeAuthUser {
  const FakeAuthUser({
    required this.email,
    required this.password,
    required this.status,
    required this.role,
    required this.displayName,
  });

  final String email;
  final String password;
  final String status;
  final UserRole role;
  final String displayName;
}

class AuthResult {
  const AuthResult._({
    this.user,
    this.errorMessage,
  });

  final FakeAuthUser? user;
  final String? errorMessage;

  bool get isSuccess => user != null;

  factory AuthResult.success(FakeAuthUser user) => AuthResult._(user: user);

  factory AuthResult.failure(String message) =>
      AuthResult._(errorMessage: message);
}
