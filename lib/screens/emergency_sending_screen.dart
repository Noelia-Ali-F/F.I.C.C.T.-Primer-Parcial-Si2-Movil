import 'package:flutter/material.dart';

import '../models/emergency_models.dart';
import '../services/alert_service.dart';
import '../services/emergency_service.dart';
import '../utils/double_back_logout_scope.dart';
import 'emergency_success_screen.dart';

class EmergencySendingScreen extends StatefulWidget {
  const EmergencySendingScreen({
    super.key,
    required this.draft,
  });

  final EmergencyDraft draft;

  @override
  State<EmergencySendingScreen> createState() => _EmergencySendingScreenState();
}

class _EmergencySendingScreenState extends State<EmergencySendingScreen> {
  static const List<String> _steps = [
    'Creando incidente',
    'Subiendo archivos',
    'Enviando ubicación',
    'Notificando operadores',
  ];

  int _completedSteps = 0;
  bool _isSubmitting = true;
  String? _errorMessage;
  String? _incidentId;
  int? _statusCode;

  @override
  void initState() {
    super.initState();
    _submitEmergency();
  }

  @override
  void dispose() => super.dispose();

  Future<void> _advanceTo(int step) async {
    if (!mounted) {
      return;
    }
    setState(() => _completedSteps = step);
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  Future<void> _submitEmergency() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _statusCode = null;
      _completedSteps = 0;
    });

    // Avanzamos la UI antes de enviar para dar feedback inmediato al usuario.
    await _advanceTo(1);
    await _advanceTo(2);

    final response = await EmergencyService.submitEmergency(widget.draft);
    if (!mounted) {
      return;
    }

    if (!response.isSuccess) {
      AlertService.registerEmergencyFailed(response.message);
      setState(() {
        _isSubmitting = false;
        _errorMessage = response.message;
        _statusCode = response.statusCode;
      });
      return;
    }

    _incidentId = response.incidentId;
    AlertService.registerEmergencySubmitted(
      incidentNumber: _incidentId ?? 'EMG-PENDIENTE',
      vehicleName: widget.draft.vehicleName,
      problemType: widget.draft.problemType,
      etaLabel: '15 - 20 min',
    );
    await _advanceTo(3);
    await _advanceTo(4);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => EmergencySuccessScreen(
          user: widget.draft.user,
          incidentNumber: _incidentId ?? 'EMG-PENDIENTE',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DoubleBackLogoutScope(
      child: Scaffold(
        backgroundColor: const Color(0xFFF7FAFE),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFFE7ECF3)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x140B285A),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 52,
                        height: 52,
                        child: CircularProgressIndicator(
                          strokeWidth: 4,
                          valueColor: AlwaysStoppedAnimation(Color(0xFF123F78)),
                          backgroundColor: Color(0xFFE7ECF3),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        _errorMessage == null
                            ? 'Enviando emergencia...'
                            : 'No se pudo enviar',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF101828),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _errorMessage == null
                            ? 'Por favor espera mientras procesamos tu solicitud'
                            : _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF66758C),
                          fontWeight: FontWeight.w600,
                          height: 1.45,
                        ),
                      ),
                      if (_errorMessage != null && (_statusCode ?? 0) > 0) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF4E5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFEACB63)),
                          ),
                          child: Text(
                            'HTTP ${_statusCode!}',
                            style: const TextStyle(
                              color: Color(0xFF9A6700),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFD),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE7ECF3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Payload preparado',
                              style: TextStyle(
                                color: Color(0xFF123F78),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${widget.draft.vehicleName} · ${widget.draft.problemType}',
                              style: const TextStyle(
                                color: Color(0xFF101828),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.draft.address ?? 'Direccion no disponible'} · ${widget.draft.zone ?? 'Zona no disponible'}',
                              style: const TextStyle(
                                color: Color(0xFF66758C),
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${widget.draft.photoPaths.length} fotos · ${widget.draft.hasAudio ? 'con audio' : 'sin audio'}',
                              style: const TextStyle(
                                color: Color(0xFF66758C),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ...List.generate(_steps.length, (index) {
                        final completed = index < _completedSteps;
                        final active =
                            _isSubmitting && index == _completedSteps;
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == _steps.length - 1 ? 0 : 14,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: completed
                                      ? const Color(0xFFE8F7EA)
                                      : active
                                          ? const Color(0xFFFFF7DB)
                                          : const Color(0xFFF4F7FB),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  completed
                                      ? Icons.check_rounded
                                      : active
                                          ? Icons.more_horiz_rounded
                                          : Icons.circle_outlined,
                                  size: 16,
                                  color: completed
                                      ? const Color(0xFF31A24C)
                                      : active
                                          ? const Color(0xFFD8AD20)
                                          : const Color(0xFF98A2B3),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _steps[index],
                                  style: TextStyle(
                                    color: completed || active
                                        ? const Color(0xFF101828)
                                        : const Color(0xFF98A2B3),
                                    fontWeight: completed || active
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _submitEmergency,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF123F78),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Reintentar envio',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
