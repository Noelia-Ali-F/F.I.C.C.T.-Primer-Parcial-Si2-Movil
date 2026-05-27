import 'package:flutter/material.dart';

import '../app_routes.dart';

class RegistrationSelectionScreen extends StatelessWidget {
  const RegistrationSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3C83F),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF0B92A),
              Color(0xFFF6D34F),
              Color(0xFFFFE58A),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned(
                top: -40,
                right: -10,
                child: _RegistrationBackdropCircle(
                  size: 180,
                  color: Color(0x26FFFFFF),
                ),
              ),
              const Positioned(
                top: 120,
                left: -24,
                child: _RegistrationBackdropCircle(
                  size: 120,
                  color: Color(0x1FFFFFFF),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0x26FFFFFF),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Color(0xFF123F78),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Registro',
                            style: TextStyle(
                              color: Color(0xFF123F78),
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const _RegistrationHeroPanel(),
                    const SizedBox(height: 22),
                    Expanded(
                      child: _RegistrationOptionCard(
                        title: 'Crear cuenta de cliente',
                        icon: Icons.person_add_alt_1_rounded,
                        illustration: const _ClientRegistrationArt(),
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.clientRegistrationForm,
                          );
                        },
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
}

class _RegistrationBackdropCircle extends StatelessWidget {
  const _RegistrationBackdropCircle({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _RegistrationHeroPanel extends StatelessWidget {
  const _RegistrationHeroPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF123F78),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220B285A),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0x1FFFFFFF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.assignment_ind_rounded,
              color: Color(0xFFFFD86B),
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Registro de cliente',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Completa tus datos una sola vez para poder solicitar asistencia vehicular desde la app.',
                  style: TextStyle(
                    color: Color(0xE8FFFFFF),
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RegistrationOptionCard extends StatelessWidget {
  const _RegistrationOptionCard({
    required this.title,
    required this.icon,
    required this.illustration,
    required this.onPressed,
  });

  final String title;
  final IconData icon;
  final Widget illustration;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF2),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFF1D57B)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x160B285A),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0BF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Acceso cliente',
              style: TextStyle(
                color: Color(0xFF123F78),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 14),
          illustration,
          const SizedBox(height: 20),
          const Text(
            'Activa tu perfil para registrar vehículos, reportar incidentes y consultar tu historial de emergencias.',
            style: TextStyle(
              color: Color(0xFF55637C),
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 20),
              label: Text(title),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF123F78),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientRegistrationArt extends StatelessWidget {
  const _ClientRegistrationArt();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 210,
            height: 128,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF5F7FB), Color(0xFFE5ECF7)],
              ),
              borderRadius: BorderRadius.circular(32),
            ),
          ),
          Positioned(
            top: 18,
            right: 46,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFFF77A8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_add_alt_1_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          Positioned(
            left: 34,
            top: 26,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF123F78),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
          ),
          const Positioned(
            bottom: 18,
            right: 40,
            child: Icon(
              Icons.directions_car_filled_rounded,
              size: 76,
              color: Color(0xFFEB9E22),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 72,
            child: Container(
              width: 62,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 54,
            right: 30,
            child: Container(
              width: 58,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFFC8D2E2),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const Positioned(
            bottom: 18,
            left: 40,
            child: Icon(
              Icons.verified_user_rounded,
              size: 30,
              color: Color(0xFF2CB56F),
            ),
          ),
        ],
      ),
    );
  }
}
