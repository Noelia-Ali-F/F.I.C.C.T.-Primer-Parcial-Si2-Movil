import 'dart:io';

import 'package:flutter/material.dart';

import '../models/emergency_models.dart';
import '../utils/double_back_logout_scope.dart';
import '../widgets/emergency_flow_stepper.dart';
import 'emergency_sending_screen.dart';

class EmergencyReviewScreen extends StatefulWidget {
  const EmergencyReviewScreen({super.key, required this.args});

  final EmergencyReviewArgs args;

  @override
  State<EmergencyReviewScreen> createState() => _EmergencyReviewScreenState();
}

class _EmergencyReviewScreenState extends State<EmergencyReviewScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _shareLiveLocation = true;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _formatAudioDuration(double? totalSeconds) {
    if (totalSeconds == null) {
      return '00:00';
    }
    final roundedSeconds = totalSeconds.round();
    final minutes = (roundedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (roundedSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.args.draft;

    return DoubleBackLogoutScope(
      child: Scaffold(
        backgroundColor: const Color(0xFFF7FAFE),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF7FAFE),
          surfaceTintColor: const Color(0xFFF7FAFE),
          title: const Text(
            'Revisar y Enviar',
            style: TextStyle(
              color: Color(0xFF123F78),
              fontWeight: FontWeight.w900,
            ),
          ),
          iconTheme: const IconThemeData(color: Color(0xFF123F78)),
          actions: [
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(
                Icons.help_outline_rounded,
                color: Color(0xFF123F78),
              ),
              label: const Text(
                'Ayuda',
                style: TextStyle(
                  color: Color(0xFF123F78),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
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
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF123F78), Color(0xFF215FA7)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x220B285A),
                        blurRadius: 18,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Revisar y Enviar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Verifica la información antes de enviar tu emergencia.',
                        style: TextStyle(
                          color: Color(0xE8FFFFFF),
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const EmergencyFlowStepper(
                  currentStep: 4,
                  helperText:
                      'Revisa toda la informacion antes de confirmar el envio final.',
                ),
                const SizedBox(height: 18),
                Theme(
                  data: Theme.of(context).copyWith(
                    switchTheme: SwitchThemeData(
                      thumbColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return const Color(0xFFD8AD20);
                        }
                        return Colors.white;
                      }),
                      trackColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return const Color(0xFF123F78);
                        }
                        return const Color(0xFFD0D5DD);
                      }),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ReviewCard(
                        label: 'VEHÍCULO',
                        icon: Icons.directions_car_filled_rounded,
                        child: Row(
                          children: [
                            if (draft.photoPaths.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(draft.photoPaths.first),
                                  width: 74,
                                  height: 54,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else
                              Container(
                                width: 74,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF7DB),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.directions_car_filled_rounded,
                                  color: Color(0xFF123F78),
                                ),
                              ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    draft.vehicleName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF101828),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Placa: ${draft.vehiclePlate}',
                                    style: const TextStyle(
                                        color: Color(0xFF66758C)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _ReviewCard(
                        label: 'PROBLEMA',
                        icon: Icons.report_problem_rounded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              draft.problemType,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF101828),
                              ),
                            ),
                            if ((draft.description ?? '')
                                .trim()
                                .isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                draft.description!,
                                style:
                                    const TextStyle(color: Color(0xFF66758C)),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _ReviewCard(
                        label: 'EVIDENCIA',
                        icon: Icons.perm_media_rounded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${draft.photoPaths.length} ${draft.photoPaths.length == 1 ? 'Foto' : 'Fotos'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF101828),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              draft.hasAudio
                                  ? '1 Audio (${_formatAudioDuration(draft.audioDurationSeconds)})'
                                  : 'Sin audio adjunto',
                              style: const TextStyle(color: Color(0xFF66758C)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _ReviewCard(
                        label: 'UBICACIÓN',
                        icon: Icons.location_on_rounded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Santa Cruz de la Sierra, Bolivia',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF101828),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.args.zone} · ${widget.args.latitude.toStringAsFixed(5)}, ${widget.args.longitude.toStringAsFixed(5)}',
                              style: const TextStyle(
                                color: Color(0xFF66758C),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _ReviewCard(
                        label: 'OPCIONES',
                        icon: Icons.settings_rounded,
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _shareLiveLocation,
                          onChanged: (value) {
                            setState(() => _shareLiveLocation = value);
                          },
                          title: const Text(
                            'Compartiendo ubicación en tiempo real',
                            style: TextStyle(
                              color: Color(0xFF101828),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: const Text(
                            'Permite que el operador siga tu ubicación durante la atención.',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Comentario adicional (opcional)',
                  style: TextStyle(
                    color: Color(0xFF123F78),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _commentController,
                  maxLines: 4,
                  maxLength: 300,
                  decoration: InputDecoration(
                    hintText: 'Escribe algo más que consideres importante...',
                    counterStyle: const TextStyle(
                      color: Color(0xFF98A2B3),
                      fontWeight: FontWeight.w600,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Color(0xFFD8E0EA)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Color(0xFFD8E0EA)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: Color(0xFF123F78),
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => EmergencySendingScreen(
                            draft: draft,
                          ),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF123F78),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'ENVIAR EMERGENCIA',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'Se creó un incidente y un especialista atenderá tu solicitud',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF66758C),
                      fontWeight: FontWeight.w600,
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
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.label,
    required this.icon,
    required this.child,
  });

  final String label;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7ECF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120B285A),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7DB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: const Color(0xFF123F78),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF123F78),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
