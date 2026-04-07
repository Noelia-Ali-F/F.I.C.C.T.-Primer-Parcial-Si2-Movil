import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/auth_models.dart';
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

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          child: SingleChildScrollView(
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
                  padding: const EdgeInsets.all(20),
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
                      const Text(
                        'SOLICITAR EMERGENCIA',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF123F78),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Activa una nueva solicitud y comparte tu ubicación en segundos.',
                        style: TextStyle(
                          color: Color(0xFF55637C),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: _isFetchingLocation ? null : _useCurrentLocation,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF123F78),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                          icon: _isFetchingLocation
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.my_location_rounded),
                          label: const Text('Ubicacion actual'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SantaCruzLocationMap(
                        selectedPoint: _selectedMapPoint,
                        onChanged: (point) {
                          setState(() => _selectedMapPoint = point);
                        },
                        onMapCreated: (controller) {
                          _mapController = controller;
                        },
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7DB),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFEACB63)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
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
                        child: FilledButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.add_alert_rounded),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFD8AD20),
                            foregroundColor: const Color(0xFF123F78),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          label: const Text('Nueva Emergencia'),
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
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: [
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
    required this.onChanged,
    required this.onMapCreated,
  });

  final LatLng selectedPoint;
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
      height: 220,
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
            const Positioned(
              top: 14,
              left: 14,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text(
                    'Santa Cruz, Bolivia',
                    style: TextStyle(
                      color: Color(0xFF1F1F1F),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
      height: 220,
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
