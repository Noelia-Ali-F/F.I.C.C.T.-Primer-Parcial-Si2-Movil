import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../config/api_config.dart';
import '../screens/client_registration_form_screen.dart';

class ClientRegistrationResponse {
  const ClientRegistrationResponse({
    required this.isSuccess,
    required this.message,
    required this.statusCode,
    this.clientId,
  });

  final bool isSuccess;
  final String message;
  final int statusCode;
  final int? clientId;
}

class ClientRegistrationService {
  const ClientRegistrationService._();

  static Future<ClientRegistrationResponse> registerClient(
    ClientRegistrationData data,
  ) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    // POST /api/clientes
    // Envía el formulario de registro como JSON para que el backend cree
    // el cliente y devuelva el id generado.
    final uri = Uri.http(
      ApiConfig.backendAuthority,
      ApiConfig.clientRegistrationPath,
    );

    try {
      final request = await client.postUrl(uri).timeout(
            const Duration(seconds: 10),
          );
      request.headers.contentType = ContentType.json;
      request.add(
        // Contrato esperado por el backend web para registro de clientes.
        utf8.encode(
          jsonEncode({
            'identity_card': data.identityCard,
            'full_name': data.fullName,
            'email': data.email,
            'phone': data.phone,
            'password': data.password,
            'confirm_password': data.password,
            'accepted_terms': true,
            'role': 'client',
          }),
        ),
      );

      final response =
          await request.close().timeout(const Duration(seconds: 10));
      final responseBody = await response.transform(utf8.decoder).join();
      // El backend puede devolver message/detail y también el id del cliente.
      final parsedMessage = _extractMessage(responseBody);
      final clientId = _extractClientId(responseBody);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ClientRegistrationResponse(
          isSuccess: true,
          message: parsedMessage.isEmpty
              ? 'Cliente registrado correctamente.'
              : parsedMessage,
          statusCode: response.statusCode,
          clientId: clientId,
        );
      }

      return ClientRegistrationResponse(
        isSuccess: false,
        message: parsedMessage.isEmpty
            ? 'El backend respondió con estado ${response.statusCode}.'
            : parsedMessage,
        statusCode: response.statusCode,
      );
    } on SocketException {
      return const ClientRegistrationResponse(
        isSuccess: false,
        message: 'No se pudo conectar con el backend en 34.71.120.235.',
        statusCode: 0,
      );
    } on TimeoutException {
      return const ClientRegistrationResponse(
        isSuccess: false,
        message: 'El backend tardó demasiado en responder.',
        statusCode: 0,
      );
    } catch (_) {
      return const ClientRegistrationResponse(
        isSuccess: false,
        message: 'Ocurrió un error inesperado al registrar al cliente.',
        statusCode: 0,
      );
    } finally {
      client.close(force: true);
    }
  }

  static String _extractMessage(String responseBody) {
    if (responseBody.trim().isEmpty) {
      return '';
    }

    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        final directMessage = decoded['message'] ?? decoded['detail'];
        if (directMessage is String && directMessage.trim().isNotEmpty) {
          return directMessage.trim();
        }

        final errors = decoded['errors'];
        if (errors is Map<String, dynamic> && errors.isNotEmpty) {
          final firstValue = errors.values.first;
          if (firstValue is List && firstValue.isNotEmpty) {
            return firstValue.first.toString();
          }
          if (firstValue != null) {
            return firstValue.toString();
          }
        }
      }
    } catch (_) {
      return responseBody.trim();
    }

    return responseBody.trim();
  }

  static int? _extractClientId(String responseBody) {
    if (responseBody.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        final id = decoded['id'];
        if (id is int) {
          return id;
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }
}
