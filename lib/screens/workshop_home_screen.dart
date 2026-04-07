import 'package:flutter/material.dart';

import '../models/auth_models.dart';
import '../utils/logout_dialog.dart';

class WorkshopHomeScreen extends StatelessWidget {
  const WorkshopHomeScreen({super.key, required this.user});

  final FakeAuthUser user;

  @override
  Widget build(BuildContext context) {
    const requests = [
      ('Batería', 'Alta prioridad', '2.3 km'),
      ('Grua', 'Urgencia media', '4.1 km'),
      ('Combustible', 'Asignación directa', '6.0 km'),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Taller (A2)'),
        actions: [
          IconButton(
            onPressed: () => showLogoutDialog(context),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenido, ${user.displayName}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF123F78),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Administra las solicitudes disponibles y responde rápidamente a emergencias asignadas.',
                style: TextStyle(
                  color: Color(0xFF55637C),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              Container(
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
                    const Text(
                      'SOLICITUDES DISPONIBLES',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2F3647),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...requests.map(
                      (request) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _WorkshopRequestCard(
                          title: request.$1,
                          detail: request.$2,
                          distance: request.$3,
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: [
          NavigationDestination(icon: Icon(Icons.list_alt_rounded), label: 'Solicitudes'),
          NavigationDestination(icon: Icon(Icons.map_rounded), label: 'Cobertura'),
          NavigationDestination(icon: Icon(Icons.build_rounded), label: 'Servicios'),
          NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Perfil'),
        ],
      ),
    );
  }
}

class _WorkshopRequestCard extends StatelessWidget {
  const _WorkshopRequestCard({
    required this.title,
    required this.detail,
    required this.distance,
  });

  final String title;
  final String detail;
  final String distance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8E0EA)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0x14D8AD20),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.miscellaneous_services_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF123F78),
                      ),
                    ),
                    Text(detail, style: const TextStyle(color: Color(0xFF66758C))),
                  ],
                ),
              ),
              Text(
                distance,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF66758C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('Rechazar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {},
                  child: const Text('Aceptar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
