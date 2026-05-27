import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../config/api_config.dart';
import '../models/vehicle_models.dart';

class VehicleService {
  const VehicleService._();

  static Future<List<VehicleRecord>> fetchVehicles({
    int? clientId,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    // GET /api/vehiculos?client_id={id}
    // Recupera la lista de vehículos del cliente desde el backend web.
    final uri = Uri.http(
      ApiConfig.backendAuthority,
      ApiConfig.vehicleRegistrationPath,
      clientId == null ? null : {'client_id': '$clientId'},
    );

    try {
      final request = await client.getUrl(uri).timeout(
            const Duration(seconds: 10),
          );
      final response =
          await request.close().timeout(const Duration(seconds: 10));
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'GET ${uri.path} respondió ${response.statusCode}',
          uri: uri,
        );
      }

      if (responseBody.trim().isEmpty) {
        return const [];
      }

      final decoded = jsonDecode(responseBody);
      final list = switch (decoded) {
        List<dynamic> value => value,
        Map<String, dynamic> value when value['items'] is List<dynamic> =>
          value['items'] as List<dynamic>,
        Map<String, dynamic> value when value['vehicles'] is List<dynamic> =>
          value['vehicles'] as List<dynamic>,
        _ => const <dynamic>[],
      };

      return list
          .whereType<Map<String, dynamic>>()
          .map(VehicleRecord.fromJson)
          .toList();
    } finally {
      client.close(force: true);
    }
  }

  static Future<VehicleRegistrationResponse> registerVehicle(
    VehicleRegistrationData data,
  ) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    // POST /api/vehiculos
    // El backend de vehículos recibe multipart/form-data para combinar campos
    // del formulario y una foto opcional.
    final uri = Uri.http(
      ApiConfig.backendAuthority,
      ApiConfig.vehicleRegistrationPath,
    );
    const boundary = '----flutter-vehicle-form-boundary';

    try {
      final request = await client.postUrl(uri).timeout(
            const Duration(seconds: 10),
          );

      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'multipart/form-data; boundary=$boundary',
      );

      // Campos de texto del multipart requeridos por el backend web.
      void writeField(String name, String value) {
        request.write('--$boundary\r\n');
        request.write(
          'Content-Disposition: form-data; name="$name"\r\n\r\n',
        );
        request.write('$value\r\n');
      }

      writeField('client_id', data.clientId.toString());
      writeField('brand', data.brand);
      writeField('model', data.model);
      writeField('year', data.year.toString());
      writeField('plate', data.plate);
      writeField('color', data.color);
      writeField('is_primary', data.isPrimary.toString());

      if (data.photoPath != null && data.photoPath!.trim().isNotEmpty) {
        // photo viaja como archivo adjunto cuando el usuario selecciona imagen.
        final photoFile = File(data.photoPath!);
        if (await photoFile.exists()) {
          final fileName = photoFile.uri.pathSegments.isNotEmpty
              ? photoFile.uri.pathSegments.last
              : 'vehicle_photo.jpg';
          final mimeType = _guessMimeType(fileName);

          request.write('--$boundary\r\n');
          request.write(
            'Content-Disposition: form-data; name="photo"; filename="$fileName"\r\n',
          );
          request.write('Content-Type: $mimeType\r\n\r\n');
          request.add(await photoFile.readAsBytes());
          request.write('\r\n');
        }
      }

      request.write('--$boundary--\r\n');

      final response =
          await request.close().timeout(const Duration(seconds: 10));
      final responseBody = await response.transform(utf8.decoder).join();
      final parsedMessage = _extractMessage(responseBody);
      final vehicleId = _extractIntValue(responseBody, 'id');
      final photoUrl = _extractStringValue(responseBody, 'photo_url');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return VehicleRegistrationResponse(
          isSuccess: true,
          message: parsedMessage.isEmpty
              ? 'Vehículo registrado correctamente.'
              : parsedMessage,
          statusCode: response.statusCode,
          vehicleId: vehicleId,
          photoUrl: photoUrl,
        );
      }

      return VehicleRegistrationResponse(
        isSuccess: false,
        message: parsedMessage.isEmpty
            ? 'El backend respondió con estado ${response.statusCode}.'
            : parsedMessage,
        statusCode: response.statusCode,
      );
    } on SocketException {
      return const VehicleRegistrationResponse(
        isSuccess: false,
        message:
            'No se pudo conectar con el backend para registrar el vehículo.',
        statusCode: 0,
      );
    } on TimeoutException {
      return const VehicleRegistrationResponse(
        isSuccess: false,
        message:
            'El backend tardó demasiado en responder al registrar el vehículo.',
        statusCode: 0,
      );
    } catch (_) {
      return const VehicleRegistrationResponse(
        isSuccess: false,
        message: 'Ocurrió un error inesperado al registrar el vehículo.',
        statusCode: 0,
      );
    } finally {
      client.close(force: true);
    }
  }

  static Future<VehicleDeleteResponse> deleteVehicle(int vehicleId) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    // DELETE /api/vehiculos/{id}
    // El backend elimina el vehículo indicado y responde con un estado simple.
    final uri = Uri.http(
      ApiConfig.backendAuthority,
      '${ApiConfig.vehicleRegistrationPath}/$vehicleId',
    );

    try {
      final request = await client.deleteUrl(uri).timeout(
            const Duration(seconds: 10),
          );
      final response =
          await request.close().timeout(const Duration(seconds: 10));
      final responseBody = await response.transform(utf8.decoder).join();
      final parsedMessage = _extractMessage(responseBody);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return VehicleDeleteResponse(
          isSuccess: true,
          message: parsedMessage.isEmpty
              ? 'Vehículo eliminado correctamente.'
              : parsedMessage,
          statusCode: response.statusCode,
        );
      }

      return VehicleDeleteResponse(
        isSuccess: false,
        message: parsedMessage.isEmpty
            ? 'El backend respondió con estado ${response.statusCode}.'
            : parsedMessage,
        statusCode: response.statusCode,
      );
    } on SocketException {
      return const VehicleDeleteResponse(
        isSuccess: false,
        message:
            'No se pudo conectar con el backend para eliminar el vehículo.',
        statusCode: 0,
      );
    } on TimeoutException {
      return const VehicleDeleteResponse(
        isSuccess: false,
        message:
            'El backend tardó demasiado en responder al eliminar el vehículo.',
        statusCode: 0,
      );
    } catch (_) {
      return const VehicleDeleteResponse(
        isSuccess: false,
        message: 'Ocurrió un error inesperado al eliminar el vehículo.',
        statusCode: 0,
      );
    } finally {
      client.close(force: true);
    }
  }

  static Future<VehicleUpdateResponse> updateVehicle({
    required int vehicleId,
    required VehicleRegistrationData data,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    // PUT /api/vehiculos/{id}
    // Mantiene el mismo contrato multipart que el alta de vehículos.
    final uri = Uri.http(
      ApiConfig.backendAuthority,
      '${ApiConfig.vehicleRegistrationPath}/$vehicleId',
    );
    const boundary = '----flutter-vehicle-form-boundary';

    try {
      final request = await client.putUrl(uri).timeout(
            const Duration(seconds: 10),
          );

      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'multipart/form-data; boundary=$boundary',
      );

      // Campos de texto del multipart esperados por el backend web.
      void writeField(String name, String value) {
        request.write('--$boundary\r\n');
        request.write(
          'Content-Disposition: form-data; name="$name"\r\n\r\n',
        );
        request.write('$value\r\n');
      }

      writeField('client_id', data.clientId.toString());
      writeField('brand', data.brand);
      writeField('model', data.model);
      writeField('year', data.year.toString());
      writeField('plate', data.plate);
      writeField('color', data.color);
      writeField('is_primary', data.isPrimary.toString());

      if (data.photoPath != null && data.photoPath!.trim().isNotEmpty) {
        // photo es opcional; si no se envía, el backend mantiene la actual.
        final photoFile = File(data.photoPath!);
        if (await photoFile.exists()) {
          final fileName = photoFile.uri.pathSegments.isNotEmpty
              ? photoFile.uri.pathSegments.last
              : 'vehicle_photo.jpg';
          final mimeType = _guessMimeType(fileName);

          request.write('--$boundary\r\n');
          request.write(
            'Content-Disposition: form-data; name="photo"; filename="$fileName"\r\n',
          );
          request.write('Content-Type: $mimeType\r\n\r\n');
          request.add(await photoFile.readAsBytes());
          request.write('\r\n');
        }
      }

      request.write('--$boundary--\r\n');

      final response =
          await request.close().timeout(const Duration(seconds: 10));
      final responseBody = await response.transform(utf8.decoder).join();
      final parsedMessage = _extractMessage(responseBody);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        VehicleRecord? vehicle;
        try {
          final decoded = jsonDecode(responseBody);
          if (decoded is Map<String, dynamic>) {
            vehicle = VehicleRecord.fromJson(decoded);
          }
        } catch (_) {}

        return VehicleUpdateResponse(
          isSuccess: true,
          message: parsedMessage.isEmpty
              ? 'Vehículo actualizado correctamente.'
              : parsedMessage,
          statusCode: response.statusCode,
          vehicle: vehicle,
        );
      }

      return VehicleUpdateResponse(
        isSuccess: false,
        message: parsedMessage.isEmpty
            ? 'El backend respondió con estado ${response.statusCode}.'
            : parsedMessage,
        statusCode: response.statusCode,
      );
    } on SocketException {
      return const VehicleUpdateResponse(
        isSuccess: false,
        message:
            'No se pudo conectar con el backend para actualizar el vehículo.',
        statusCode: 0,
      );
    } on TimeoutException {
      return const VehicleUpdateResponse(
        isSuccess: false,
        message:
            'El backend tardó demasiado en responder al actualizar el vehículo.',
        statusCode: 0,
      );
    } catch (_) {
      return const VehicleUpdateResponse(
        isSuccess: false,
        message: 'Ocurrió un error inesperado al actualizar el vehículo.',
        statusCode: 0,
      );
    } finally {
      client.close(force: true);
    }
  }

  static String _guessMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
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

        if (decoded['id'] != null) {
          return 'Vehículo registrado correctamente.';
        }
      }
    } catch (_) {
      return '';
    }

    return '';
  }

  static int? _extractIntValue(String responseBody, String key) {
    if (responseBody.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        final value = decoded[key];
        if (value is int) {
          return value;
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  static String? _extractStringValue(String responseBody, String key) {
    if (responseBody.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        final value = decoded[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }
}
