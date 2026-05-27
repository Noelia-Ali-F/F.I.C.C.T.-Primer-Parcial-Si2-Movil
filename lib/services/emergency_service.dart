import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../config/api_config.dart';
import '../models/emergency_models.dart';

class EmergencySubmissionResponse {
  const EmergencySubmissionResponse({
    required this.isSuccess,
    required this.message,
    required this.statusCode,
    this.incidentId,
  });

  final bool isSuccess;
  final String message;
  final int statusCode;
  final String? incidentId;
}

class EmergencyService {
  const EmergencyService._();

  static Future<List<EmergencyHistoryItem>> fetchClientEmergencies(
    int clientId,
  ) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    final uri = Uri.http(
      ApiConfig.backendAuthority,
      ApiConfig.emergencyRegistrationPath,
    );

    try {
      final request = await client.getUrl(uri).timeout(
            const Duration(seconds: 15),
          );
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      final response =
          await request.close().timeout(const Duration(seconds: 20));
      final responseBody = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const <EmergencyHistoryItem>[];
      }

      final decoded = jsonDecode(responseBody);
      if (decoded is! List<dynamic>) {
        return const <EmergencyHistoryItem>[];
      }

      // El backend lista todo; el filtro por cliente se resuelve del lado móvil con el user autenticado.
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(EmergencyHistoryItem.fromJson)
          .where((item) => item.clientId == clientId)
          .toList(growable: false);
    } on SocketException {
      return const <EmergencyHistoryItem>[];
    } on TimeoutException {
      return const <EmergencyHistoryItem>[];
    } catch (_) {
      return const <EmergencyHistoryItem>[];
    } finally {
      client.close(force: true);
    }
  }

  static Future<EmergencySubmissionResponse> submitEmergency(
    EmergencyDraft draft,
  ) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    // POST /api/emergencias
    // El backend recibe un multipart con campos de texto, photos repetido y
    // audio opcional en un único envío.
    final uri = Uri.http(
      ApiConfig.backendAuthority,
      ApiConfig.emergencyRegistrationPath,
    );
    const boundary = '----flutter-emergency-form-boundary';

    try {
      final request = await client.postUrl(uri).timeout(
            const Duration(seconds: 15),
          );

      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'multipart/form-data; boundary=$boundary',
      );
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      // Si el usuario ya inició sesión, la API acepta el Bearer token.
      final token = draft.user.accessToken?.trim();
      if (token != null && token.isNotEmpty) {
        final type = (draft.user.tokenType?.trim().isNotEmpty ?? false)
            ? draft.user.tokenType!.trim()
            : 'Bearer';
        request.headers.set(HttpHeaders.authorizationHeader, '$type $token');
      }

      // El backend espera multipart/form-data y el campo photos repetido por archivo.
      void writeField(String name, String value) {
        request.write('--$boundary\r\n');
        request.write('Content-Disposition: form-data; name="$name"\r\n\r\n');
        request.write('$value\r\n');
      }

      final clientId = draft.user.id;
      if (clientId != null) {
        writeField('client_id', clientId.toString());
      }

      // Campos de texto del contrato final validado con el backend web.
      writeField('vehicle_name', draft.vehicleName);
      writeField('vehicle_plate', draft.vehiclePlate);
      writeField('problem_type', draft.problemType);
      if ((draft.description ?? '').trim().isNotEmpty) {
        writeField('description', draft.description!.trim());
      }
      if (draft.latitude != null) {
        writeField('latitude', draft.latitude!.toString());
      }
      if (draft.longitude != null) {
        writeField('longitude', draft.longitude!.toString());
      }
      if ((draft.address ?? '').trim().isNotEmpty) {
        writeField('address', draft.address!.trim());
      }
      if ((draft.zone ?? '').trim().isNotEmpty) {
        writeField('zone', draft.zone!.trim());
      }
      if ((draft.nearestWorkshopId ?? '').trim().isNotEmpty) {
        writeField('nearest_workshop_id', draft.nearestWorkshopId!.trim());
      }
      if ((draft.nearestWorkshopName ?? '').trim().isNotEmpty) {
        writeField('nearest_workshop_name', draft.nearestWorkshopName!.trim());
      }
      if ((draft.nearestWorkshopSpecialty ?? '').trim().isNotEmpty) {
        writeField(
          'nearest_workshop_specialty',
          draft.nearestWorkshopSpecialty!.trim(),
        );
      }
      if ((draft.nearestWorkshopZone ?? '').trim().isNotEmpty) {
        writeField('nearest_workshop_zone', draft.nearestWorkshopZone!.trim());
      }
      if (draft.nearestWorkshopDistanceMeters != null) {
        writeField(
          'nearest_workshop_distance_meters',
          draft.nearestWorkshopDistanceMeters!.toStringAsFixed(2),
        );
      }
      if (draft.price != null) {
        // price viaja junto con la emergencia para que backend pueda persistirlo en BD.
        writeField('price', draft.price!.toString());
      }
      if (draft.audioDurationSeconds != null) {
        writeField(
          'audio_duration_seconds',
          draft.audioDurationSeconds!.toString(),
        );
      }

      // photos debe repetirse una vez por cada imagen seleccionada.
      for (final photoPath in draft.photoPaths) {
        await _writeFileField(
          request: request,
          boundary: boundary,
          fieldName: 'photos',
          path: photoPath,
        );
      }

      if (draft.hasAudio) {
        // audio viaja como un solo archivo opcional separado de photos.
        await _writeFileField(
          request: request,
          boundary: boundary,
          fieldName: 'audio',
          path: draft.audioPath!,
        );
      }

      request.write('--$boundary--\r\n');

      final response =
          await request.close().timeout(const Duration(seconds: 30));
      final responseBody = await response.transform(utf8.decoder).join();
      // El backend puede responder con id, detail o message según el caso.
      final parsedMessage = _extractMessage(responseBody);
      final incidentId = _extractIncidentId(responseBody);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return EmergencySubmissionResponse(
          isSuccess: true,
          message: parsedMessage.isEmpty
              ? 'Emergencia enviada correctamente.'
              : parsedMessage,
          statusCode: response.statusCode,
          incidentId: incidentId,
        );
      }

      return EmergencySubmissionResponse(
        isSuccess: false,
        message: parsedMessage.isEmpty
            ? 'El backend respondió con estado ${response.statusCode}.'
            : parsedMessage,
        statusCode: response.statusCode,
        incidentId: incidentId,
      );
    } on SocketException {
      return const EmergencySubmissionResponse(
        isSuccess: false,
        message:
            'No se pudo conectar con el backend para enviar la emergencia.',
        statusCode: 0,
      );
    } on TimeoutException {
      return const EmergencySubmissionResponse(
        isSuccess: false,
        message:
            'El backend tardó demasiado en responder al enviar la emergencia.',
        statusCode: 0,
      );
    } catch (_) {
      return const EmergencySubmissionResponse(
        isSuccess: false,
        message: 'Ocurrió un error inesperado al enviar la emergencia.',
        statusCode: 0,
      );
    } finally {
      client.close(force: true);
    }
  }

  static Future<void> _writeFileField({
    required HttpClientRequest request,
    required String boundary,
    required String fieldName,
    required String path,
  }) async {
    if (path.trim().isEmpty) {
      return;
    }

    final file = File(path);
    if (!await file.exists()) {
      return;
    }

    final fileName = file.uri.pathSegments.isNotEmpty
        ? file.uri.pathSegments.last
        : 'attachment';
    // Se infiere el MIME para que el backend valide correctamente foto/audio.
    final mimeType = _guessMimeType(fileName);

    request.write('--$boundary\r\n');
    request.write(
      'Content-Disposition: form-data; name="$fieldName"; filename="$fileName"\r\n',
    );
    request.write('Content-Type: $mimeType\r\n\r\n');
    request.add(await file.readAsBytes());
    request.write('\r\n');
  }

  static String _guessMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lower.endsWith('.m4a')) {
      return 'audio/mp4';
    }
    if (lower.endsWith('.aac')) {
      return 'audio/aac';
    }
    if (lower.endsWith('.mp3')) {
      return 'audio/mpeg';
    }
    if (lower.endsWith('.wav')) {
      return 'audio/wav';
    }
    if (lower.endsWith('.ogg')) {
      return 'audio/ogg';
    }
    if (lower.endsWith('.webm')) {
      return 'audio/webm';
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
        // Soporta detail/message simples y respuestas de validación por campo.
        final directMessage = decoded['message'] ?? decoded['detail'];
        if (directMessage is String && directMessage.trim().isNotEmpty) {
          return directMessage.trim();
        }

        if (directMessage is List && directMessage.isNotEmpty) {
          return directMessage.first.toString();
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

        if (decoded.isNotEmpty) {
          final firstValue = decoded.values.first;
          if (firstValue is List && firstValue.isNotEmpty) {
            return firstValue.first.toString();
          }
          if (firstValue is String && firstValue.trim().isNotEmpty) {
            return firstValue.trim();
          }
        }
      }
    } catch (_) {
      return responseBody.trim();
    }

    return responseBody.trim();
  }

  static String? _extractIncidentId(String responseBody) {
    if (responseBody.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        final directId =
            decoded['id'] ?? decoded['incident_id'] ?? decoded['uuid'];
        if (directId != null) {
          return directId.toString();
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }
}
