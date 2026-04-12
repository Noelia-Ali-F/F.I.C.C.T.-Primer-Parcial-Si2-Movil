import 'dart:async';

import 'package:flutter/material.dart';

import '../app_routes.dart';
import 'client_registration_form_screen.dart';

class ClientRegistrationValidationScreen extends StatefulWidget {
  const ClientRegistrationValidationScreen({
    super.key,
    required this.data,
  });

  final ClientRegistrationData data;

  @override
  State<ClientRegistrationValidationScreen> createState() =>
      _ClientRegistrationValidationScreenState();
}

class _ClientRegistrationValidationScreenState
    extends State<ClientRegistrationValidationScreen> {
  final List<bool> _completedChecks = List<bool>.filled(5, false);
  Timer? _timer;
  bool _finished = false;
  int _currentStep = 0;

  late final List<_ValidationItem> _items = [
    _ValidationItem(
      title: 'Campos obligatorios',
      isValid: widget.data.fullName.isNotEmpty &&
          widget.data.email.isNotEmpty &&
          widget.data.phone.isNotEmpty &&
          widget.data.password.isNotEmpty,
    ),
    _ValidationItem(
      title: 'Formato de correo',
      isValid: RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(widget.data.email),
    ),
    _ValidationItem(
      title: 'Teléfono válido',
      isValid: widget.data.phone.replaceAll(RegExp(r'\D'), '').length >= 8,
    ),
    _ValidationItem(
      title: 'Contraseña segura',
      isValid: widget.data.password.length >= 8,
    ),
    const _ValidationItem(
      title: 'Correo disponible',
      isValid: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startValidationAnimation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startValidationAnimation() {
    _timer = Timer.periodic(const Duration(milliseconds: 550), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_currentStep >= _items.length) {
        timer.cancel();
        setState(() => _finished = true);
        return;
      }

      setState(() {
        _completedChecks[_currentStep] = true;
        _currentStep += 1;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final allPassed = _items.every((item) => item.isValid);

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
                        'Validación de datos',
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
                  'Estamos revisando la información del cliente con la misma identidad visual del proyecto.',
                  style: TextStyle(
                    color: Colors.white,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
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
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF123F78),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _finished && allPassed
                              ? 'Información validada'
                              : 'Validando información...',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEE),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFEACB63)),
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < _items.length; i++) ...[
                              _ValidationRow(
                                title: _items[i].title,
                                done: _completedChecks[i],
                                success: _items[i].isValid,
                              ),
                              if (i != _items.length - 1) const SizedBox(height: 14),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      if (!_finished)
                        const Column(
                          children: [
                            SizedBox(
                              width: 34,
                              height: 34,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Color(0xFF123F78),
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Validando...',
                              style: TextStyle(
                                color: Color(0xFF55637C),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      if (_finished) ...[
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: allPassed
                                ? const Color(0x1427AE60)
                                : const Color(0x14D92D20),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            allPassed
                                ? Icons.check_circle_rounded
                                : Icons.error_rounded,
                            size: 42,
                            color: allPassed
                                ? const Color(0xFF27AE60)
                                : const Color(0xFFD92D20),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          allPassed
                              ? 'Tu registro de cliente está listo.'
                              : 'Revisa los datos ingresados e inténtalo nuevamente.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF55637C),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () {
                              if (allPassed) {
                                Navigator.of(context).pushNamed(
                                  AppRoutes.clientEmailOtp,
                                  arguments: widget.data,
                                );
                                return;
                              }
                              Navigator.of(context).pop();
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFD8AD20),
                              foregroundColor: const Color(0xFF123F78),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              allPassed ? 'Finalizar' : 'Volver al registro',
                              style: const TextStyle(fontWeight: FontWeight.w900),
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
        ),
      ),
    );
  }
}

class _ValidationRow extends StatelessWidget {
  const _ValidationRow({
    required this.title,
    required this.done,
    required this.success,
  });

  final String title;
  final bool done;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final color = !done
        ? const Color(0xFF98A2B3)
        : success
            ? const Color(0xFF27AE60)
            : const Color(0xFFD92D20);

    final icon = !done
        ? Icons.radio_button_unchecked_rounded
        : success
            ? Icons.check_circle_rounded
            : Icons.cancel_rounded;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: done ? 1 : 0.75,
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: const Color(0xFF101828),
                fontWeight: done ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ValidationItem {
  const _ValidationItem({
    required this.title,
    required this.isValid,
  });

  final String title;
  final bool isValid;
}
