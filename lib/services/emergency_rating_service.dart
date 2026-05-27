import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class EmergencyRatingService {
  EmergencyRatingService._();

  static const String _storageFileName = 'emergency_ratings.json';

  static Future<Map<int, int>> loadRatings() async {
    try {
      final file = await _storageFile();
      if (!await file.exists()) {
        return const <int, int>{};
      }

      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return const <int, int>{};
      }

      final ratings = <int, int>{};
      for (final entry in decoded.entries) {
        final emergencyId = int.tryParse(entry.key);
        final rating = _parseRating(entry.value);
        if (emergencyId == null || rating == null) {
          continue;
        }
        ratings[emergencyId] = rating;
      }
      return ratings;
    } catch (_) {
      return const <int, int>{};
    }
  }

  static Future<void> saveRating({
    required int emergencyId,
    required int rating,
  }) async {
    final ratings = await loadRatings();
    ratings[emergencyId] = rating.clamp(1, 5);
    await _persistRatings(ratings);
  }

  static Future<File> _storageFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_storageFileName');
  }

  static Future<void> _persistRatings(Map<int, int> ratings) async {
    try {
      final file = await _storageFile();
      final payload = <String, int>{};
      for (final entry in ratings.entries) {
        payload[entry.key.toString()] = entry.value;
      }
      await file.writeAsString(jsonEncode(payload), flush: true);
    } catch (_) {
      // Si falla la persistencia local, mantenemos la calificación en memoria.
    }
  }

  static int? _parseRating(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString());
  }
}
