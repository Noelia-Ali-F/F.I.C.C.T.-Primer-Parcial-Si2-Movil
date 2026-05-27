import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../config/api_config.dart';

class RouteService {
  const RouteService._();

  static Future<List<LatLng>> computeDrivingRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 12);
    final uri =
        Uri.https('routes.googleapis.com', '/directions/v2:computeRoutes');

    try {
      final request = await client.postUrl(uri).timeout(
            const Duration(seconds: 12),
          );
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set(
        'X-Goog-Api-Key',
        ApiConfig.googleRoutesApiKey,
      );
      request.headers.set(
        'X-Goog-FieldMask',
        'routes.polyline.encodedPolyline',
      );

      request.write(
        jsonEncode({
          'origin': {
            'location': {
              'latLng': {
                'latitude': origin.latitude,
                'longitude': origin.longitude,
              },
            },
          },
          'destination': {
            'location': {
              'latLng': {
                'latitude': destination.latitude,
                'longitude': destination.longitude,
              },
            },
          },
          'travelMode': 'DRIVE',
          'routingPreference': 'TRAFFIC_AWARE',
          'polylineQuality': 'HIGH_QUALITY',
          'polylineEncoding': 'ENCODED_POLYLINE',
          'languageCode': 'es-419',
        }),
      );

      final response =
          await request.close().timeout(const Duration(seconds: 12));
      final responseBody = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const <LatLng>[];
      }

      final decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) {
        return const <LatLng>[];
      }

      final routes = decoded['routes'];
      if (routes is! List || routes.isEmpty) {
        return const <LatLng>[];
      }

      final route = routes.first;
      if (route is! Map<String, dynamic>) {
        return const <LatLng>[];
      }

      final polyline = route['polyline'];
      if (polyline is! Map<String, dynamic>) {
        return const <LatLng>[];
      }

      final encoded = polyline['encodedPolyline']?.toString();
      if (encoded == null || encoded.trim().isEmpty) {
        return const <LatLng>[];
      }

      return _decodePolyline(encoded);
    } on SocketException {
      return const <LatLng>[];
    } on TimeoutException {
      return const <LatLng>[];
    } catch (_) {
      return const <LatLng>[];
    } finally {
      client.close(force: true);
    }
  }

  static List<LatLng> _decodePolyline(String encoded) {
    final coordinates = <LatLng>[];
    var index = 0;
    var latitude = 0;
    var longitude = 0;

    while (index < encoded.length) {
      var shift = 0;
      var result = 0;
      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20 && index < encoded.length);
      final latitudeChange = (result & 1) != 0 ? ~(result >> 1) : result >> 1;
      latitude += latitudeChange;

      shift = 0;
      result = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20 && index < encoded.length);
      final longitudeChange = (result & 1) != 0 ? ~(result >> 1) : result >> 1;
      longitude += longitudeChange;

      coordinates.add(
        LatLng(latitude / 1e5, longitude / 1e5),
      );
    }

    return coordinates;
  }
}
