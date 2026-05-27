import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/workshop_models.dart';
import '../services/route_service.dart';
import '../services/workshop_service.dart';

class TechnicianTrackingMapArgs {
  const TechnicianTrackingMapArgs({
    required this.emergencyId,
    required this.workshopId,
    required this.workshopName,
    this.technicianId,
    this.technicianName,
    this.incidentDescription,
    this.latitude,
    this.longitude,
  });

  final String emergencyId;
  final String workshopId;
  final String workshopName;
  final String? technicianId;
  final String? technicianName;
  final String? incidentDescription;
  final double? latitude;
  final double? longitude;
}

class TechnicianTrackingMapScreen extends StatefulWidget {
  const TechnicianTrackingMapScreen({
    super.key,
    required this.args,
  });

  final TechnicianTrackingMapArgs args;

  @override
  State<TechnicianTrackingMapScreen> createState() =>
      _TechnicianTrackingMapScreenState();
}

class _TechnicianTrackingMapScreenState
    extends State<TechnicianTrackingMapScreen> {
  static const LatLng _defaultSantaCruzLocation = LatLng(-17.7833, -63.1821);
  static const int _simulationSteps = 36;

  GoogleMapController? _mapController;
  bool _isLoading = true;
  bool _isSimulationRunning = false;
  String? _errorMessage;
  WorkshopMapPoint? _workshopPoint;
  LatLng? _clientPoint;
  LatLng? _technicianStartPoint;
  LatLng? _technicianCurrentPoint;
  List<LatLng> _routePoints = const <LatLng>[];
  double _simulationProgress = 0;
  Timer? _simulationTimer;

  bool get _supportsNativeMap {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  LatLng get _targetPoint {
    if (widget.args.latitude != null && widget.args.longitude != null) {
      return LatLng(widget.args.latitude!, widget.args.longitude!);
    }
    if (_workshopPoint != null) {
      return LatLng(_workshopPoint!.latitude, _workshopPoint!.longitude);
    }
    return _defaultSantaCruzLocation;
  }

  LatLng? get _destinationPoint => _clientPoint;

  String get _subtitle {
    final technicianName = widget.args.technicianName?.trim();
    final incidentDescription = widget.args.incidentDescription?.trim();

    if ((technicianName ?? '').isNotEmpty &&
        (incidentDescription ?? '').isNotEmpty) {
      return '$technicianName atenderá: $incidentDescription';
    }
    if ((technicianName ?? '').isNotEmpty) {
      return '$technicianName fue asignado a tu emergencia.';
    }
    if ((incidentDescription ?? '').isNotEmpty) {
      return 'Incidente reportado: $incidentDescription';
    }
    return 'Ubicación actual del taller asignado.';
  }

  @override
  void initState() {
    super.initState();
    _bootstrapMap();
  }

  Future<void> _bootstrapMap() async {
    // El mapa necesita tres piezas: punto inicial del técnico, punto destino del cliente y ruta por calles.
    await _loadWorkshopLocation();
    await _loadClientLocation();
    if (!mounted) {
      return;
    }
    await _loadRoadRoute();
    if (!mounted) {
      return;
    }
    _startSimulation();
  }

  Future<void> _loadWorkshopLocation() async {
    if (widget.args.latitude != null && widget.args.longitude != null) {
      // Si la push ya trae coordenadas, las usamos como posición inicial del técnico.
      final initialPoint =
          LatLng(widget.args.latitude!, widget.args.longitude!);
      setState(() {
        _technicianStartPoint = initialPoint;
        _technicianCurrentPoint = initialPoint;
        _isLoading = false;
      });
      return;
    }

    try {
      final workshops = await WorkshopService.fetchWorkshops();
      final point = workshops.cast<WorkshopMapPoint?>().firstWhere(
            (item) =>
                item != null &&
                (item.id == widget.args.workshopId ||
                    item.name.toLowerCase() ==
                        widget.args.workshopName.toLowerCase()),
            orElse: () => null,
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _workshopPoint = point;
        if (point != null) {
          _technicianStartPoint = LatLng(point.latitude, point.longitude);
          _technicianCurrentPoint = _technicianStartPoint;
        }
        _isLoading = false;
        _errorMessage = point == null
            ? 'No se pudo ubicar el taller asignado en el mapa.'
            : null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'No se pudo cargar la ubicación del taller asignado.';
      });
    }
  }

  Future<void> _loadClientLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      const locationSettings =
          LocationSettings(accuracy: LocationAccuracy.high);
      final position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        // El destino de la simulación es la ubicación actual del cliente en el dispositivo.
        _clientPoint = LatLng(position.latitude, position.longitude);
      });
    } catch (_) {
      // Si falla la ubicación del cliente, mantenemos la simulación con el punto por defecto.
    }
  }

  Future<void> _loadRoadRoute() async {
    final start = _technicianStartPoint;
    final end = _destinationPoint;
    if (start == null || end == null) {
      _routePoints = const <LatLng>[];
      return;
    }

    // Si Google Routes responde, la simulación seguirá avenidas/calles reales en lugar de línea recta.
    final route = await RouteService.computeDrivingRoute(
      origin: start,
      destination: end,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _routePoints =
          route.length >= 2 ? _downsampleRoute(route) : const <LatLng>[];
    });
  }

  void _startSimulation() {
    final start = _technicianStartPoint;
    final end = _destinationPoint;
    if (start == null || end == null) {
      return;
    }

    // La animación consume la polilínea real o, si falla, una interpolación simple como respaldo.
    final simulationPoints = _simulationPathPoints(start, end);
    if (simulationPoints.length < 2) {
      return;
    }

    _simulationTimer?.cancel();
    _fitMapToPoints(simulationPoints);
    setState(() {
      _simulationProgress = 0;
      _technicianCurrentPoint = simulationPoints.first;
      _isSimulationRunning = true;
    });

    var currentIndex = 0;
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 700), (
      timer,
    ) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      currentIndex++;
      if (currentIndex >= simulationPoints.length) {
        timer.cancel();
        setState(() {
          _simulationProgress = 1;
          _technicianCurrentPoint = simulationPoints.last;
          _isSimulationRunning = false;
        });
        return;
      }

      final nextPoint = simulationPoints[currentIndex];
      final progress = currentIndex / (simulationPoints.length - 1);
      setState(() {
        _simulationProgress = progress;
        _technicianCurrentPoint = nextPoint;
      });

      // La cámara acompaña al técnico para reforzar visualmente el "en camino".
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(nextPoint),
      );
    });
  }

  Future<void> _fitMapToPoints(List<LatLng> points) async {
    if (points.isEmpty) {
      return;
    }

    var minLatitude = points.first.latitude;
    var maxLatitude = points.first.latitude;
    var minLongitude = points.first.longitude;
    var maxLongitude = points.first.longitude;

    for (final point in points.skip(1)) {
      if (point.latitude < minLatitude) {
        minLatitude = point.latitude;
      }
      if (point.latitude > maxLatitude) {
        maxLatitude = point.latitude;
      }
      if (point.longitude < minLongitude) {
        minLongitude = point.longitude;
      }
      if (point.longitude > maxLongitude) {
        maxLongitude = point.longitude;
      }
    }

    final southWest = LatLng(minLatitude, minLongitude);
    final northEast = LatLng(maxLatitude, maxLongitude);

    await Future<void>.delayed(const Duration(milliseconds: 200));
    await _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: southWest, northeast: northEast),
        84,
      ),
    );
  }

  List<LatLng> _simulationPathPoints(LatLng start, LatLng end) {
    if (_routePoints.length >= 2) {
      return _routePoints;
    }

    return List<LatLng>.generate(_simulationSteps + 1, (index) {
      final progress = index / _simulationSteps;
      return LatLng(
        start.latitude + (end.latitude - start.latitude) * progress,
        start.longitude + (end.longitude - start.longitude) * progress,
      );
    }, growable: false);
  }

  List<LatLng> _downsampleRoute(List<LatLng> points) {
    if (points.length <= 48) {
      return List<LatLng>.from(points, growable: false);
    }

    final sampled = <LatLng>[];
    final lastIndex = points.length - 1;
    for (var i = 0; i < 48; i++) {
      final pointIndex = (i * lastIndex / 47).round();
      sampled.add(points[pointIndex]);
    }
    return sampled;
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    final technicianPoint = _technicianCurrentPoint;
    if (technicianPoint != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('assigned-technician'),
          position: technicianPoint,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: InfoWindow(
            title: widget.args.technicianName?.trim().isNotEmpty == true
                ? widget.args.technicianName
                : widget.args.workshopName,
            snippet: _isSimulationRunning
                ? 'En camino al cliente'
                : 'Llegó al punto del cliente',
          ),
        ),
      );
    }

    final clientPoint = _destinationPoint;
    if (clientPoint != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('client-location'),
          position: clientPoint,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
          infoWindow: const InfoWindow(
            title: 'Tu ubicación',
            snippet: 'Punto de atención del cliente',
          ),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _buildPolylines() {
    final route = _routePoints;
    if (route.length >= 2) {
      // La ruta real solo se dibuja si la API devolvió una polilínea válida.
      return {
        Polyline(
          polylineId: const PolylineId('technician-route'),
          points: route,
          width: 6,
          color: const Color(0xFF123F78),
        ),
      };
    }

    final start = _technicianCurrentPoint;
    final end = _destinationPoint;
    if (start == null || end == null) {
      return const <Polyline>{};
    }

    return {
      Polyline(
        polylineId: const PolylineId('technician-route'),
        points: [start, end],
        width: 6,
        color: const Color(0xFF123F78),
        patterns: [
          PatternItem.dash(20),
          PatternItem.gap(10),
        ],
      ),
    };
  }

  String get _progressLabel {
    final percentage = (_simulationProgress * 100).round();
    if (_isSimulationRunning) {
      return 'En camino · $percentage%';
    }
    if (_simulationProgress >= 1) {
      return 'Técnico llegó al cliente';
    }
    return 'Esperando inicio de recorrido';
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final targetPoint = _targetPoint;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: _supportsNativeMap
                ? GoogleMap(
                    onMapCreated: (controller) => _mapController = controller,
                    initialCameraPosition: CameraPosition(
                      target: targetPoint,
                      zoom: 15.5,
                    ),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: false,
                    compassEnabled: true,
                    markers: _buildMarkers(),
                    polylines: _buildPolylines(),
                  )
                : Container(
                    color: const Color(0xFF123F78),
                    alignment: Alignment.center,
                    child: const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'El mapa en tiempo real solo está disponible en Android o iOS.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FloatingMapButton(
                      icon: Icons.arrow_back_rounded,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x260B285A),
                              blurRadius: 22,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Técnico asignado',
                              style: TextStyle(
                                color: Color(0xFF123F78),
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.args.workshopName,
                              style: const TextStyle(
                                color: Color(0xFF101828),
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _subtitle,
                              style: const TextStyle(
                                color: Color(0xFF55637C),
                                fontSize: 14,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(
                                  Icons.route_rounded,
                                  color: Color(0xFF123F78),
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Emergencia #${widget.args.emergencyId}',
                                    style: const TextStyle(
                                      color: Color(0xFF344054),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            LinearProgressIndicator(
                              value: _simulationProgress == 0 &&
                                      !_isSimulationRunning
                                  ? null
                                  : _simulationProgress,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(999),
                              backgroundColor: const Color(0xFFE5EAF1),
                              color: const Color(0xFF123F78),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _progressLabel,
                              style: const TextStyle(
                                color: Color(0xFF123F78),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x26000000),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          if (_errorMessage != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x220B285A),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Color(0xFF344054),
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FloatingMapButton extends StatelessWidget {
  const _FloatingMapButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 8,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(icon, color: const Color(0xFF123F78)),
        ),
      ),
    );
  }
}
