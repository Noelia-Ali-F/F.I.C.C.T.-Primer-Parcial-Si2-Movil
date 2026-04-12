import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class EmergencyRequestArgs {
  const EmergencyRequestArgs({
    required this.location,
    required this.zone,
  });

  final LatLng location;
  final String zone;
}

class EmergencyRequestScreen extends StatefulWidget {
  const EmergencyRequestScreen({super.key, required this.args});

  final EmergencyRequestArgs args;

  @override
  State<EmergencyRequestScreen> createState() => _EmergencyRequestScreenState();
}

class _EmergencyRequestScreenState extends State<EmergencyRequestScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();

  final List<_VehicleOption> _vehicles = const [
    _VehicleOption(
      name: 'Ford Focus 2018',
      plate: '1025HNA',
      icon: Icons.directions_car_filled_rounded,
    ),
    _VehicleOption(
      name: 'Toyota Yaris 2020',
      plate: 'GAE5877',
      icon: Icons.drive_eta_rounded,
    ),
    _VehicleOption(
      name: 'Hyundai Tucson 2017',
      plate: 'PAS18866',
      icon: Icons.airport_shuttle_rounded,
    ),
  ];

  final List<String> _problemTypes = const [
    'Batería',
    'Neumático',
    'Combustible',
    'Motor',
    'Choque leve',
    'Remolque',
  ];

  int _selectedVehicleIndex = 0;
  String _selectedProblem = 'Batería';
  XFile? _selectedEvidence;
  bool _isPickingImage = false;
  bool _isRecordingAudio = false;
  String? _recordedAudioPath;

  Future<void> _showSuccessDialog() async {
    await showGeneralDialog<void>(
      context: context,
      barrierLabel: 'Registro exitoso',
      barrierDismissible: true,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => const _EmergencySuccessDialog(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeIn,
        );

        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.86, end: 1).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _toggleAudioRecording() async {
    if (_isRecordingAudio) {
      final path = await _audioRecorder.stop();
      if (!mounted) {
        return;
      }

      setState(() {
        _isRecordingAudio = false;
        _recordedAudioPath = path;
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
          content: Text('Debes aceptar el permiso del micrófono para grabar audio.'),
        ),
      );
      return;
    }

    final directory = await getTemporaryDirectory();
    final filePath =
        '${directory.path}/emergency-audio-${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _audioRecorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: filePath,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isRecordingAudio = true;
      _recordedAudioPath = null;
    });
  }

  Future<void> _pickEvidence(ImageSource source) async {
    if (_isPickingImage) {
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

      setState(() => _selectedEvidence = image);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir la cámara o la galería en este momento.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = _vehicles[_selectedVehicleIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('Registrar Emergencia'),
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
                      'Nueva emergencia',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ubicación marcada: ${widget.args.zone} · ${widget.args.location.latitude.toStringAsFixed(4)}, ${widget.args.location.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(
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
                subtitle: 'Elige uno de tus vehículos registrados para esta emergencia.',
                child: Column(
                  children: List.generate(_vehicles.length, (index) {
                    final item = _vehicles[index];
                    final selected = index == _selectedVehicleIndex;
                    return Padding(
                      padding: EdgeInsets.only(bottom: index == _vehicles.length - 1 ? 0 : 12),
                      child: InkWell(
                        onTap: () => setState(() => _selectedVehicleIndex = index),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: selected ? const Color(0xFFFFF7DB) : Colors.white,
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
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(item.icon, color: const Color(0xFF123F78)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                      style: const TextStyle(color: Color(0xFF66758C)),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                selected
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
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
                subtitle: 'Indica el incidente principal para asignar mejor la ayuda.',
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _problemTypes.map((problem) {
                    final selected = problem == _selectedProblem;
                    return ChoiceChip(
                      label: Text(problem),
                      selected: selected,
                      onSelected: (_) => setState(() => _selectedProblem = problem),
                      selectedColor: const Color(0xFFD8AD20),
                      backgroundColor: const Color(0xFFF4F7FB),
                      labelStyle: TextStyle(
                        color: selected ? const Color(0xFF123F78) : const Color(0xFF55637C),
                        fontWeight: FontWeight.w700,
                      ),
                      side: BorderSide(
                        color: selected ? const Color(0xFFD8AD20) : const Color(0xFFD8E0EA),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: '3. Añadir evidencia',
                subtitle: 'Describe el problema y registra evidencia visual de apoyo.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Descripción opcional de la emergencia...',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFD),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFD8E0EA)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFD8E0EA)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF123F78), width: 1.4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _EvidenceTile(
                            icon: _isRecordingAudio
                                ? Icons.stop_circle_rounded
                                : Icons.mic_rounded,
                            title: _isRecordingAudio
                                ? 'Detener audio'
                                : 'Grabar audio',
                            subtitle: _isRecordingAudio
                                ? 'Grabando evidencia'
                                : 'Usar micrófono',
                            onTap: _toggleAudioRecording,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _EvidenceTile(
                            icon: Icons.photo_camera_rounded,
                            title: 'Tomar evidencia',
                            subtitle: 'Usar cámara',
                            onTap: () => _pickEvidence(ImageSource.camera),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedEvidence != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFD),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFD8E0EA)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Evidencia adjunta',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF123F78),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.file(
                                File(_selectedEvidence!.path),
                                height: 170,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_recordedAudioPath != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFD),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFD8E0EA)),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.audio_file_rounded,
                              color: Color(0xFF123F78),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Audio de evidencia grabado correctamente.',
                                style: TextStyle(
                                  color: Color(0xFF123F78),
                                  fontWeight: FontWeight.w700,
                                ),
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
                              'GPS registrado en ${widget.args.zone} para ${vehicle.name} con problema: $_selectedProblem.',
                              style: const TextStyle(
                                color: Color(0xFF55637C),
                                height: 1.35,
                              ),
                            ),
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
                  onPressed: () async {
                    if (_isRecordingAudio) {
                      await _toggleAudioRecording();
                    }
                    if (!mounted) {
                      return;
                    }
                    await _showSuccessDialog();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFD8AD20),
                    foregroundColor: const Color(0xFF123F78),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text(
                    'Registrar Emergencia',
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

class _EvidenceTile extends StatelessWidget {
  const _EvidenceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFD),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD8E0EA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0x14D8AD20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF123F78)),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF123F78),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF66758C)),
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
