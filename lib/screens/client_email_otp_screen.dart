import 'dart:async';

import 'package:flutter/material.dart';

import '../app_routes.dart';
import '../services/client_registration_service.dart';
import 'client_registration_form_screen.dart';

class ClientEmailOtpScreen extends StatefulWidget {
  const ClientEmailOtpScreen({
    super.key,
    required this.data,
  });

  final ClientRegistrationData data;

  @override
  State<ClientEmailOtpScreen> createState() => _ClientEmailOtpScreenState();
}

class _ClientEmailOtpScreenState extends State<ClientEmailOtpScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(
      text: ['2', '4', '6', '8', '1', '3'][index],
    ),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  Timer? _timer;
  int _secondsRemaining = 45;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    _secondsRemaining = 45;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_secondsRemaining == 0) {
        timer.cancel();
        return;
      }

      setState(() => _secondsRemaining -= 1);
    });
  }

  bool get _canVerify =>
      _controllers.every((controller) => controller.text.trim().length == 1);

  Future<void> _submitRegistration() async {
    if (_isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await ClientRegistrationService.registerClient(widget.data);

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);

    if (!result.isSuccess) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Registro no enviado'),
          content: Text(
            result.statusCode == 0
                ? result.message
                : 'Backend: ${result.statusCode}\n${result.message}',
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

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Registro confirmado'),
        content: Text(
          result.clientId == null
              ? 'Backend: ${result.statusCode}\nEl cliente fue creado correctamente.'
              : 'Backend: ${result.statusCode}\nCliente creado con ID ${result.clientId}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacementNamed(
      AppRoutes.clientRegistrationSuccess,
      arguments: widget.data,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6C40E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const Spacer(),
              const Text(
                'Verificación OTP',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 26),
              const Text(
                'Ingresa el código OTP enviado a',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.data.email,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  return Padding(
                    padding: EdgeInsets.only(right: index == 5 ? 0 : 10),
                    child: SizedBox(
                      width: 42,
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF101828),
                              width: 1.4,
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty && index < 5) {
                            _focusNodes[index + 1].requestFocus();
                          }
                          setState(() {});
                        },
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 28),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                children: [
                  const Text(
                    '¿No recibiste el OTP?',
                    style: TextStyle(fontSize: 13, color: Color(0xA6000000)),
                  ),
                  TextButton(
                    onPressed: _secondsRemaining == 0
                        ? () {
                            setState(_startCountdown);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Se envió un nuevo código de verificación.'),
                              ),
                            );
                          }
                        : null,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFA66300),
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      _secondsRemaining == 0
                          ? 'REENVIAR OTP'
                          : 'REENVIAR OTP (${_secondsRemaining.toString().padLeft(2, '0')})',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: 210,
                child: FilledButton(
                  onPressed: _canVerify && !_isSubmitting
                      ? _submitRegistration
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black87,
                          ),
                        )
                      : const Text(
                          'VERIFICAR Y CONTINUAR',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
