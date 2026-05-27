class WorkshopMapPoint {
  const WorkshopMapPoint({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.specialty,
    this.zone,
    this.address,
    this.phone,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String? specialty;
  final String? zone;
  final String? address;
  final String? phone;

  factory WorkshopMapPoint.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['workshop_id'] ?? json['uuid'] ?? '')
        .toString()
        .trim();
    final name = (json['name'] ??
            json['workshop_name'] ??
            json['full_name'] ??
            'Taller sin nombre')
        .toString()
        .trim();
    final zone = json['zone']?.toString().trim();
    final specialty = json['specialty']?.toString().trim();
    final address = json['address']?.toString().trim();

    return WorkshopMapPoint(
      id: id.isEmpty ? name : id,
      name: name.isEmpty ? 'Taller sin nombre' : name,
      latitude: _toDouble(
        json['latitude'] ?? json['lat'] ?? json['y'],
      ),
      longitude: _toDouble(
        json['longitude'] ?? json['lng'] ?? json['lon'] ?? json['x'],
      ),
      specialty: specialty?.isEmpty == true ? null : specialty,
      zone: zone?.isEmpty == true ? null : zone,
      address: address?.isEmpty == true ? zone : address,
      phone: json['phone']?.toString(),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.parse(value.toString());
  }
}
