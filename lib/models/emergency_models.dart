import 'auth_models.dart';

class EmergencyDraft {
  const EmergencyDraft({
    required this.user,
    required this.vehicleName,
    required this.vehiclePlate,
    required this.problemType,
    required this.photoPaths,
    this.description,
    this.audioPath,
    this.audioDurationSeconds,
    this.latitude,
    this.longitude,
    this.address,
    this.zone,
    this.nearestWorkshopId,
    this.nearestWorkshopName,
    this.nearestWorkshopSpecialty,
    this.nearestWorkshopZone,
    this.nearestWorkshopDistanceMeters,
    this.price,
  });

  final FakeAuthUser user;
  final String vehicleName;
  final String vehiclePlate;
  final String problemType;
  final String? description;
  final List<String> photoPaths;
  final String? audioPath;
  final double? audioDurationSeconds;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? zone;
  final String? nearestWorkshopId;
  final String? nearestWorkshopName;
  final String? nearestWorkshopSpecialty;
  final String? nearestWorkshopZone;
  final double? nearestWorkshopDistanceMeters;
  final int? price;

  bool get hasAudio => audioPath != null && audioPath!.trim().isNotEmpty;
}

class EmergencyReviewArgs {
  const EmergencyReviewArgs({
    required this.draft,
    required this.zone,
    required this.latitude,
    required this.longitude,
  });

  final EmergencyDraft draft;
  final String zone;
  final double latitude;
  final double longitude;
}

class EmergencyHistoryItem {
  const EmergencyHistoryItem({
    required this.id,
    required this.clientId,
    required this.vehicleName,
    required this.vehiclePlate,
    required this.problemType,
    required this.emergencyStatus,
    required this.createdAt,
    this.price,
    this.description,
    this.zone,
    this.address,
    this.assignedTechnicianName,
    this.assignmentStatus,
  });

  final int id;
  final int clientId;
  final String vehicleName;
  final String vehiclePlate;
  final String problemType;
  final String emergencyStatus;
  final DateTime createdAt;
  final int? price;
  final String? description;
  final String? zone;
  final String? address;
  final String? assignedTechnicianName;
  final String? assignmentStatus;

  factory EmergencyHistoryItem.fromJson(Map<String, dynamic> json) {
    return EmergencyHistoryItem(
      id: _toInt(json['id']),
      clientId: _toInt(json['client_id']),
      vehicleName:
          (json['vehicle_name'] ?? 'Vehículo sin nombre').toString().trim(),
      vehiclePlate: (json['vehicle_plate'] ?? 'Sin placa').toString().trim(),
      problemType: (json['problem_type'] ?? 'Sin tipo').toString().trim(),
      emergencyStatus:
          (json['emergency_status'] ?? 'pendiente').toString().trim(),
      createdAt: DateTime.tryParse(
            (json['created_at'] ?? '').toString(),
          ) ??
          DateTime.now(),
      price: _tryToInt(json['price']),
      description: json['description']?.toString().trim(),
      zone: json['zone']?.toString().trim(),
      address: json['address']?.toString().trim(),
      assignedTechnicianName:
          json['assigned_technician_name']?.toString().trim(),
      assignmentStatus: json['assignment_status']?.toString().trim(),
    );
  }

  static int _toInt(dynamic value) {
    final parsed = _tryToInt(value);
    if (parsed == null) {
      throw const FormatException('No se pudo convertir a entero');
    }
    return parsed;
  }

  static int? _tryToInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString());
  }
}
