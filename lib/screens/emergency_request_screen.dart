import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../models/auth_models.dart';
import '../models/emergency_models.dart';
import '../models/workshop_models.dart';
import '../services/vehicle_service.dart';
import '../services/workshop_service.dart';
import '../utils/double_back_logout_scope.dart';
import 'client_home_screen.dart';
import 'emergency_sending_screen.dart';
import 'vehicle_registration_screen.dart';

class EmergencyRequestArgs {
  const EmergencyRequestArgs({
    required this.user,
    required this.clientId,
  });

  final FakeAuthUser user;
  final int? clientId;
}

class EmergencyRequestScreen extends StatefulWidget {
  const EmergencyRequestScreen({super.key, required this.args});

  final EmergencyRequestArgs args;

  @override
  State<EmergencyRequestScreen> createState() => _EmergencyRequestScreenState();
}

class _EmergencyRequestScreenState extends State<EmergencyRequestScreen> {
  static const LatLng _defaultSantaCruzLocation = LatLng(-17.7833, -63.1821);
  static const int _maxPhotoCount = 6;
  static const int _maxPhotoBytes = 20 * 1024 * 1024;
  static const int _maxAudioBytes = 40 * 1024 * 1024;

  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationSearchController =
      TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  final List<_ProblemOption> _problemTypes = const [
    _ProblemOption(
      label: 'Batería',
      icon: Icons.battery_6_bar_rounded,
      price: 50,
    ),
    _ProblemOption(
      label: 'Neumático',
      icon: Icons.tire_repair_rounded,
      price: 50,
    ),
    _ProblemOption(
      label: 'Combustible',
      icon: Icons.local_gas_station_rounded,
      price: 60,
    ),
    _ProblemOption(
      label: 'Motor',
      icon: Icons.settings_rounded,
      price: 100,
    ),
    _ProblemOption(
      label: 'Sistema eléctrico',
      icon: Icons.bolt_rounded,
      price: 90,
    ),
    _ProblemOption(
      label: 'Accidente',
      icon: Icons.car_crash_rounded,
      price: 150,
    ),
    _ProblemOption(
      label: 'Cerrajería / llaves',
      icon: Icons.key_rounded,
      price: 80,
    ),
    _ProblemOption(
      label: 'Otro',
      icon: Icons.more_horiz_rounded,
    ),
  ];

  List<_VehicleOption> _vehicles = const [];
  int _selectedVehicleIndex = 0;
  String _selectedProblem = 'Batería';
  final List<XFile> _selectedEvidence = [];
  bool _isPickingImage = false;
  bool _isRecordingAudio = false;
  bool _isLoadingVehicles = true;
  bool _isFetchingLocation = false;
  bool _isSearchingLocation = false;
  bool _isLoadingNearbyWorkshops = false;
  bool _isFindingNearestWorkshop = false;
  bool _isPlayingAudio = false;
  bool _isOpeningVehicleRegistration = false;
  bool _didAutoOpenVehicleRegistration = false;
  String? _recordedAudioPath;
  DateTime? _recordingStartedAt;
  Duration? _recordedAudioDuration;
  Timer? _recordingTimer;
  LatLng _selectedMapPoint = _defaultSantaCruzLocation;
  GoogleMapController? _mapController;
  String _selectedAddress = 'Santa Cruz de la Sierra, Bolivia';
  String? _manualDirectionText;
  List<WorkshopMapPoint> _nearbyWorkshops = const [];
  WorkshopMapPoint? _nearestWorkshop;
  double? _nearestWorkshopDistanceMeters;

  String get _selectedZone => _resolveSantaCruzZone(_selectedMapPoint);
  String get _directionText =>
      _manualDirectionText ?? '$_selectedAddress\n$_selectedZone';
  int? get _selectedProblemPrice {
    for (final problem in _problemTypes) {
      if (problem.label == _selectedProblem) {
        return problem.price;
      }
    }
    return null;
  }

  String _normalizeText(String value) {
    return value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll(RegExp(r'[^a-z0-9\s/]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  List<String> _specialtyKeywordsForProblem(String problem) {
    final normalizedProblem = _normalizeText(problem);
    return switch (normalizedProblem) {
      'bateria' => ['bateria', 'electrico', 'sistema electrico'],
      'neumatico' => ['neumatico', 'llanta', 'gomeria'],
      'combustible' => ['combustible'],
      'motor' => ['motor', 'mecanica', 'mecanica general'],
      'sistema electrico' => ['electrico', 'sistema electrico', 'bateria'],
      'accidente' => ['accidente', 'colision', 'chaperia', 'grua'],
      'cerrajeria / llaves' => [
          'cerrajeria',
          'llaves',
          'cerrajeria automotriz'
        ],
      'otro' => const <String>[],
      _ => const <String>[],
    };
  }

  bool _supportsSelectedProblem(WorkshopMapPoint workshop) {
    final specialty = workshop.specialty?.trim();
    if (_selectedProblem == 'Otro') {
      return true;
    }
    if (specialty == null || specialty.isEmpty) {
      return false;
    }

    final normalizedSpecialty = _normalizeText(specialty);
    final keywords = _specialtyKeywordsForProblem(_selectedProblem);
    if (keywords.isEmpty) {
      return true;
    }

    for (final keyword in keywords) {
      if (normalizedSpecialty.contains(_normalizeText(keyword))) {
        return true;
      }
    }

    return false;
  }

  void _openClientTab(int index) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ClientHomeScreen(
          user: widget.args.user,
          initialTabIndex: index,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadVehicles();
    _syncSelectedAddress();
    _loadNearbyWorkshops();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) {
        return;
      }
      setState(() => _isPlayingAudio = false);
    });
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) {
        return;
      }
      setState(() => _isPlayingAudio = state == PlayerState.playing);
    });
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _descriptionController.dispose();
    _locationSearchController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _mapController?.dispose();
    super.dispose();
  }

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
      // Si falla la geocodificacion inversa, mantenemos la direccion actual.
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
    await _loadNearbyWorkshops();
  }

  Future<void> _loadNearbyWorkshops() async {
    if (_isLoadingNearbyWorkshops) {
      return;
    }

    setState(() => _isLoadingNearbyWorkshops = true);

    final workshops = await WorkshopService.fetchWorkshops();

    if (!mounted) {
      return;
    }

    setState(() {
      _nearbyWorkshops = workshops;
      final nearestId = _nearestWorkshop?.id;
      WorkshopMapPoint? updatedNearestWorkshop;
      if (nearestId != null) {
        for (final item in workshops) {
          if (item.id == nearestId) {
            updatedNearestWorkshop = item;
            break;
          }
        }
      }
      _nearestWorkshop = updatedNearestWorkshop;
      if (_nearestWorkshop == null) {
        _nearestWorkshopDistanceMeters = null;
      }
      _isLoadingNearbyWorkshops = false;
    });
  }

  Future<Position?> _getCurrentPositionForMap() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      _showLocationMessage(
        'Activa la ubicacion del dispositivo para marcar tu posicion actual.',
      );
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      _showLocationMessage(
        'Debes aceptar el permiso de ubicacion para usar tu posicion actual.',
      );
      return null;
    }

    if (permission == LocationPermission.deniedForever) {
      _showLocationMessage(
        'El permiso de ubicacion fue bloqueado. Habilitalo desde ajustes.',
      );
      return null;
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
    );
    return Geolocator.getCurrentPosition(locationSettings: locationSettings);
  }

  Future<void> _useCurrentLocation() async {
    if (_isFetchingLocation) {
      return;
    }

    setState(() => _isFetchingLocation = true);

    try {
      final position = await _getCurrentPositionForMap();
      if (position == null) {
        return;
      }
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

  Future<void> _goToNearestWorkshop() async {
    if (_isFindingNearestWorkshop) {
      return;
    }

    if (_nearbyWorkshops.isEmpty) {
      _showLocationMessage('No hay talleres cargados en el mapa.');
      return;
    }

    setState(() => _isFindingNearestWorkshop = true);

    try {
      final position = await _getCurrentPositionForMap();
      if (position == null) {
        return;
      }

      final candidateWorkshops = _nearbyWorkshops
          .where(_supportsSelectedProblem)
          .toList(growable: false);
      if (candidateWorkshops.isEmpty) {
        _showLocationMessage(
          'No se encontraron talleres con especialidad para $_selectedProblem.',
        );
        return;
      }

      WorkshopMapPoint? nearestWorkshop;
      double? nearestDistanceMeters;

      for (final workshop in candidateWorkshops) {
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          workshop.latitude,
          workshop.longitude,
        );

        if (nearestDistanceMeters == null || distance < nearestDistanceMeters) {
          nearestDistanceMeters = distance;
          nearestWorkshop = workshop;
        }
      }

      if (!mounted ||
          nearestWorkshop == null ||
          nearestDistanceMeters == null) {
        return;
      }

      setState(() {
        _nearestWorkshop = nearestWorkshop;
        _nearestWorkshopDistanceMeters = nearestDistanceMeters;
      });

      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              nearestWorkshop.latitude,
              nearestWorkshop.longitude,
            ),
            zoom: 15.5,
          ),
        ),
      );

      _showLocationMessage(
        'Taller mas cercano para $_selectedProblem: ${nearestWorkshop.name} '
        '(${nearestDistanceMeters.toStringAsFixed(0)} m)',
      );
    } catch (_) {
      _showLocationMessage('No se pudo calcular el taller mas cercano.');
    } finally {
      if (mounted) {
        setState(() => _isFindingNearestWorkshop = false);
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
        'No se encontro una ubicacion para la direccion ingresada.',
      );
    } finally {
      if (mounted) {
        setState(() => _isSearchingLocation = false);
      }
    }
  }

  Future<void> _editDirectionText() async {
    final controller = TextEditingController(text: _directionText);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar direccion'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Escribe la direccion completa',
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

  void _showLocationMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _loadVehicles() async {
    final clientId = widget.args.clientId;
    if (clientId == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingVehicles = false;
        _vehicles = const [];
      });
      return;
    }

    try {
      final records = await VehicleService.fetchVehicles(clientId: clientId);
      if (!mounted) {
        return;
      }

      setState(() {
        _vehicles = records
            .map(
              (record) => _VehicleOption(
                name: '${record.brand} ${record.model} ${record.year}'.trim(),
                plate: record.plate,
                icon: Icons.directions_car_filled_rounded,
              ),
            )
            .toList();
        _selectedVehicleIndex = 0;
        _isLoadingVehicles = false;
      });

      if (records.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _openVehicleRegistrationScreen(autoOpened: true);
        });
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _vehicles = const [];
        _selectedVehicleIndex = 0;
        _isLoadingVehicles = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudieron cargar tus vehículos registrados.'),
        ),
      );
    }
  }

  Future<void> _openVehicleRegistrationScreen({
    bool autoOpened = false,
  }) async {
    if (_isOpeningVehicleRegistration) {
      return;
    }
    if (autoOpened && _didAutoOpenVehicleRegistration) {
      return;
    }

    final clientId = widget.args.clientId;
    if (clientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'No se encontró el cliente autenticado para registrar el vehículo.'),
        ),
      );
      return;
    }

    if (autoOpened) {
      _didAutoOpenVehicleRegistration = true;
    }

    _isOpeningVehicleRegistration = true;
    final result = await Navigator.of(context).push<VehicleRegistrationResult>(
      MaterialPageRoute(
        builder: (_) => VehicleRegistrationScreen(clientId: clientId),
      ),
    );
    _isOpeningVehicleRegistration = false;

    if (!mounted) {
      return;
    }

    if (result == null) {
      setState(() {});
      return;
    }

    await _loadVehicles();
    if (!mounted) {
      return;
    }

    if (_vehicles.isEmpty) {
      final summaryParts = result.summary.split('·');
      final name = summaryParts.first.trim();
      final plate = summaryParts.length > 1 ? summaryParts[1].trim() : '';
      setState(() {
        _vehicles = [
          _VehicleOption(
            name: name,
            plate: plate,
            icon: Icons.directions_car_filled_rounded,
          ),
        ];
        _selectedVehicleIndex = 0;
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vehículo agregado correctamente.'),
      ),
    );
  }

  Future<void> _toggleAudioRecording() async {
    if (_isRecordingAudio) {
      _recordingTimer?.cancel();
      String? path;
      try {
        path = await _audioRecorder.stop();
      } catch (_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isRecordingAudio = false;
          _recordingStartedAt = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo detener la grabacion de audio.'),
          ),
        );
        return;
      }
      if (!mounted) {
        return;
      }

      // Validamos el archivo final ya grabado antes de conservarlo en el draft.
      final fileSize = path == null ? 0 : await File(path).length();
      if (fileSize > _maxAudioBytes) {
        try {
          if (path != null) {
            final file = File(path);
            if (await file.exists()) {
              await file.delete();
            }
          }
        } catch (_) {
          // Ignorado: ya mostraremos el error al usuario.
        }
        setState(() {
          _isRecordingAudio = false;
          _recordedAudioPath = null;
          _recordedAudioDuration = null;
          _recordingStartedAt = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El audio supera el máximo de 40 MB.'),
          ),
        );
        return;
      }

      setState(() {
        _isRecordingAudio = false;
        _recordedAudioPath = path;
        _recordedAudioDuration = _recordingStartedAt == null
            ? null
            : DateTime.now().difference(_recordingStartedAt!);
        _recordingStartedAt = null;
        if (_recordedAudioDuration != null &&
            _recordedAudioDuration! > const Duration(seconds: 60)) {
          _recordedAudioDuration = const Duration(seconds: 60);
        }
      });
      return;
    }

    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Debes aceptar el permiso del micrófono para grabar audio.'),
        ),
      );
      return;
    }

    final directory = await getTemporaryDirectory();
    final filePath =
        '${directory.path}/emergency-audio-${DateTime.now().millisecondsSinceEpoch}.m4a';

    try {
      await _audioPlayer.stop();

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'No se pudo iniciar la grabacion de audio. Revisa el permiso del microfono.'),
        ),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isRecordingAudio = true;
      _isPlayingAudio = false;
      _recordedAudioPath = null;
      _recordedAudioDuration = null;
      _recordingStartedAt = DateTime.now();
    });

    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted || !_isRecordingAudio || _recordingStartedAt == null) {
        timer.cancel();
        return;
      }

      // Cortamos la grabación en cliente para alinear la UI con el límite actual.
      final elapsed = DateTime.now().difference(_recordingStartedAt!);
      if (elapsed >= const Duration(seconds: 60)) {
        timer.cancel();
        await _toggleAudioRecording();
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La grabacion se detuvo al llegar a 60 segundos.'),
          ),
        );
        return;
      }

      setState(() {
        _recordedAudioDuration = elapsed;
      });
    });
  }

  Future<void> _pickEvidence(ImageSource source) async {
    if (_isPickingImage) {
      return;
    }

    if (_selectedEvidence.length >= _maxPhotoCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solo puedes adjuntar hasta 6 imágenes.'),
        ),
      );
      return;
    }

    setState(() => _isPickingImage = true);

    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (image == null || !mounted) {
        return;
      }

      final imageSize = await File(image.path).length();
      if (imageSize > _maxPhotoBytes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cada foto debe pesar como máximo 20 MB.'),
          ),
        );
        return;
      }

      setState(() => _selectedEvidence.add(image));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('No se pudo abrir la cámara o la galería en este momento.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  void _removeEvidenceAt(int index) {
    setState(() {
      _selectedEvidence.removeAt(index);
    });
  }

  Future<void> _previewRecordedAudio() async {
    if (_recordedAudioPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero debes grabar un audio.'),
        ),
      );
      return;
    }

    try {
      if (_isPlayingAudio) {
        await _audioPlayer.pause();
        return;
      }

      await _audioPlayer.stop();
      await _audioPlayer.play(
        DeviceFileSource(_recordedAudioPath!),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo reproducir el audio grabado.'),
        ),
      );
    }
  }

  Future<void> _deleteRecordedAudio() async {
    if (_recordedAudioPath == null) {
      return;
    }

    final path = _recordedAudioPath!;
    await _audioPlayer.stop();

    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Si falla el borrado fisico, igual limpiamos el estado local.
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isPlayingAudio = false;
      _recordedAudioPath = null;
      _recordedAudioDuration = null;
    });
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) {
      return '00:00';
    }
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  double? _durationInSeconds(Duration? duration) {
    if (duration == null) {
      return null;
    }
    return duration.inMilliseconds / 1000;
  }

  int _safeFileSize(String path) {
    try {
      final file = File(path);
      if (!file.existsSync()) {
        return 0;
      }
      return file.lengthSync();
    } catch (_) {
      return 0;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) {
      return '0 KB';
    }
    final mb = bytes / (1024 * 1024);
    if (mb >= 1) {
      return '${mb.toStringAsFixed(1)} MB';
    }
    final kb = bytes / 1024;
    return '${kb.toStringAsFixed(0)} KB';
  }

  @override
  Widget build(BuildContext context) {
    final hasVehicles = _vehicles.isNotEmpty;
    final safeSelectedIndex =
        hasVehicles ? _selectedVehicleIndex.clamp(0, _vehicles.length - 1) : 0;
    final vehicle = hasVehicles ? _vehicles[safeSelectedIndex] : null;
    final totalPhotoBytes = _selectedEvidence.fold<int>(
      0,
      (sum, file) => sum + _safeFileSize(file.path),
    );
    final audioBytes =
        _recordedAudioPath == null ? 0 : _safeFileSize(_recordedAudioPath!);

    return DoubleBackLogoutScope(
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FB),
        appBar: AppBar(
          title: const Text('Reportar Emergencia'),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF123F78),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x220B285A),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reportar emergencia',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Completa los datos del incidente y confirma la ubicacion para enviar una sola solicitud.',
                        style: TextStyle(
                          color: Color(0xE8FFFFFF),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _SectionCard(
                  title: '1. Seleccionar vehículo',
                  subtitle:
                      'Elige uno de tus vehículos registrados para esta emergencia.',
                  child: _isLoadingVehicles
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF123F78),
                            ),
                          ),
                        )
                      : !hasVehicles
                          ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFD),
                                borderRadius: BorderRadius.circular(18),
                                border:
                                    Border.all(color: const Color(0xFFD8E0EA)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Aún no tienes vehículos registrados. Registra uno primero para continuar con la emergencia.',
                                    style: TextStyle(
                                      color: Color(0xFF55637C),
                                      height: 1.35,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      onPressed: _isOpeningVehicleRegistration
                                          ? null
                                          : _openVehicleRegistrationScreen,
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF123F78),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.add_circle_outline_rounded,
                                      ),
                                      label: const Text(
                                        'Registrar vehículo',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              children:
                                  List.generate(_vehicles.length, (index) {
                                final item = _vehicles[index];
                                final selected = index == safeSelectedIndex;
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom:
                                        index == _vehicles.length - 1 ? 0 : 12,
                                  ),
                                  child: InkWell(
                                    onTap: () => setState(
                                        () => _selectedVehicleIndex = index),
                                    borderRadius: BorderRadius.circular(18),
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? const Color(0xFFFFF7DB)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: selected
                                              ? const Color(0xFFD8AD20)
                                              : const Color(0xFFD8E0EA),
                                          width: selected ? 1.4 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 46,
                                            height: 46,
                                            decoration: BoxDecoration(
                                              color: const Color(0x14D8AD20),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            child: Icon(
                                              item.icon,
                                              color: const Color(0xFF123F78),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    color: Color(0xFF123F78),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  item.plate,
                                                  style: const TextStyle(
                                                    color: Color(0xFF66758C),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            selected
                                                ? Icons.check_circle_rounded
                                                : Icons
                                                    .radio_button_unchecked_rounded,
                                            color: selected
                                                ? const Color(0xFF123F78)
                                                : const Color(0xFF97A5BA),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: '2. Tipo de problema',
                  subtitle:
                      'Indica el incidente principal para asignar mejor la ayuda.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final itemWidth = (constraints.maxWidth - 12) / 2;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: _problemTypes.map((problem) {
                              final selected =
                                  problem.label == _selectedProblem;
                              return SizedBox(
                                width: itemWidth,
                                child: _ProblemTypeTile(
                                  label: problem.label,
                                  icon: problem.icon,
                                  price: problem.price,
                                  selected: selected,
                                  onTap: () {
                                    setState(() {
                                      _selectedProblem = problem.label;
                                      if (_nearestWorkshop != null &&
                                          !_supportsSelectedProblem(
                                            _nearestWorkshop!,
                                          )) {
                                        _nearestWorkshop = null;
                                        _nearestWorkshopDistanceMeters = null;
                                      }
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      if (_selectedProblem == 'Otro') ...[
                        const SizedBox(height: 18),
                        const Text(
                          'Descripción breve',
                          style: TextStyle(
                            color: Color(0xFF3F4754),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _descriptionController,
                          maxLines: 3,
                          maxLength: 300,
                          decoration: InputDecoration(
                            hintText: 'Cuéntanos qué sucede (opcional)',
                            counterStyle: const TextStyle(
                              color: Color(0xFF98A2B3),
                              fontWeight: FontWeight.w600,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFD),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide:
                                  const BorderSide(color: Color(0xFFD8E0EA)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide:
                                  const BorderSide(color: Color(0xFFD8E0EA)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFF123F78),
                                width: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: '3. Anadir evidencia',
                  subtitle:
                      'Agrega fotos del vehículo y evidencia adicional para acelerar la ayuda.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fotos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF123F78),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Agrega fotos del vehículo y la situación (máx. 6 imágenes)',
                        style: TextStyle(
                          color: Color(0xFF66758C),
                          height: 1.35,
                        ),
                      ),
                      if (_selectedEvidence.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 98,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedEvidence.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              final evidence = _selectedEvidence[index];
                              return _EvidenceImageCard(
                                imagePath: evidence.path,
                                onRemove: () => _removeEvidenceAt(index),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFD),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFD8E0EA)),
                          ),
                          child: Text(
                            'Total fotos: ${_selectedEvidence.length} · ${_formatBytes(totalPhotoBytes)}',
                            style: const TextStyle(
                              color: Color(0xFF66758C),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _EvidenceActionTile(
                              icon: Icons.photo_camera_rounded,
                              label: 'Tomar foto',
                              accentColor: const Color(0xFF123F78),
                              onTap: () => _pickEvidence(ImageSource.camera),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _EvidenceActionTile(
                              icon: Icons.file_upload_outlined,
                              label: 'Subir de galería',
                              accentColor: const Color(0xFFD8AD20),
                              onTap: () => _pickEvidence(ImageSource.gallery),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Audio (opcional)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF123F78),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Graba un audio explicando mejor la situación (máx. 60 seg)',
                        style: TextStyle(
                          color: Color(0xFF66758C),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${_formatDuration(_recordedAudioDuration)} / 01:00',
                        style: const TextStyle(
                          color: Color(0xFF66758C),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _AudioPreviewCard(
                        hasAudio: _recordedAudioPath != null,
                        isRecording: _isRecordingAudio,
                        isPlaying: _isPlayingAudio,
                        onDelete: _recordedAudioPath == null
                            ? null
                            : _deleteRecordedAudio,
                      ),
                      if (_recordedAudioPath != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFD),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFD8E0EA)),
                          ),
                          child: const Text(
                            'Audio de evidencia grabado correctamente.',
                            style: TextStyle(
                              color: Color(0xFF123F78),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFD),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFD8E0EA)),
                          ),
                          child: Text(
                            'Tamano de audio: ${_formatBytes(audioBytes)}',
                            style: const TextStyle(
                              color: Color(0xFF66758C),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _AudioActionTile(
                              icon: _isRecordingAudio
                                  ? Icons.stop_circle_rounded
                                  : Icons.mic_rounded,
                              label: _isRecordingAudio ? 'Detener' : 'Grabar',
                              accentColor: const Color(0xFF123F78),
                              onTap: _toggleAudioRecording,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _AudioActionTile(
                              icon: _isPlayingAudio
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              label: _isPlayingAudio ? 'Pausar' : 'Reproducir',
                              accentColor: const Color(0xFF66758C),
                              onTap: () {
                                _previewRecordedAudio();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F7FF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Color(0xFF7C8FB5),
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Puedes agregar fotos y audio para que podamos ayudarte más rápido.',
                                style: TextStyle(
                                  color: Color(0xFF7C8FB5),
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                ),
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
                          color: const Color(0xFFFFF7DB),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFEACB63)),
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
                                Icons.location_on_rounded,
                                color: Color(0xFFD8AD20),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                vehicle == null
                                    ? 'Debes registrar un vehículo antes de continuar con el reporte.'
                                    : 'Vas a continuar con ${vehicle.name} y el problema: $_selectedProblem.',
                                style: const TextStyle(
                                  color: Color(0xFF55637C),
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8DE),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFEACB63)),
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
                                Icons.payments_rounded,
                                color: Color(0xFFD8AD20),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Precio total estimado',
                                    style: TextStyle(
                                      color: Color(0xFF123F78),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _selectedProblemPrice == null
                                        ? 'Se cotizará según evaluación del taller.'
                                        : 'Servicio base por $_selectedProblem.',
                                    style: const TextStyle(
                                      color: Color(0xFF55637C),
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _selectedProblemPrice == null
                                  ? 'A cotizar'
                                  : 'Bs ${_selectedProblemPrice!}',
                              style: const TextStyle(
                                color: Color(0xFF123F78),
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _SectionCard(
                  title: '4. Confirmar ubicacion',
                  subtitle:
                      'Incluye latitud, longitud, direccion y zona en el mismo envio.',
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
                          border: Border.all(color: const Color(0xFFDCE5F0)),
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
                                  hintText: 'Buscar direccion o zona',
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
                              onPressed:
                                  _isSearchingLocation ? null : _searchLocation,
                              icon: _isSearchingLocation
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
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
                      _EmergencyRequestLocationMap(
                        selectedPoint: _selectedMapPoint,
                        zone: _selectedZone,
                        workshops: _nearbyWorkshops,
                        nearestWorkshopId: _nearestWorkshop?.id,
                        isFetchingLocation: _isFetchingLocation,
                        isFindingNearestWorkshop: _isFindingNearestWorkshop,
                        onCurrentLocationTap:
                            _isFetchingLocation ? null : _useCurrentLocation,
                        onNearestWorkshopTap: _goToNearestWorkshop,
                        onChanged: (point) => _updateSelectedPoint(point),
                        onMapCreated: (controller) {
                          _mapController = controller;
                        },
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFFDBEAFE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.car_repair_rounded,
                                color: Color(0xFF1D4ED8),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _isLoadingNearbyWorkshops
                                    ? 'Cargando talleres cercanos desde el backend...'
                                    : _nearbyWorkshops.isEmpty
                                        ? 'No se recibieron coordenadas de talleres para esta zona.'
                                        : 'Se muestran ${_nearbyWorkshops.length} talleres cercanos como puntos azules en el mapa.',
                                style: const TextStyle(
                                  color: Color(0xFF55637C),
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_nearestWorkshop != null) ...[
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
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF123F78),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFD8AD20),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Taller mas cercano',
                                      style: TextStyle(
                                        color: Color(0xFF123F78),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      [
                                        _nearestWorkshop!.name,
                                        _nearestWorkshop!.specialty,
                                        _nearestWorkshop!.zone,
                                      ]
                                          .where(
                                            (value) =>
                                                (value ?? '').trim().isNotEmpty,
                                          )
                                          .join(' · '),
                                      style: const TextStyle(
                                        color: Color(0xFF55637C),
                                        height: 1.35,
                                      ),
                                    ),
                                    if (_nearestWorkshopDistanceMeters != null)
                                      Text(
                                        'Distancia aproximada: ${_nearestWorkshopDistanceMeters!.toStringAsFixed(0)} m',
                                        style: const TextStyle(
                                          color: Color(0xFF123F78),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
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
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFDCE5F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Direccion final',
                                    style: TextStyle(
                                      color: Color(0xFF101828),
                                      fontWeight: FontWeight.w800,
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
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: !hasVehicles
                        ? null
                        : () async {
                            if (_isRecordingAudio) {
                              await _toggleAudioRecording();
                            }
                            if (!mounted) {
                              return;
                            }
                            final selectedVehicle = _vehicles[
                                _selectedVehicleIndex.clamp(
                                    0, _vehicles.length - 1)];
                            final draft = EmergencyDraft(
                              user: widget.args.user,
                              vehicleName: selectedVehicle.name,
                              vehiclePlate: selectedVehicle.plate,
                              problemType: _selectedProblem,
                              description:
                                  _descriptionController.text.trim().isEmpty
                                      ? null
                                      : _descriptionController.text.trim(),
                              photoPaths: _selectedEvidence
                                  .map((item) => item.path)
                                  .toList(growable: false),
                              audioPath: _recordedAudioPath,
                              audioDurationSeconds:
                                  _durationInSeconds(_recordedAudioDuration),
                              latitude: _selectedMapPoint.latitude,
                              longitude: _selectedMapPoint.longitude,
                              address: _directionText,
                              zone: _selectedZone,
                              nearestWorkshopId: _nearestWorkshop?.id,
                              nearestWorkshopName: _nearestWorkshop?.name,
                              nearestWorkshopSpecialty:
                                  _nearestWorkshop?.specialty,
                              nearestWorkshopZone: _nearestWorkshop?.zone,
                              nearestWorkshopDistanceMeters:
                                  _nearestWorkshopDistanceMeters,
                              price: _selectedProblemPrice,
                            );
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => EmergencySendingScreen(
                                  draft: draft,
                                ),
                              ),
                            );
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD8AD20),
                      foregroundColor: const Color(0xFF123F78),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: const Icon(Icons.send_rounded),
                    label: const Text(
                      'Enviar emergencia',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: 1,
          onDestinationSelected: _openClientTab,
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
                icon: Icon(Icons.person_rounded), label: 'Perfil'),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120B285A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF123F78),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF66758C),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          child,
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

class _EmergencyRequestLocationMap extends StatelessWidget {
  const _EmergencyRequestLocationMap({
    required this.selectedPoint,
    required this.zone,
    required this.workshops,
    required this.nearestWorkshopId,
    required this.isFetchingLocation,
    required this.isFindingNearestWorkshop,
    required this.onCurrentLocationTap,
    required this.onNearestWorkshopTap,
    required this.onChanged,
    required this.onMapCreated,
  });

  final LatLng selectedPoint;
  final String zone;
  final List<WorkshopMapPoint> workshops;
  final String? nearestWorkshopId;
  final bool isFetchingLocation;
  final bool isFindingNearestWorkshop;
  final VoidCallback? onCurrentLocationTap;
  final Future<void> Function() onNearestWorkshopTap;
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

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('selected-location'),
        position: selectedPoint,
        draggable: true,
        onDragEnd: onChanged,
        infoWindow: InfoWindow(
          title: 'Ubicacion marcada',
          snippet: zone,
        ),
      ),
    };

    for (final workshop in workshops) {
      final isNearestWorkshop = workshop.id == nearestWorkshopId;
      markers.add(
        Marker(
          markerId: MarkerId('workshop-${workshop.id}'),
          position: LatLng(workshop.latitude, workshop.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isNearestWorkshop
                ? BitmapDescriptor.hueOrange
                : BitmapDescriptor.hueAzure,
          ),
          infoWindow: InfoWindow(
            title: workshop.specialty?.trim().isNotEmpty == true
                ? workshop.specialty
                : workshop.name,
            snippet: [
              workshop.name,
              workshop.zone,
            ].where((value) => (value ?? '').trim().isNotEmpty).join(' - '),
          ),
        ),
      );
    }

    return SizedBox(
      height: 360,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            GoogleMap(
              onMapCreated: onMapCreated,
              initialCameraPosition: const CameraPosition(
                target: _EmergencyRequestScreenState._defaultSantaCruzLocation,
                zoom: 12.8,
              ),
              mapType: MapType.normal,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
              compassEnabled: true,
              buildingsEnabled: true,
              onTap: onChanged,
              markers: markers,
            ),
            Positioned(
              top: 16,
              left: 16,
              child: SizedBox(
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
                      : const Icon(Icons.my_location_rounded),
                ),
              ),
            ),
            Positioned(
              top: 80,
              left: 16,
              child: SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: isFindingNearestWorkshop
                      ? null
                      : () async {
                          await onNearestWorkshopTap();
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF123F78),
                    foregroundColor: const Color(0xFFD8AD20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  child: isFindingNearestWorkshop
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.near_me_rounded),
                ),
              ),
            ),
          ],
        ),
      ),
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
        borderRadius: BorderRadius.circular(16),
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
          const SizedBox(height: 4),
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
      height: 360,
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

class _EvidenceImageCard extends StatelessWidget {
  const _EvidenceImageCard({
    required this.imagePath,
    required this.onRemove,
  });

  final String imagePath;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(
            File(imagePath),
            width: 96,
            height: 96,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: -6,
          left: -6,
          child: InkWell(
            onTap: onRemove,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD9DDEE)),
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 15,
                color: Color(0xFF8A5CF6),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EvidenceActionTile extends StatelessWidget {
  const _EvidenceActionTile({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 112,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: accentColor == const Color(0xFFD8AD20)
              ? const Color(0xFFFFF8DE)
              : const Color(0xFFF4F7FB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: accentColor.withOpacity(0.35),
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: accentColor, size: 26),
            const SizedBox(height: 10),
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioPreviewCard extends StatelessWidget {
  const _AudioPreviewCard({
    required this.hasAudio,
    required this.isRecording,
    required this.isPlaying,
    required this.onDelete,
  });

  final bool hasAudio;
  final bool isRecording;
  final bool isPlaying;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    const bars = <double>[
      10,
      18,
      28,
      16,
      34,
      22,
      12,
      30,
      14,
      26,
      20,
      12,
      24,
      18,
      10,
      28,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8E0EA)),
      ),
      child: Row(
        children: [
          Icon(
            isRecording
                ? Icons.graphic_eq_rounded
                : isPlaying
                    ? Icons.pause_circle_filled_rounded
                    : Icons.volume_up_rounded,
            color: const Color(0xFF123F78),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: bars
                  .map(
                    (height) => Container(
                      width: 3,
                      height: height,
                      decoration: BoxDecoration(
                        color: hasAudio || isRecording
                            ? const Color(0xFF3F4754)
                            : const Color(0xFFD0D6E2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: onDelete,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.delete_outline_rounded,
              color:
                  hasAudio ? const Color(0xFF98A2B3) : const Color(0xFFD0D6E2),
            ),
          ),
        ],
      ),
    );
  }
}

class _AudioActionTile extends StatelessWidget {
  const _AudioActionTile({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 116,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: accentColor == const Color(0xFF66758C)
              ? const Color(0xFFF4F7FB)
              : const Color(0xFFF3F7FF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: accentColor.withOpacity(0.18),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: accentColor,
                size: 28,
              ),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF3F4754),
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProblemTypeTile extends StatelessWidget {
  const _ProblemTypeTile({
    required this.label,
    required this.icon,
    required this.price,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final int? price;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 144,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF7DB) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFFD8AD20) : const Color(0xFFD8E0EA),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x10D8AD20),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            if (selected)
              const Align(
                alignment: Alignment.topRight,
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: Color(0xFF123F78),
                ),
              ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 26,
                    color: const Color(0xFF3F4754),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF3F4754),
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      height: 1.15,
                    ),
                  ),
                  if (price != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0x1FD8AD20)
                            : const Color(0xFFF4F7FB),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Bs $price',
                        style: TextStyle(
                          color: selected
                              ? const Color(0xFF123F78)
                              : const Color(0xFF66758C),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleOption {
  const _VehicleOption({
    required this.name,
    required this.plate,
    required this.icon,
  });

  final String name;
  final String plate;
  final IconData icon;
}

class _ProblemOption {
  const _ProblemOption({
    required this.label,
    required this.icon,
    this.price,
  });

  final String label;
  final IconData icon;
  final int? price;
}
