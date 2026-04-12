import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../app_routes.dart';
import '../models/auth_models.dart';
import 'emergency_request_screen.dart';
import 'vehicle_management_screen.dart';
import 'vehicle_registration_screen.dart';
import '../utils/logout_dialog.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key, required this.user});

  final FakeAuthUser user;

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  static const LatLng _defaultSantaCruzLocation = LatLng(-17.7833, -63.1821);

  LatLng _selectedMapPoint = _defaultSantaCruzLocation;
  GoogleMapController? _mapController;
  bool _isFetchingLocation = false;
  int _selectedTabIndex = 0;
  final List<String> _vehicles = <String>[
    'Toyota Corolla 2019 · 4578KPL',
    'Suzuki Vitara 2021 · 8231RBS',
  ];

  String get _selectedZone => _resolveSantaCruzZone(_selectedMapPoint);

  Future<void> _useCurrentLocation() async {
    if (_isFetchingLocation) {
      return;
    }

    setState(() => _isFetchingLocation = true);

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _showLocationMessage(
          'Activa la ubicacion del dispositivo para marcar tu posicion actual.',
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showLocationMessage(
          'Debes aceptar el permiso de ubicacion para usar tu posicion actual.',
        );
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationMessage(
          'El permiso de ubicacion fue bloqueado. Habilitalo desde ajustes.',
        );
        return;
      }

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
      );
      final position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
      final currentPoint = LatLng(position.latitude, position.longitude);

      if (!mounted) {
        return;
      }

      setState(() => _selectedMapPoint = currentPoint);

      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: currentPoint, zoom: 16),
        ),
      );
    } catch (_) {
      _showLocationMessage(
        'No se pudo obtener tu ubicacion actual en este momento.',
      );
    } finally {
      if (mounted) {
        setState(() => _isFetchingLocation = false);
      }
    }
  }

  void _showLocationMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openVehicleRegistrationScreen() async {
    final result = await Navigator.of(context).push<VehicleRegistrationResult>(
      MaterialPageRoute(
        builder: (_) => const VehicleRegistrationScreen(),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      if (result.isPrimary) {
        _vehicles.insert(0, '${result.summary} · Principal');
      } else {
        _vehicles.add(result.summary);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vehículo agregado correctamente.'),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0x24FFFFFF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cliente (A1)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      widget.user.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: IconButton(
                  onPressed: () => showLogoutDialog(context),
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFF123F78),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Solicita asistencia, revisa tu historial y sigue tus emergencias en tiempo real.',
            style: TextStyle(
              color: Colors.white,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x160B285A),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F7FB),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Color(0xFF123F78),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Obtén tu ubicación',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF101828),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFD),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE7ECF3)),
                  ),
                  child: Column(
                    children: [
                      _SantaCruzLocationMap(
                        selectedPoint: _selectedMapPoint,
                        zone: _selectedZone,
                        isFetchingLocation: _isFetchingLocation,
                        onCurrentLocationTap: _isFetchingLocation
                            ? null
                            : _useCurrentLocation,
                        onChanged: (point) {
                          setState(() => _selectedMapPoint = point);
                        },
                        onMapCreated: (controller) {
                          _mapController = controller;
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F7FB),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: const Color(0xFFDCE5F0)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF123F78),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.place_rounded,
                                      color: Color(0xFFD8AD20),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Ubicacion marcada',
                                          style: TextStyle(
                                            color: Color(0xFF123F78),
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Santa Cruz de la Sierra, Bolivia · $_selectedZone',
                                          style: const TextStyle(
                                            color: Color(0xFF55637C),
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () {
                                  Navigator.of(context).pushNamed(
                                    AppRoutes.emergencyRequest,
                                    arguments: EmergencyRequestArgs(
                                      location: _selectedMapPoint,
                                      zone: _selectedZone,
                                    ),
                                  );
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF123F78),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 17),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                child: const Text(
                                  'CONTINUAR',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Historial de solicitudes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF123F78),
            ),
          ),
          const SizedBox(height: 12),
          const _HistoryCard(
            title: 'Batería descargada',
            subtitle: 'Equipetrol - hace 2 horas',
            status: 'Completado',
          ),
          const SizedBox(height: 12),
          const _HistoryCard(
            title: 'Neumático pinchado',
            subtitle: 'Av. Banzer - ayer',
            status: 'Atendido',
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderContent({
    required String title,
    required IconData icon,
    required String message,
  }) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x160B285A),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54, color: const Color(0xFF123F78)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF123F78),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF55637C),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x160B285A),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'BIENVENIDO',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF101828),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFD),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE7ECF3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFDCE5F0),
                            width: 3,
                          ),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFE9EEF6), Color(0xFFC7D2E5)],
                          ),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 42,
                          color: Color(0xFF123F78),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.user.displayName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF101828),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.user.email,
                              style: const TextStyle(
                                color: Color(0xFF66758C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _ProfileActionTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Mi cuenta',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sección de cuenta disponible próximamente.'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _ProfileActionTile(
                  icon: Icons.directions_car_filled_outlined,
                  title: 'Mis Vehículos',
                  highlighted: true,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => VehicleManagementScreen(
                          initialVehicles: _vehicles,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                ..._vehicles.map(
                  (vehicle) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFD),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFDCE5F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.directions_car_filled_rounded,
                            color: Color(0xFF123F78),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              vehicle,
                              style: const TextStyle(
                                color: Color(0xFF123F78),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                _ProfileActionTile(
                  icon: Icons.logout_rounded,
                  title: 'Cerrar sesión',
                  onTap: () => showLogoutDialog(context),
                ),
                const SizedBox(height: 12),
                _ProfileActionTile(
                  icon: Icons.add_circle_outline_rounded,
                  title: 'Agregar Vehículo',
                  onTap: _openVehicleRegistrationScreen,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _openVehicleRegistrationScreen,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4D8E50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text(
                      'Agregar Vehículo',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = switch (_selectedTabIndex) {
      0 => _buildHomeContent(),
      1 => _buildPlaceholderContent(
          title: 'Historial',
          icon: Icons.history_rounded,
          message: 'Aquí verás el detalle de tus asistencias y emergencias anteriores.',
        ),
      2 => _buildPlaceholderContent(
          title: 'Alertas',
          icon: Icons.notifications_active_rounded,
          message: 'Aquí llegarán avisos del taller, estado de la asistencia y novedades importantes.',
        ),
      _ => _buildProfileContent(),
    };

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFD8AD20),
              Color(0xFFF0C630),
              Color(0xFFF8D74E),
            ],
          ),
        ),
        child: SafeArea(
          child: body,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTabIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedTabIndex = index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.history_rounded), label: 'Historial'),
          NavigationDestination(icon: Icon(Icons.notifications_rounded), label: 'Alertas'),
          NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Perfil'),
        ],
      ),
    );
  }
}

String _resolveSantaCruzZone(LatLng point) {
  if (point.latitude > -17.765 && point.longitude < -63.19) {
    return 'Norte integrado';
  }
  if (point.latitude <= -17.765 &&
      point.latitude > -17.79 &&
      point.longitude < -63.185) {
    return 'Equipetrol';
  }
  if (point.latitude > -17.78 &&
      point.longitude >= -63.185 &&
      point.longitude < -63.16) {
    return 'Av. Banzer';
  }
  if (point.longitude >= -63.16 && point.latitude > -17.8) {
    return 'Villa 1ro de Mayo';
  }
  if (point.latitude <= -17.81 && point.longitude < -63.19) {
    return 'Doble Via La Guardia';
  }
  if (point.latitude <= -17.81 && point.longitude >= -63.19) {
    return 'Plan Tres Mil';
  }
  return 'Centro';
}

class _SantaCruzLocationMap extends StatelessWidget {
  const _SantaCruzLocationMap({
    required this.selectedPoint,
    required this.zone,
    required this.isFetchingLocation,
    required this.onCurrentLocationTap,
    required this.onChanged,
    required this.onMapCreated,
  });

  final LatLng selectedPoint;
  final String zone;
  final bool isFetchingLocation;
  final VoidCallback? onCurrentLocationTap;
  final ValueChanged<LatLng> onChanged;
  final ValueChanged<GoogleMapController> onMapCreated;

  bool get _supportsNativeMap {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  Widget build(BuildContext context) {
    if (!_supportsNativeMap) {
      return _UnsupportedMapFallback(selectedPoint: selectedPoint);
    }

    return SizedBox(
      height: 430,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            GoogleMap(
              onMapCreated: onMapCreated,
              initialCameraPosition: const CameraPosition(
                target: _ClientHomeScreenState._defaultSantaCruzLocation,
                zoom: 12.8,
              ),
              mapType: MapType.normal,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
              compassEnabled: true,
              buildingsEnabled: true,
              trafficEnabled: false,
              onTap: onChanged,
              markers: {
                Marker(
                  markerId: const MarkerId('selected-location'),
                  position: selectedPoint,
                  draggable: true,
                  onDragEnd: onChanged,
                  infoWindow: InfoWindow(
                    title: 'Ubicacion marcada',
                    snippet: _resolveSantaCruzZone(selectedPoint),
                  ),
                ),
              },
            ),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _MapInputChip(
                          label: 'Latitud',
                          value: selectedPoint.latitude.toStringAsFixed(5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MapInputChip(
                          label: 'Longitud',
                          value: selectedPoint.longitude.toStringAsFixed(5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 54,
                        child: FilledButton(
                          onPressed: onCurrentLocationTap,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF123F78),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                          ),
                          child: isFetchingLocation
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text(
                                  'IR',
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x14000000),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.centerLeft,
                          child: const Text(
                            'Obtener ubicación',
                            style: TextStyle(
                              color: Color(0xFF101828),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: onCurrentLocationTap,
                          icon: isFetchingLocation
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(
                                  Icons.my_location_rounded,
                                  color: Color(0xFF123F78),
                                ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: onCurrentLocationTap,
                          icon: const Icon(
                            Icons.search_rounded,
                            color: Color(0xFF101828),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x18000000),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Santa Cruz, Bolivia',
                      style: TextStyle(
                        color: Color(0xFF101828),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      zone,
                      style: const TextStyle(color: Color(0xFF667085)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnsupportedMapFallback extends StatelessWidget {
  const _UnsupportedMapFallback({required this.selectedPoint});

  final LatLng selectedPoint;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 430,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF123F78), Color(0xFF2E6BB2)],
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.map_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Mapa real no disponible aqui',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'La vista con Google Maps funciona en Android o iOS con API key configurada.',
            style: TextStyle(
              color: Color(0xE8FFFFFF),
              height: 1.4,
            ),
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0x22FFFFFF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Ubicacion actual: ${selectedPoint.latitude.toStringAsFixed(4)}, ${selectedPoint.longitude.toStringAsFixed(4)}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapInputChip extends StatelessWidget {
  const _MapInputChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF98A2B3),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF101828),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlighted ? const Color(0xFFF7FBFF) : const Color(0xFFFDFDFD),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: highlighted
                  ? const Color(0xFFE06C64)
                  : const Color(0xFFDCE5F0),
              width: highlighted ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF123F78)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF101828),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.title,
    required this.subtitle,
    required this.status,
  });

  final String title;
  final String subtitle;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120B285A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0x14D8AD20),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.car_crash_outlined, color: Color(0xFF123F78)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF123F78),
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Color(0xFF66758C))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0x140B8E43),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              status,
              style: const TextStyle(
                color: Color(0xFF0B8E43),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
