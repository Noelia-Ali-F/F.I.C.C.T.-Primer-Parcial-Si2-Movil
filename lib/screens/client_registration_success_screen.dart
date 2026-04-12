import 'package:flutter/material.dart';

import '../app_routes.dart';
import 'client_registration_form_screen.dart';

class ClientRegistrationSuccessScreen extends StatelessWidget {
  const ClientRegistrationSuccessScreen({
    super.key,
    required this.data,
  });

  final ClientRegistrationData data;

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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 34, 24, 24),
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
                      width: 96,
                      height: 96,
                      decoration: const BoxDecoration(
                        color: Color(0x14123F78),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 56,
                        color: Color(0xFF123F78),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '¡Cuenta creada!\nexitosamente',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF101828),
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'La cuenta de ${data.fullName} fue registrada correctamente.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF55637C),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Ahora puedes solicitar asistencia vehicular.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF55637C),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            AppRoutes.login,
                            (route) => false,
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFD8AD20),
                          foregroundColor: const Color(0xFF123F78),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Continuar',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
