import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../config/api_config.dart';
import '../models/workshop_models.dart';

class WorkshopService {
  const WorkshopService._();

  static Future<List<WorkshopMapPoint>> fetchWorkshops() async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    final uri = Uri.http(ApiConfig.backendAuthority, ApiConfig.workshopMapPath);

    try {
      final request = await client.getUrl(uri).timeout(
            const Duration(seconds: 10),
          );
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      final response =
          await request.close().timeout(const Duration(seconds: 10));
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const [];
      }

      if (responseBody.trim().isEmpty) {
        return const [];
      }

      final decoded = jsonDecode(responseBody);
      final rawList = switch (decoded) {
        List<dynamic> value => value,
        Map<String, dynamic> value when value['items'] is List<dynamic> =>
          value['items'] as List<dynamic>,
        Map<String, dynamic> value when value['workshops'] is List<dynamic> =>
          value['workshops'] as List<dynamic>,
        Map<String, dynamic> value when value['talleres'] is List<dynamic> =>
          value['talleres'] as List<dynamic>,
        Map<String, dynamic> value when value['data'] is List<dynamic> =>
          value['data'] as List<dynamic>,
        _ => const <dynamic>[],
      };

      final points = <WorkshopMapPoint>[];
      for (final item in rawList) {
        if (item is! Map<String, dynamic>) {
          continue;
        }

        try {
          final approvalStatus = item['approval_status']?.toString().trim();
          final point = WorkshopMapPoint.fromJson(item);
          final isActive = approvalStatus == null ||
              approvalStatus.isEmpty ||
              approvalStatus.toLowerCase() == 'activo';

          if (!isActive) {
            continue;
          }

          points.add(point);
        } catch (_) {
          // Ignoramos puntos mal formados para no romper el mapa completo.
        }
      }

      return points;
    } on SocketException {
      return const [];
    } on TimeoutException {
      return const [];
    } catch (_) {
      return const [];
    } finally {
      client.close(force: true);
    }
  }
}
