class VehicleRegistrationData {
  const VehicleRegistrationData({
    required this.clientId,
    required this.brand,
    required this.model,
    required this.year,
    required this.plate,
    required this.color,
    required this.isPrimary,
    this.photoPath,
  });

  final int clientId;
  final String brand;
  final String model;
  final int year;
  final String plate;
  final String color;
  final bool isPrimary;
  final String? photoPath;
}

class VehicleRegistrationResponse {
  const VehicleRegistrationResponse({
    required this.isSuccess,
    required this.message,
    required this.statusCode,
    this.vehicleId,
    this.photoUrl,
  });

  final bool isSuccess;
  final String message;
  final int statusCode;
  final int? vehicleId;
  final String? photoUrl;
}

class VehicleDeleteResponse {
  const VehicleDeleteResponse({
    required this.isSuccess,
    required this.message,
    required this.statusCode,
  });

  final bool isSuccess;
  final String message;
  final int statusCode;
}

class VehicleUpdateResponse {
  const VehicleUpdateResponse({
    required this.isSuccess,
    required this.message,
    required this.statusCode,
    this.vehicle,
  });

  final bool isSuccess;
  final String message;
  final int statusCode;
  final VehicleRecord? vehicle;
}

class VehicleRecord {
  const VehicleRecord({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.plate,
    required this.color,
    required this.isPrimary,
    this.photoPath,
    this.photoUrl,
  });

  final int? id;
  final String brand;
  final String model;
  final int year;
  final String plate;
  final String color;
  final bool isPrimary;
  final String? photoPath;
  final String? photoUrl;

  String get summary => '$brand $model $year · $plate';

  factory VehicleRecord.fromJson(Map<String, dynamic> json) {
    return VehicleRecord(
      id: json['id'] as int?,
      brand: json['brand']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      year: (json['year'] as num?)?.toInt() ?? 0,
      plate: json['plate']?.toString() ?? '',
      color: json['color']?.toString() ?? '',
      isPrimary: json['is_primary'] == true,
      photoPath: json['photo_path']?.toString(),
      photoUrl: json['photo_url']?.toString(),
    );
  }
}
