import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../config/api_config.dart';

class PushDeviceRegistrationService {
  PushDeviceRegistrationService._();

  static int? _currentClientUserId;

  static Future<void> updateCurrentClientUserId(int? userId) async {
    _currentClientUserId = userId;
    if (userId == null) {
      return;
    }

    await syncCurrentToken();
  }

  static Future<void> syncCurrentToken() async {
    final userId = _currentClientUserId;
    if (userId == null) {
      return;
    }

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.trim().isEmpty) {
      log(
        'FCM token aún no disponible para registrar.',
        name: 'PushDeviceRegistrationService',
      );
      return;
    }

    await _registerToken(
      userId: userId,
      token: token.trim(),
    );
  }

  static Future<void> registerRefreshedToken(String token) async {
    final userId = _currentClientUserId;
    if (userId == null || token.trim().isEmpty) {
      return;
    }

    await _registerToken(
      userId: userId,
      token: token.trim(),
    );
  }

  static Future<void> _registerToken({
    required int userId,
    required String token,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    final uri = Uri.http(ApiConfig.backendAuthority, ApiConfig.fcmTokenPath);

    try {
      final request = await client.postUrl(uri).timeout(
            const Duration(seconds: 10),
          );
      request.headers.contentType = ContentType.json;
      request.add(
        utf8.encode(
          jsonEncode({
            'user_id': userId,
            'fcm_token': token,
            'platform': 'android',
          }),
        ),
      );

      final response =
          await request.close().timeout(const Duration(seconds: 10));
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        log(
          'No se pudo registrar FCM token. '
          'status=${response.statusCode} body=$responseBody',
          name: 'PushDeviceRegistrationService',
        );
        return;
      }

      log(
        'FCM token registrado para user_id=$userId body=$responseBody',
        name: 'PushDeviceRegistrationService',
      );
    } on SocketException catch (error) {
      log(
        'Sin conexión al registrar FCM token: $error',
        name: 'PushDeviceRegistrationService',
      );
    } on TimeoutException catch (error) {
      log(
        'Timeout al registrar FCM token: $error',
        name: 'PushDeviceRegistrationService',
      );
    } catch (error, stackTrace) {
      log(
        'Error inesperado al registrar FCM token: $error',
        name: 'PushDeviceRegistrationService',
        stackTrace: stackTrace,
      );
    } finally {
      client.close(force: true);
    }
  }
}
