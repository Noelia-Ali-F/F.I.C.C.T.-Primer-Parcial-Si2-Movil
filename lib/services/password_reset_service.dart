import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../config/api_config.dart';
import 'fake_auth_service.dart';

class PasswordResetResult {
  const PasswordResetResult({
    required this.isSuccess,
    this.errorMessage,
  });

  final bool isSuccess;
  final String? errorMessage;
}

class PasswordResetService {
  const PasswordResetService._();

  static Future<PasswordResetResult> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    final backendResult = await _resetPasswordWithBackend(
      email: normalizedEmail,
      newPassword: newPassword,
    );
    if (backendResult.isSuccess) {
      return backendResult;
    }

    final localReset = await FakeAuthService.resetPassword(
      email: normalizedEmail,
      newPassword: newPassword,
    );
    if (localReset) {
      return const PasswordResetResult(isSuccess: true);
    }

    return PasswordResetResult(
      isSuccess: false,
      errorMessage: backendResult.errorMessage ??
          'No se encontró una cuenta para $normalizedEmail.',
    );
  }

  static Future<PasswordResetResult> _resetPasswordWithBackend({
    required String email,
    required String newPassword,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    final uri = Uri.http(
      ApiConfig.backendAuthority,
      ApiConfig.forgotPasswordPath,
    );

    try {
      final request = await client.postUrl(uri).timeout(
            const Duration(seconds: 10),
          );
      request.headers.contentType = ContentType.json;
      request.add(
        utf8.encode(
          jsonEncode({
            'email': email,
            'new_password': newPassword,
            'confirm_password': newPassword,
          }),
        ),
      );

      final response =
          await request.close().timeout(const Duration(seconds: 10));
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const PasswordResetResult(isSuccess: true);
      }

      return PasswordResetResult(
        isSuccess: false,
        errorMessage: _extractMessage(responseBody),
      );
    } on SocketException {
      return const PasswordResetResult(isSuccess: false);
    } on TimeoutException {
      return const PasswordResetResult(isSuccess: false);
    } catch (_) {
      return const PasswordResetResult(isSuccess: false);
    } finally {
      client.close(force: true);
    }
  }

  static String _extractMessage(String responseBody) {
    if (responseBody.trim().isEmpty) {
      return 'No se pudo actualizar la contraseña.';
    }

    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'] ?? decoded['message'];
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
