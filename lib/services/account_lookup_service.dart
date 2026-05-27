import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../config/api_config.dart';
import '../models/auth_models.dart';

class AccountLookupResult {
  const AccountLookupResult({
    this.accountType,
    this.errorMessage,
  });

  final UserRole? accountType;
  final String? errorMessage;

  bool get hasMatch => accountType != null;
}

class AccountLookupService {
  const AccountLookupService._();

  static Future<AccountLookupResult> findAccountTypeByEmail(
    String email,
  ) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      return const AccountLookupResult();
    }

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    final uri = Uri.http(ApiConfig.backendAuthority, ApiConfig.accountTypePath);

    try {
      final request = await client.postUrl(uri).timeout(
            const Duration(seconds: 10),
          );
      request.headers.contentType = ContentType.json;
      request.add(
        utf8.encode(
          jsonEncode({
            'email': normalizedEmail,
          }),
        ),
      );

      final response =
          await request.close().timeout(const Duration(seconds: 10));
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return AccountLookupResult(
          errorMessage: _extractMessage(responseBody),
        );
      }

      final decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) {
        return const AccountLookupResult();
      }

      final rawRole = (decoded['role'] ??
              decoded['account_type'] ??
              decoded['accountType'] ??
              decoded['type'])
          ?.toString()
          .trim()
          .toLowerCase();

      return AccountLookupResult(
        accountType: _parseRole(rawRole),
      );
    } on SocketException {
      return const AccountLookupResult();
    } on TimeoutException {
      return const AccountLookupResult();
    } catch (_) {
      return const AccountLookupResult();
    } finally {
      client.close(force: true);
    }
  }

  static UserRole? _parseRole(String? rawRole) {
    return switch (rawRole) {
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
      return 'No se pudo validar el tipo de cuenta.';
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
