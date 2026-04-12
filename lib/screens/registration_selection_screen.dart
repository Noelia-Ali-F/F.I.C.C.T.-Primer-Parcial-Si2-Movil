import 'package:flutter/material.dart';

import '../app_routes.dart';

class RegistrationSelectionScreen extends StatelessWidget {
  const RegistrationSelectionScreen({super.key});

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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
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
                        'Registro',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(22, 12, 22, 0),
                child: Text(
                  'Selecciona el tipo de registro con la identidad visual del proyecto.',
                  style: TextStyle(
                    color: Colors.white,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                  child: Column(
                    children: [
                      _RegistrationOptionCard(
                        title: 'Registrar clientes',
                        icon: Icons.person_add_alt_1_rounded,
                        illustration: const _ClientRegistrationArt(),
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.clientRegistrationForm,
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      _RegistrationOptionCard(
                        title: 'Registrar asociados de taller',
                        icon: Icons.garage_rounded,
                        illustration: const _WorkshopRegistrationArt(),
                        onPressed: () {},
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 2,
        indicatorColor: Color(0x1AFF3B30),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_rounded, color: Color(0xFF858585)),
            selectedIcon: Icon(Icons.home_rounded, color: Color(0xFFFF3B30)),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_rounded, color: Color(0xFF858585)),
            selectedIcon: Icon(Icons.settings_rounded, color: Color(0xFFFF3B30)),
            label: 'Repuestos',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_rounded, color: Color(0xFFFF3B30), size: 34),
            selectedIcon: Icon(Icons.add_circle_rounded, color: Color(0xFFFF3B30), size: 34),
            label: 'Registro',
          ),
          NavigationDestination(
            icon: Icon(Icons.handyman_rounded, color: Color(0xFF858585)),
            selectedIcon: Icon(Icons.handyman_rounded, color: Color(0xFFFF3B30)),
            label: 'Taller',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_rounded, color: Color(0xFF858585)),
            selectedIcon: Icon(Icons.chat_bubble_rounded, color: Color(0xFFFF3B30)),
            label: 'Chats',
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
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEACB63)),
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
          illustration,
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 20),
              label: Text(title),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD8AD20),
                foregroundColor: const Color(0xFF123F78),
                padding: const EdgeInsets.symmetric(vertical: 14),
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
      height: 128,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 126,
            height: 126,
            decoration: const BoxDecoration(
              color: Color(0xFFF2F5FA),
              shape: BoxShape.circle,
            ),
          ),
          Positioned(
            top: 24,
            left: 72,
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0xFFFF77A8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_add_alt_1_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const Positioned(
            bottom: 22,
            child: Icon(Icons.local_shipping_rounded, size: 66, color: Color(0xFFEB9E22)),
          ),
          Positioned(
            bottom: 26,
            left: 70,
            child: Container(
              width: 46,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F2),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Positioned(
            bottom: 38,
            right: 62,
            child: Container(
              width: 54,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFC8D2E2),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const Positioned(
            bottom: 22,
            left: 56,
            child: Icon(Icons.warning_amber_rounded, size: 30, color: Color(0xFFFF6B6B)),
          ),
        ],
      ),
    );
  }
}

class _WorkshopRegistrationArt extends StatelessWidget {
  const _WorkshopRegistrationArt();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 128,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 126,
            height: 126,
            decoration: const BoxDecoration(
              color: Color(0xFFF2F5FA),
              shape: BoxShape.circle,
            ),
          ),
          Positioned(
            bottom: 22,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_rounded, size: 34, color: Color(0xFF2E3138)),
                const SizedBox(width: 14),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.car_repair_rounded, size: 76, color: Color(0xFFF0B92A)),
                    Positioned(
                      bottom: 6,
                      right: -2,
                      child: Container(
                        width: 38,
                        height: 22,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2CB56F),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Positioned(
            top: 18,
            right: 70,
            child: Icon(Icons.handyman_rounded, size: 26, color: Color(0xFF123F78)),
          ),
        ],
      ),
    );
  }
}
