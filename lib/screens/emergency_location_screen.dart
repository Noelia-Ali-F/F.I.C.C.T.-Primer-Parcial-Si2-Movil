import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class EmergencyLocationScreen extends StatefulWidget {
  const EmergencyLocationScreen({super.key});

  @override
  State<EmergencyLocationScreen> createState() => _EmergencyLocationScreenState();
}

class _EmergencyLocationScreenState extends State<EmergencyLocationScreen> {
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
        _showMessage('Activa la ubicacion del dispositivo para marcar tu posicion actual.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showMessage('Debes aceptar el permiso de ubicacion para usar tu posicion actual.');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showMessage('El permiso de ubicacion fue bloqueado. Habilitalo desde ajustes.');
        return;
      }

      const locationSettings = LocationSettings(accuracy: LocationAccuracy.high);
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
      _showMessage('No se pudo obtener tu ubicacion actual en este momento.');
    } finally {
      if (mounted) {
        setState(() => _isFetchingLocation = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showSuccessDialog() async {
    await showGeneralDialog<void>(
      context: context,
      barrierLabel: 'Registro exitoso',
      barrierDismissible: true,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) => const _EmergencySuccessDialog(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Confirma tu ubicación para completar el registro de la emergencia.',
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
                            child: IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                color: Color(0xFF123F78),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Registrar Emergencia',
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
                            _EmergencyLocationMap(
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
                                      onPressed: () async {
                                        await _showSuccessDialog();
                                        if (!mounted) {
                                          return;
                                        }
                                        Navigator.of(context).popUntil((route) => route.isFirst);
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
                                        'REGISTRAR EMERGENCIA',
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
              ],
            ),
          ),
        ),
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

class _EmergencyLocationMap extends StatelessWidget {
  const _EmergencyLocationMap({
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
                target: _EmergencyLocationScreenState._defaultSantaCruzLocation,
                zoom: 12.8,
              ),
              mapType: MapType.normal,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
              compassEnabled: true,
              buildingsEnabled: true,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF98A2B3),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF101828),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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

class _EmergencySuccessDialog extends StatelessWidget {
  const _EmergencySuccessDialog();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 260,
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
          decoration: BoxDecoration(
            color: const Color(0xFFFFCC16),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 24,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFFFFCC16),
                  size: 34,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '¡Éxito!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Tu emergencia fue registrada correctamente.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: 98,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Aceptar',
                    style: TextStyle(fontWeight: FontWeight.w800),
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
