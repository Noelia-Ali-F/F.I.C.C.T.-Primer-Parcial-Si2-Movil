import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../app_routes.dart';
import '../models/auth_models.dart';
import '../models/emergency_models.dart';
import '../models/vehicle_models.dart';
import '../services/alert_service.dart';
import '../services/emergency_rating_service.dart';
import '../services/emergency_service.dart';
import '../services/vehicle_service.dart';
import 'emergency_review_screen.dart';
import 'emergency_request_screen.dart';
import 'technician_tracking_map_screen.dart';
import 'vehicle_management_screen.dart';
import 'vehicle_registration_screen.dart';
import '../utils/double_back_logout_scope.dart';
import '../utils/logout_dialog.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({
    super.key,
    required this.user,
    this.initialTabIndex = 0,
    this.emergencyDraft,
  });

  final FakeAuthUser user;
  final int initialTabIndex;
  final EmergencyDraft? emergencyDraft;

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  static const LatLng _defaultSantaCruzLocation = LatLng(-17.7833, -63.1821);
  final GlobalKey<FormState> _vehicleFormKey = GlobalKey<FormState>();

  LatLng _selectedMapPoint = _defaultSantaCruzLocation;
  GoogleMapController? _mapController;
  bool _isFetchingLocation = false;
  bool _isSearchingLocation = false;
  String _selectedAddress = 'Santa Cruz de la Sierra, Bolivia';
  String? _manualDirectionText;
  int _selectedTabIndex = 0;
  final TextEditingController _locationSearchController =
      TextEditingController();
  final TextEditingController _vehicleBrandController = TextEditingController();
  final TextEditingController _vehicleModelController = TextEditingController();
  final TextEditingController _vehicleYearController = TextEditingController(
    text: '2018',
  );
  final TextEditingController _vehiclePlateController = TextEditingController(
    text: '1023HHNNI',
  );
  final List<String> _vehicles = <String>[];
  final List<Color> _vehicleColors = const [
    Color(0xFFF3F4F6),
    Color(0xFF9CA3AF),
    Color(0xFFD6B256),
    Color(0xFF1F2937),
  ];
  int _selectedVehicleColorIndex = 1;
  bool _isPrimaryVehicle = true;
  bool _isSavingVehicle = false;
  bool _isLoadingVehicles = true;
  bool _isLoadingHistory = true;
  List<EmergencyHistoryItem> _emergencyHistory = const [];
  Map<int, int> _emergencyRatings = const <int, int>{};

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;
    _syncSelectedAddress();
    _loadVehicles();
    _loadEmergencyHistory();
    _loadEmergencyRatings();
  }

  String get _selectedZone => _resolveSantaCruzZone(_selectedMapPoint);
  String get _directionText =>
      _manualDirectionText ?? '$_selectedAddress\n$_selectedZone';

  Future<void> _syncSelectedAddress() async {
    try {
      final placemarks = await placemarkFromCoordinates(
        _selectedMapPoint.latitude,
        _selectedMapPoint.longitude,
      );
      if (!mounted || placemarks.isEmpty) {
        return;
      }

      final place = placemarks.first;
      final address = [
        place.street,
        place.subLocality,
        place.locality,
      ].where((value) => (value ?? '').trim().isNotEmpty).join(', ');

      final fallback = [
        place.locality,
        place.administrativeArea,
        place.country,
      ].where((value) => (value ?? '').trim().isNotEmpty).join(', ');

      final resolvedAddress = address.trim().isNotEmpty ? address : fallback;
      if (resolvedAddress.trim().isEmpty) {
        return;
      }

      setState(() => _selectedAddress = resolvedAddress);
    } catch (_) {
      // Si falla la geocodificación inversa, mantenemos la dirección anterior.
    }
  }

  Future<void> _updateSelectedPoint(
    LatLng point, {
    bool moveCamera = false,
  }) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _selectedMapPoint = point;
      _manualDirectionText = null;
    });

    if (moveCamera) {
      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: point, zoom: 16),
        ),
      );
    }

    await _syncSelectedAddress();
  }

  Future<void> _editDirectionText() async {
    final controller = TextEditingController(text: _directionText);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar dirección'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Escribe la dirección completa',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (!mounted || result == null || result.isEmpty) {
      return;
    }

    setState(() => _manualDirectionText = result);
  }

  Future<void> _loadVehicles() async {
    final clientId = widget.user.id;
    if (clientId == null) {
      if (mounted) {
        setState(() => _isLoadingVehicles = false);
      }
      return;
    }

    try {
      final backendVehicles = await VehicleService.fetchVehicles(
        clientId: clientId,
      );
      if (!mounted) {
        return;
      }

      if (backendVehicles.isEmpty) {
        setState(() => _isLoadingVehicles = false);
        return;
      }

      setState(() {
        _vehicles
          ..clear()
          ..addAll(
            backendVehicles.map(
              (vehicle) => vehicle.isPrimary
                  ? '${vehicle.summary} · Principal'
                  : vehicle.summary,
            ),
          );
        _isLoadingVehicles = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoadingVehicles = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudieron cargar los vehículos desde el backend. Se muestran los datos locales.',
          ),
        ),
      );
    }
  }

  Future<void> _loadEmergencyHistory() async {
    final clientId = widget.user.id;
    if (clientId == null) {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
      return;
    }

    setState(() => _isLoadingHistory = true);
    final history = await EmergencyService.fetchClientEmergencies(clientId);
    if (!mounted) {
      return;
    }

    setState(() {
      _emergencyHistory = history;
      _isLoadingHistory = false;
    });
  }

  Future<void> _loadEmergencyRatings() async {
    final ratings = await EmergencyRatingService.loadRatings();
    if (!mounted) {
      return;
    }
    setState(() => _emergencyRatings = ratings);
  }

  Future<void> _rateEmergency(EmergencyHistoryItem item, int rating) async {
    setState(() {
      _emergencyRatings = <int, int>{
        ..._emergencyRatings,
        item.id: rating,
      };
    });
    await EmergencyRatingService.saveRating(
      emergencyId: item.id,
      rating: rating,
    );
  }

  void _addVehicleToList({
    required String summary,
    required bool isPrimary,
  }) {
    setState(() {
      if (isPrimary) {
        for (var i = 0; i < _vehicles.length; i++) {
          _vehicles[i] = _vehicles[i].replaceAll(' · Principal', '');
        }
        _vehicles.insert(0, '$summary · Principal');
      } else {
        _vehicles.add(summary);
      }
    });
  }

  void _clearVehicleForm() {
    setState(() {
      _vehicleBrandController.clear();
      _vehicleModelController.clear();
      _vehicleYearController.text = '2018';
      _vehiclePlateController.text = '1023HHNNI';
      _selectedVehicleColorIndex = 1;
      _isPrimaryVehicle = true;
    });
  }

  String? _validateVehicleRequired(String? value, String fieldName) {
    if ((value ?? '').trim().isEmpty) {
      return 'Ingresa $fieldName.';
    }
    return null;
  }

  String? _validateVehicleYear(String? value) {
    final text = (value ?? '').trim();
    final year = int.tryParse(text);
    if (year == null) {
      return 'Ingresa un año válido.';
    }
    if (year < 1950 || year > 2100) {
      return 'Ingresa un año entre 1950 y 2100.';
    }
    return null;
  }

  Future<void> _saveVehicleFromTab() async {
    FocusScope.of(context).unfocus();
    final isValid = _vehicleFormKey.currentState?.validate() ?? false;
    if (!isValid || _isSavingVehicle) {
      return;
    }

    final colorLabels = ['blanco', 'gris', 'dorado', 'negro'];
    final clientId = widget.user.id;
    if (clientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('No se encontró el identificador del cliente autenticado.'),
        ),
      );
      return;
    }

    final vehicleData = VehicleRegistrationData(
      clientId: clientId,
      brand: _vehicleBrandController.text.trim(),
      model: _vehicleModelController.text.trim(),
      year: int.parse(_vehicleYearController.text.trim()),
      plate: _vehiclePlateController.text.trim().toUpperCase(),
      color: colorLabels[_selectedVehicleColorIndex],
      isPrimary: _isPrimaryVehicle,
    );

    setState(() => _isSavingVehicle = true);

    final response = await VehicleService.registerVehicle(vehicleData);

    if (!mounted) {
      return;
    }

    setState(() => _isSavingVehicle = false);

    if (!response.isSuccess) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Registro no enviado'),
          content: Text(
            response.statusCode == 0
                ? response.message
                : 'Backend: ${response.statusCode}\n${response.message}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
      return;
    }

    await _loadVehicles();
    if (!mounted) {
      return;
    }
    _clearVehicleForm();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          response.vehicleId == null
              ? response.message
              : '${response.message} ID ${response.vehicleId}.',
        ),
      ),
    );
  }

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
      await _updateSelectedPoint(currentPoint, moveCamera: true);
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

  Future<void> _searchLocation() async {
    final query = _locationSearchController.text.trim();
    if (query.isEmpty || _isSearchingLocation) {
      return;
    }

    setState(() => _isSearchingLocation = true);

    try {
      final results = await locationFromAddress(query);
      if (results.isEmpty || !mounted) {
        return;
      }

      final location = results.first;
      final searchedPoint = LatLng(location.latitude, location.longitude);
      await _updateSelectedPoint(searchedPoint, moveCamera: true);
    } catch (_) {
      _showLocationMessage(
        'No se encontró una ubicación para la dirección ingresada.',
      );
    } finally {
      if (mounted) {
        setState(() => _isSearchingLocation = false);
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

  void _continueEmergencyFlow() {
    if (widget.emergencyDraft != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EmergencyReviewScreen(
            args: EmergencyReviewArgs(
              draft: widget.emergencyDraft!,
              zone: _selectedZone,
              latitude: _selectedMapPoint.latitude,
              longitude: _selectedMapPoint.longitude,
            ),
          ),
        ),
      );
      return;
    }

    Navigator.of(context).pushNamed(
      AppRoutes.emergencyRequest,
      arguments: EmergencyRequestArgs(
        user: widget.user,
        clientId: widget.user.id,
      ),
    );
  }

  Future<void> _openVehicleRegistrationScreen() async {
    final result = await Navigator.of(context).push<VehicleRegistrationResult>(
      MaterialPageRoute(
        builder: (_) => VehicleRegistrationScreen(
          clientId: widget.user.id,
        ),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    _addVehicleToList(
      summary: result.summary,
      isPrimary: result.isPrimary,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vehículo agregado correctamente.'),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _locationSearchController.dispose();
    _vehicleBrandController.dispose();
    _vehicleModelController.dispose();
    _vehicleYearController.dispose();
    _vehiclePlateController.dispose();
    super.dispose();
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Confirma tu ubicación',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Usaremos tu ubicación para enviarte ayuda más rápida',
                style: TextStyle(
                  color: Colors.white,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
                        onCurrentLocationTap:
                            _isFetchingLocation ? null : _useCurrentLocation,
                        onChanged: (point) => _updateSelectedPoint(point),
                        onMapCreated: (controller) {
                          _mapController = controller;
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFDCE5F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.search_rounded,
                                    color: Color(0xFF98A2B3),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: _locationSearchController,
                                      textInputAction: TextInputAction.search,
                                      onSubmitted: (_) => _searchLocation(),
                                      decoration: const InputDecoration(
                                        hintText: 'Buscar dirección',
                                        hintStyle: TextStyle(
                                          color: Color(0xFF98A2B3),
                                          fontWeight: FontWeight.w600,
                                        ),
                                        border: InputBorder.none,
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _isSearchingLocation
                                        ? null
                                        : _searchLocation,
                                    icon: _isSearchingLocation
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.search_rounded,
                                            color: Color(0xFF98A2B3),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F7FB),
                                borderRadius: BorderRadius.circular(18),
                                border:
                                    Border.all(color: const Color(0xFFDCE5F0)),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                          '$_selectedAddress · $_selectedZone',
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
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(0xFFDCE5F0),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Ajusta el punto en el mapa',
                                    style: TextStyle(
                                      color: Color(0xFF101828),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Arrastra el marcador si es necesario',
                                    style: TextStyle(
                                      color: Color(0xFF66758C),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          'Dirección:',
                                          style: TextStyle(
                                            color: Color(0xFF66758C),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: _editDirectionText,
                                        icon: const Icon(
                                          Icons.edit_rounded,
                                          color: Color(0xFF123F78),
                                          size: 20,
                                        ),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _directionText,
                                    style: const TextStyle(
                                      color: Color(0xFF101828),
                                      height: 1.35,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _LocationDetailCard(
                                          label: 'Latitud',
                                          value: _selectedMapPoint.latitude
                                              .toStringAsFixed(5),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _LocationDetailCard(
                                          label: 'Longitud',
                                          value: _selectedMapPoint.longitude
                                              .toStringAsFixed(5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      if (widget.emergencyDraft != null) {
                                        Navigator.of(context).pushNamed(
                                          AppRoutes.emergencyRequest,
                                          arguments: EmergencyRequestArgs(
                                            user: widget.user,
                                            clientId: widget.user.id,
                                          ),
                                        );
                                        return;
                                      }
                                      Navigator.of(context).maybePop();
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF123F78),
                                      side: const BorderSide(
                                        color: Color(0xFFD0D5DD),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 15,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: const Text(
                                      'Atrás',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: _continueEmergencyFlow,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF123F78),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 15,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: const Text(
                                      'Continuar',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ),
                              ],
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
    );
  }

  Widget _buildAlertsContent() {
    return ValueListenableBuilder<List<AppAlert>>(
      valueListenable: AlertService.alerts,
      builder: (context, alerts, _) {
        final unreadCount = alerts.where((item) => item.isUnread).length;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Alertas',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF101828),
                          ),
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF123F78),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$unreadCount nuevas',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    unreadCount == 0
                        ? 'No tienes alertas nuevas.'
                        : 'Mantén pulsado o toca una fila para marcarla como leída.',
                    style: const TextStyle(
                      color: Color(0xFF66758C),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: unreadCount == 0
                          ? null
                          : () => AlertService.markAllAsRead(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF123F78),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFDCE5F0)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      icon: const Icon(Icons.done_all_rounded),
                      label: const Text(
                        'Marcar todo como leído',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (alerts.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x160B285A),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 56,
                            color: Color(0xFF123F78),
                          ),
                          SizedBox(height: 14),
                          Text(
                            'Todavía no hay notificaciones.',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF123F78),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Cuando registres una emergencia o cambie su estado, aparecerá aquí.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF55637C),
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE5EAF1)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x120B285A),
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(children: _buildAlertSections(alerts)),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Historial',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF101828),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _loadEmergencyHistory,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: Color(0xFF123F78),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Aquí verás todas las solicitudes de emergencia que realizaste.',
                style: TextStyle(
                  color: Color(0xFF66758C),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
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
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF123F78), Color(0xFF215FA7)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Solicitudes registradas',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Consulta el estado y el detalle de cada emergencia.',
                                  style: TextStyle(
                                    color: Color(0xE8FFFFFF),
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0x24FFFFFF),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${_emergencyHistory.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isLoadingHistory)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 28),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_emergencyHistory.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'Aún no tienes emergencias registradas.',
                            style: TextStyle(
                              color: Color(0xFF66758C),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    else
                      ..._emergencyHistory.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _EmergencyHistoryCard(
                            item: item,
                            rating: _emergencyRatings[item.id] ?? 0,
                            onRate: (rating) => _rateEmergency(item, rating),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAlertSections(List<AppAlert> alerts) {
    final groupedAlerts = <String, List<AppAlert>>{
      'Hoy': <AppAlert>[],
      'Ayer': <AppAlert>[],
      'Anteriores': <AppAlert>[],
    };

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final alert in alerts) {
      final createdDay = DateTime(
        alert.createdAt.year,
        alert.createdAt.month,
        alert.createdAt.day,
      );

      if (createdDay == today) {
        groupedAlerts['Hoy']!.add(alert);
      } else if (createdDay == yesterday) {
        groupedAlerts['Ayer']!.add(alert);
      } else {
        groupedAlerts['Anteriores']!.add(alert);
      }
    }

    final sections = <Widget>[];
    for (final entry in groupedAlerts.entries) {
      if (entry.value.isEmpty) {
        continue;
      }

      sections.add(_AlertSectionHeader(title: entry.key));
      sections.addAll(
        entry.value.asMap().entries.map(
              (item) => _AlertRow(
                alert: item.value,
                isLast: item.key == entry.value.length - 1,
                onTap: () => _handleAlertTap(item.value),
              ),
            ),
      );
    }

    return sections;
  }

  void _handleAlertTap(AppAlert alert) {
    AlertService.markAsRead(alert.id);

    if (alert.actionType != 'open_technician_map') {
      return;
    }

    final payload = alert.actionPayload ?? const <String, dynamic>{};
    Navigator.of(context).pushNamed(
      AppRoutes.technicianTrackingMap,
      arguments: TechnicianTrackingMapArgs(
        emergencyId: payload['emergency_id']?.toString() ?? '',
        workshopId: payload['workshop_id']?.toString() ?? '',
        workshopName:
            payload['workshop_name']?.toString().trim().isNotEmpty == true
                ? payload['workshop_name'].toString().trim()
                : 'Taller asignado',
        technicianId: payload['technician_id']?.toString(),
        technicianName: payload['technician_name']?.toString(),
        incidentDescription: payload['incident_description']?.toString(),
        latitude: _tryParseAlertCoordinate(payload['latitude']),
        longitude: _tryParseAlertCoordinate(payload['longitude']),
      ),
    );
  }

  Widget _buildVehicleContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
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
                child: Form(
                  key: _vehicleFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F7FB),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.directions_car_filled_rounded,
                              color: Color(0xFF123F78),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Registrar Vehículo',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF101828),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Completa los datos del vehículo y guárdalo sin salir de esta pestaña.',
                        style: TextStyle(
                          color: Color(0xFF66758C),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _VehicleEditableLine(
                        label: 'Marca',
                        controller: _vehicleBrandController,
                        hintText: 'Ej: Toyota',
                        validator: (value) =>
                            _validateVehicleRequired(value, 'la marca'),
                      ),
                      _VehicleEditableLine(
                        label: 'Modelo',
                        controller: _vehicleModelController,
                        hintText: 'Ej: Corolla',
                        validator: (value) =>
                            _validateVehicleRequired(value, 'el modelo'),
                      ),
                      _VehicleEditableLine(
                        label: 'Año',
                        controller: _vehicleYearController,
                        hintText: 'Ej: 2018',
                        keyboardType: TextInputType.number,
                        validator: _validateVehicleYear,
                      ),
                      _VehicleEditableLine(
                        label: 'Matrícula',
                        controller: _vehiclePlateController,
                        hintText: 'Ej: 1023HHNNI',
                        textCapitalization: TextCapitalization.characters,
                        validator: (value) =>
                            _validateVehicleRequired(value, 'la matrícula'),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Color',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF101828),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: List.generate(_vehicleColors.length, (index) {
                          return Padding(
                            padding: EdgeInsets.only(
                              right:
                                  index == _vehicleColors.length - 1 ? 0 : 10,
                            ),
                            child: GestureDetector(
                              onTap: () {
                                setState(
                                  () => _selectedVehicleColorIndex = index,
                                );
                              },
                              child: _VehicleColorSwatch(
                                color: _vehicleColors[index],
                                selected: index == _selectedVehicleColorIndex,
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isPrimaryVehicle = !_isPrimaryVehicle;
                          });
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFD),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFDCE5F0)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isPrimaryVehicle
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                color: const Color(0xFF123F78),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Seleccionar como vehículo principal',
                                  style: TextStyle(
                                    color: Color(0xFF55637C),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _clearVehicleForm,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF66758C),
                                side: const BorderSide(
                                  color: Color(0xFFD0D5DD),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Cancelar',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: FilledButton(
                              onPressed:
                                  _isSavingVehicle ? null : _saveVehicleFromTab,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF2E6BB2),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _isSavingVehicle
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Guardar',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w800),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x160B285A),
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mis vehículos',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF123F78),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_isLoadingVehicles)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF123F78),
                          ),
                        ),
                      )
                    else if (_vehicles.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEE),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFEACB63)),
                        ),
                        child: const Text(
                          'Aún no tienes vehículos registrados.',
                          style: TextStyle(
                            color: Color(0xFF66758C),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
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
                              color: const Color(0xFFFFFBEE),
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: const Color(0xFFEACB63)),
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
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => VehicleManagementScreen(
                                user: widget.user,
                                clientId: widget.user.id,
                                initialVehicles: _vehicles,
                              ),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF123F78),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        icon: const Icon(Icons.settings_rounded),
                        label: const Text(
                          'Administrar vehículos',
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
                        content:
                            Text('Sección de cuenta disponible próximamente.'),
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
                          user: widget.user,
                          clientId: widget.user.id,
                          initialVehicles: _vehicles,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                if (_isLoadingVehicles)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF123F78),
                      ),
                    ),
                  )
                else if (_vehicles.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFD),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFDCE5F0)),
                    ),
                    child: const Text(
                      'Aún no tienes vehículos registrados.',
                      style: TextStyle(
                        color: Color(0xFF66758C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
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
      0 => _buildHistoryContent(),
      1 => _buildVehicleContent(),
      2 => _buildAlertsContent(),
      _ => _buildProfileContent(),
    };

    return DoubleBackLogoutScope(
      child: Scaffold(
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
            NavigationDestination(
              icon: Icon(Icons.history_rounded),
              label: 'Historial',
            ),
            NavigationDestination(
              icon: Icon(Icons.directions_car_filled_rounded),
              label: 'Vehículo',
            ),
            NavigationDestination(
              icon: Icon(Icons.notifications_rounded),
              label: 'Alertas',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_rounded),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}

double? _tryParseAlertCoordinate(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({
    required this.alert,
    required this.onTap,
    required this.isLast,
  });

  final AppAlert alert;
  final VoidCallback onTap;
  final bool isLast;

  Color get _accentColor {
    return switch (alert.category) {
      AlertCategory.success => const Color(0xFF31A24C),
      AlertCategory.warning => const Color(0xFFD97706),
      AlertCategory.info => const Color(0xFF123F78),
    };
  }

  IconData get _icon {
    return switch (alert.category) {
      AlertCategory.success => Icons.check_circle_rounded,
      AlertCategory.warning => Icons.warning_amber_rounded,
      AlertCategory.info => Icons.notifications_active_rounded,
    };
  }

  String get _timeLabel {
    final now = DateTime.now();
    final difference = now.difference(alert.createdAt);

    if (difference.inMinutes < 1) {
      return 'Ahora mismo';
    }
    if (difference.inHours < 1) {
      return 'Hace ${difference.inMinutes} min';
    }
    if (difference.inDays < 1) {
      return 'Hace ${difference.inHours} h';
    }
    return 'Hace ${difference.inDays} d';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: alert.isUnread
                ? const Color(0xFFF7FAFF)
                : const Color(0xFFFFFFFF),
            border: isLast
                ? null
                : const Border(
                    bottom: BorderSide(color: Color(0xFFE9EEF5)),
                  ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 12),
              if (alert.isUnread)
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: _accentColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                )
              else
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 8),
                ),
              const SizedBox(width: 12),
              Icon(
                _icon,
                color: alert.isUnread ? _accentColor : const Color(0xFF98A2B3),
                size: 22,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            alert.title,
                            style: TextStyle(
                              color: const Color(0xFF101828),
                              fontWeight: alert.isUnread
                                  ? FontWeight.w900
                                  : FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _timeLabel,
                          style: TextStyle(
                            color: alert.isUnread
                                ? const Color(0xFF344054)
                                : const Color(0xFF98A2B3),
                            fontWeight: alert.isUnread
                                ? FontWeight.w800
                                : FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.message,
                      style: TextStyle(
                        color: alert.isUnread
                            ? const Color(0xFF475467)
                            : const Color(0xFF66758C),
                        height: 1.35,
                        fontWeight:
                            alert.isUnread ? FontWeight.w600 : FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertSectionHeader extends StatelessWidget {
  const _AlertSectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE9EEF5)),
        ),
      ),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF66758C),
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _EmergencyHistoryCard extends StatelessWidget {
  const _EmergencyHistoryCard({
    required this.item,
    required this.rating,
    required this.onRate,
  });

  final EmergencyHistoryItem item;
  final int rating;
  final ValueChanged<int> onRate;

  Color get _statusColor {
    switch (item.emergencyStatus.toLowerCase()) {
      case 'activo':
      case 'asignado':
        return const Color(0xFF126B39);
      case 'finalizado':
      case 'completado':
        return const Color(0xFF123F78);
      default:
        return const Color(0xFFD97706);
    }
  }

  Color get _statusBackgroundColor {
    switch (item.emergencyStatus.toLowerCase()) {
      case 'activo':
      case 'asignado':
        return const Color(0xFFEAF7EE);
      case 'finalizado':
      case 'completado':
        return const Color(0xFFEAF2FD);
      default:
        return const Color(0xFFFFF4DF);
    }
  }

  String get _dateLabel {
    final date = item.createdAt.toLocal();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year · $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE5F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.problemType,
                  style: const TextStyle(
                    color: Color(0xFF101828),
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _statusBackgroundColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.emergencyStatus,
                  style: TextStyle(
                    color: _statusColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${item.vehicleName} · ${item.vehiclePlate}',
            style: const TextStyle(
              color: Color(0xFF123F78),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.description?.trim().isNotEmpty == true
                ? item.description!
                : 'Sin descripción adicional.',
            style: const TextStyle(
              color: Color(0xFF66758C),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HistoryMetaChip(
                icon: Icons.calendar_today_rounded,
                label: _dateLabel,
              ),
              if ((item.zone ?? '').trim().isNotEmpty)
                _HistoryMetaChip(
                  icon: Icons.place_rounded,
                  label: item.zone!,
                ),
              _HistoryMetaChip(
                icon: Icons.payments_rounded,
                label: item.price == null ? 'A cotizar' : 'Bs ${item.price}',
              ),
              if ((item.assignedTechnicianName ?? '').trim().isNotEmpty)
                _HistoryMetaChip(
                  icon: Icons.engineering_rounded,
                  label: item.assignedTechnicianName!,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDCE5F0)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Califica tu atención',
                    style: TextStyle(
                      color: Color(0xFF123F78),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _EmergencyRatingStars(
                  rating: rating,
                  onRate: onRate,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyRatingStars extends StatelessWidget {
  const _EmergencyRatingStars({
    required this.rating,
    required this.onRate,
  });

  final int rating;
  final ValueChanged<int> onRate;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final isActive = starValue <= rating;
        return IconButton(
          onPressed: () => onRate(starValue),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 30,
            minHeight: 30,
          ),
          icon: Icon(
            isActive ? Icons.star_rounded : Icons.star_border_rounded,
            color: isActive ? const Color(0xFFD8AD20) : const Color(0xFF98A2B3),
            size: 24,
          ),
        );
      }),
    );
  }
}

class _HistoryMetaChip extends StatelessWidget {
  const _HistoryMetaChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDCE5F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF123F78)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF55637C),
              fontWeight: FontWeight.w700,
            ),
          ),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleEditableLine extends StatelessWidget {
  const _VehicleEditableLine({
    required this.label,
    required this.controller,
    required this.validator,
    this.hintText,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController controller;
  final String? Function(String?) validator;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE7ECF3)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF101828),
              ),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              validator: validator,
              keyboardType: keyboardType,
              textCapitalization: textCapitalization,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF344054),
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: hintText,
                hintStyle: const TextStyle(
                  color: Color(0xFF98A2B3),
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                errorStyle: const TextStyle(height: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleColorSwatch extends StatelessWidget {
  const _VehicleColorSwatch({
    required this.color,
    this.selected = false,
  });

  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected ? const Color(0xFF2E6BB2) : const Color(0xFFD0D5DD),
          width: selected ? 2 : 1,
        ),
      ),
      child: selected
          ? const Icon(
              Icons.check_rounded,
              size: 18,
              color: Color(0xFF2E6BB2),
            )
          : null,
    );
  }
}

class _LocationDetailCard extends StatelessWidget {
  const _LocationDetailCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE5F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF66758C),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
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
