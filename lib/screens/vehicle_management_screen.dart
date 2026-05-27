import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/auth_models.dart';
import '../services/vehicle_service.dart';
import 'emergency_request_screen.dart';
import 'vehicle_edit_screen.dart';
import 'vehicle_registration_screen.dart';

class VehicleManagementScreen extends StatefulWidget {
  const VehicleManagementScreen({
    super.key,
    required this.user,
    required this.clientId,
    required this.initialVehicles,
  });

  final FakeAuthUser user;
  final int? clientId;
  final List<String> initialVehicles;

  @override
  State<VehicleManagementScreen> createState() =>
      _VehicleManagementScreenState();
}

class _ManagedVehicle {
  _ManagedVehicle({
    required this.summary,
    this.id,
    this.color,
    this.photoUrl,
  }) : imagePath = null;

  String summary;
  String? imagePath;
  int? id;
  String? color;
  String? photoUrl;

  bool get isPrimary => summary.contains('Principal');

  String get _cleanSummary => summary.replaceAll(' · Principal', '').trim();

  List<String> get _parts =>
      _cleanSummary.split('·').map((part) => part.trim()).toList();

  List<String> get _leftTokens {
    if (_parts.isEmpty) {
      return const [];
    }
    return _parts.first
        .split(RegExp(r'\s+'))
        .where((token) => token.trim().isNotEmpty)
        .toList();
  }

  String get brand {
    if (_leftTokens.isEmpty) {
      return '';
    }
    return _leftTokens.first;
  }

  String get year {
    if (_leftTokens.isEmpty) {
      return '';
    }
    final last = _leftTokens.last;
    return RegExp(r'^\d{4}$').hasMatch(last) ? last : '';
  }

  String get model {
    if (_leftTokens.length <= 1) {
      return '';
    }

    final endIndex =
        year.isNotEmpty ? _leftTokens.length - 1 : _leftTokens.length;
    return _leftTokens.sublist(1, endIndex).join(' ');
  }

  String get plate {
    if (_parts.length < 2) {
      return '';
    }
    return _parts[1].trim();
  }

  String get title {
    final titleParts = [
      brand,
      if (model.isNotEmpty) model,
      if (year.isNotEmpty) year,
    ].where((part) => part.isNotEmpty).toList();
    return titleParts.join(' ');
  }

  String get subtitle {
    return plate.isNotEmpty ? plate : 'Vehículo registrado';
  }
}

class _VehicleManagementScreenState extends State<VehicleManagementScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  void _openEmergencyRequest() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EmergencyRequestScreen(
          args: EmergencyRequestArgs(
            user: widget.user,
            clientId: widget.clientId,
          ),
        ),
      ),
    );
  }

  late List<_ManagedVehicle> _managedVehicles;
  bool _isLoadingVehicles = true;

  @override
  void initState() {
    super.initState();
    _managedVehicles = widget.initialVehicles
        .map((vehicle) => _ManagedVehicle(summary: vehicle))
        .toList();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    final clientId = widget.clientId;
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
        _managedVehicles = backendVehicles
            .map(
              (vehicle) => _ManagedVehicle(
                id: vehicle.id,
                summary: vehicle.isPrimary
                    ? '${vehicle.summary} · Principal'
                    : vehicle.summary,
                color: vehicle.color,
                photoUrl: vehicle.photoUrl,
              ),
            )
            .toList();
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

  void _normalizePrimaryVehicle() {
    if (_managedVehicles.isEmpty) {
      return;
    }

    final hasPrimary = _managedVehicles.any((vehicle) => vehicle.isPrimary);
    if (hasPrimary) {
      return;
    }

    _managedVehicles[0].summary =
        '${_managedVehicles[0].summary.replaceAll(' · Principal', '')} · Principal';
  }

  Future<void> _captureVehiclePhoto({
    required int index,
    required String title,
  }) async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image == null || !mounted) {
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      final extension = image.path.contains('.')
          ? image.path.substring(image.path.lastIndexOf('.'))
          : '.jpg';
      final savedImage = await File(image.path).copy(
        '${directory.path}/vehicle-${DateTime.now().millisecondsSinceEpoch}$extension',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _managedVehicles[index].imagePath = savedImage.path;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Foto actualizada para $title.'),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo tomar o guardar la foto del vehículo.'),
        ),
      );
    }
  }

  Future<void> _deleteVehicle({
    required int index,
    required String title,
  }) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar vehículo'),
        content: Text('¿Deseas eliminar "$title" de tu lista de vehículos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    final vehicle = _managedVehicles[index];
    if (vehicle.id != null) {
      final response = await VehicleService.deleteVehicle(vehicle.id!);
      if (!mounted) {
        return;
      }

      if (!response.isSuccess) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Eliminación no enviada'),
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
    }

    setState(() {
      _managedVehicles.removeAt(index);
      _normalizePrimaryVehicle();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          vehicle.id == null
              ? 'Vehículo eliminado localmente.'
              : 'Vehículo eliminado correctamente.',
        ),
      ),
    );
  }

  Future<void> _openVehicleRegistrationScreen() async {
    final result = await Navigator.of(context).push<VehicleRegistrationResult>(
      MaterialPageRoute(
        builder: (_) => VehicleRegistrationScreen(
          clientId: widget.clientId,
        ),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      if (result.isPrimary) {
        for (final vehicle in _managedVehicles) {
          vehicle.summary = vehicle.summary.replaceAll(' · Principal', '');
        }
        _managedVehicles.insert(
          0,
          _ManagedVehicle(summary: '${result.summary} · Principal'),
        );
      } else {
        _managedVehicles.add(_ManagedVehicle(summary: result.summary));
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vehículo agregado correctamente.'),
      ),
    );
  }

  Future<void> _openVehicleEditScreen({
    required int index,
    required _ManagedVehicle vehicle,
  }) async {
    final result = await Navigator.of(context).push<VehicleEditResult>(
      MaterialPageRoute(
        builder: (_) => VehicleEditScreen(
          args: VehicleEditArgs(
            id: vehicle.id,
            clientId: widget.clientId ?? 0,
            brand: vehicle.brand,
            model: vehicle.model,
            year: vehicle.year,
            plate: vehicle.plate,
            color: vehicle.color ?? 'gris',
            isPrimary: vehicle.isPrimary,
          ),
        ),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      if (result.isPrimary) {
        for (final vehicle in _managedVehicles) {
          vehicle.summary = vehicle.summary.replaceAll(' · Principal', '');
        }
      }

      _managedVehicles[index].summary =
          result.isPrimary ? '${result.summary} · Principal' : result.summary;
      _managedVehicles[index].color = result.color;
      _normalizePrimaryVehicle();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vehículo actualizado correctamente.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD8AD20),
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0x24FFFFFF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'MIS VEHÍCULOS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Administra tus vehículos con la identidad visual del proyecto.',
                  style: TextStyle(
                    color: Colors.white,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
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
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF123F78),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gestión de vehículos',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Selecciona un vehículo activo, edítalo, elimínalo o agrega uno nuevo.',
                              style: TextStyle(
                                color: Color(0xE8FFFFFF),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_isLoadingVehicles)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF123F78),
                            ),
                          ),
                        )
                      else
                        ...List.generate(_managedVehicles.length, (index) {
                          final vehicle = _managedVehicles[index];
                          final title = vehicle.title;
                          final subtitle = vehicle.subtitle;
                          final isPrimary = vehicle.isPrimary || index == 0;

                          return Padding(
                            padding: EdgeInsets.only(
                              bottom:
                                  index == _managedVehicles.length - 1 ? 0 : 12,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEE),
                                borderRadius: BorderRadius.circular(18),
                                border:
                                    Border.all(color: const Color(0xFFEACB63)),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          _captureVehiclePhoto(
                                            index: index,
                                            title: title,
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(14),
                                        child: Container(
                                          width: 62,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            border: Border.all(
                                              color: const Color(0xFFEACB63),
                                            ),
                                            image: vehicle.imagePath == null
                                                ? vehicle.photoUrl == null ||
                                                        vehicle.photoUrl!
                                                            .trim()
                                                            .isEmpty
                                                    ? null
                                                    : DecorationImage(
                                                        image: NetworkImage(
                                                          vehicle.photoUrl!,
                                                        ),
                                                        fit: BoxFit.cover,
                                                      )
                                                : DecorationImage(
                                                    image: FileImage(
                                                      File(vehicle.imagePath!),
                                                    ),
                                                    fit: BoxFit.cover,
                                                  ),
                                          ),
                                          child: vehicle.imagePath == null
                                              ? const Icon(
                                                  Icons
                                                      .directions_car_filled_rounded,
                                                  size: 34,
                                                  color: Color(0xFF123F78),
                                                )
                                              : Align(
                                                  alignment:
                                                      Alignment.bottomRight,
                                                  child: Container(
                                                    margin:
                                                        const EdgeInsets.all(4),
                                                    padding:
                                                        const EdgeInsets.all(3),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black54,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              999),
                                                    ),
                                                    child: const Icon(
                                                      Icons.camera_alt_rounded,
                                                      size: 12,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF101828),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              subtitle,
                                              style: const TextStyle(
                                                color: Color(0xFF66758C),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isPrimary)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF4D8E50),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: const Text(
                                            'ACTIVO',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        )
                                      else
                                        const Icon(
                                          Icons.check_rounded,
                                          color: Color(0xFF4D8E50),
                                          size: 26,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      vehicle.imagePath == null
                                          ? 'Toca el recuadro para tomar una foto.'
                                          : 'Toca la imagen para reemplazar la foto.',
                                      style: const TextStyle(
                                        color: Color(0xFF66758C),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () {
                                          _deleteVehicle(
                                            index: index,
                                            title: title,
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          size: 18,
                                        ),
                                        label: const Text('Eliminar'),
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              const Color(0xFFD14130),
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: () {
                                          _openVehicleEditScreen(
                                            index: index,
                                            vehicle: vehicle,
                                          );
                                        },
                                        icon: const Icon(Icons.edit_rounded,
                                            size: 18),
                                        label: const Text('Editar'),
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              const Color(0xFF123F78),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: _openVehicleRegistrationScreen,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7DB),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFEACB63)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_rounded, color: Color(0xFF123F78)),
                              SizedBox(width: 10),
                              Text(
                                'Agregar Vehículo',
                                style: TextStyle(
                                  color: Color(0xFF123F78),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _openEmergencyRequest,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFC97C7E),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lock_rounded, size: 20),
                              SizedBox(width: 10),
                              Text(
                                'AGREGAR EMERGENCIA',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
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
      ),
    );
  }
}
