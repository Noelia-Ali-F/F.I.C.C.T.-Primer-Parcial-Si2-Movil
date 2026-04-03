import 'package:flutter/material.dart';

void main() {
  runApp(const TallerAcbApp());
}

class TallerAcbApp extends StatelessWidget {
  const TallerAcbApp({super.key});

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF123F78);
    const gold = Color(0xFFD8AD20);
    const canvas = Color(0xFFF4F7FB);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Taller ACB Asistencia',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: canvas,
        colorScheme: ColorScheme.fromSeed(
          seedColor: navy,
          primary: navy,
          secondary: gold,
          surface: Colors.white,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: navy,
            height: 1.05,
          ),
          headlineSmall: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: navy,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: navy,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Color(0xFF55637C),
          ),
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(theme: theme),
                    const SizedBox(height: 20),
                    _HeroCard(theme: theme),
                    const SizedBox(height: 20),
                    Text('Resumen general', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 12),
                    const _StatsGrid(),
                    const SizedBox(height: 22),
                    Text('Acciones rápidas', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 12),
                    const _QuickActions(),
                    const SizedBox(height: 22),
                    Text('Solicitudes recientes', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.list(
                children: const [
                  _RequestCard(
                    title: 'Cambio de batería',
                    location: 'Equipetrol, Santa Cruz',
                    status: 'Urgente',
                    eta: '12 min',
                  ),
                  SizedBox(height: 12),
                  _RequestCard(
                    title: 'Remolque urbano',
                    location: 'Av. Banzer, Santa Cruz',
                    status: 'En proceso',
                    eta: '25 min',
                  ),
                  SizedBox(height: 12),
                  _RequestCard(
                    title: 'Falta de combustible',
                    location: 'Zona Sur',
                    status: 'Asignado',
                    eta: '18 min',
                  ),
                  SizedBox(height: 22),
                  _SectionTitle(title: 'Talleres disponibles'),
                  SizedBox(height: 12),
                  _WorkshopCard(
                    name: 'Taller El Rápido',
                    specialty: 'Mecánica general y electricidad',
                    coverage: 'Centro y Equipetrol',
                  ),
                  SizedBox(height: 12),
                  _WorkshopCard(
                    name: 'Gruas del Oriente',
                    specialty: 'Remolque y auxilio móvil',
                    coverage: 'Ciudad y carretera',
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.build_circle_outlined), label: 'Servicios'),
          NavigationDestination(icon: Icon(Icons.groups_rounded), label: 'Talleres'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), label: 'Perfil'),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color(0xFFF4CF46), Color(0xFFD8AD20)],
            ),
          ),
          child: const Icon(Icons.car_repair_rounded, color: Color(0xFF123F78), size: 30),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Taller ACB Asistencia', style: theme.textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(
                'Dashboard operativo de auxilio y talleres',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120B285A),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.notifications_none_rounded, color: Color(0xFF123F78)),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F4B94), Color(0xFF123F78)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x260B285A),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              color: const Color(0x24FFFFFF),
            ),
            child: const Text(
              'Panel principal',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Controla solicitudes, talleres socios y servicios urgentes desde una sola vista.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Monitorea atención inmediata, cobertura y disponibilidad operativa en tiempo real.',
            style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xE8FFFFFF)),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFD8AD20),
                    foregroundColor: const Color(0xFF123F78),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.add_road_rounded),
                  label: const Text('Nueva solicitud'),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0x7AFFFFFF)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                ),
                child: const Text('Ver mapa'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      childAspectRatio: 1.2,
      children: const [
        _StatCard(value: '18', label: 'Solicitudes hoy', detail: 'Auxilios registrados'),
        _StatCard(value: '32', label: 'Talleres activos', detail: 'Disponibles en la red'),
        _StatCard(value: '07', label: 'Urgencias', detail: 'Con prioridad alta'),
        _StatCard(value: '05', label: 'Zonas', detail: 'Cobertura operativa'),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.detail,
  });

  final String value;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF123F78),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF123F78),
            ),
          ),
          const Spacer(),
          Text(
            detail,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF66758C),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.local_shipping_outlined, 'Remolque'),
      (Icons.battery_5_bar_rounded, 'Batería'),
      (Icons.local_gas_station_rounded, 'Combustible'),
      (Icons.tire_repair_rounded, 'Neumático'),
    ];

    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
            width: 104,
            padding: const EdgeInsets.all(14),
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
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: const Color(0x14D8AD20),
                  ),
                  child: Icon(item.$1, color: const Color(0xFF123F78)),
                ),
                const Spacer(),
                Text(
                  item.$2,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF123F78),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.title,
    required this.location,
    required this.status,
    required this.eta,
  });

  final String title;
  final String location;
  final String status;
  final String eta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0x14D8AD20),
            ),
            child: const Icon(Icons.car_crash_outlined, color: Color(0xFF123F78)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF123F78),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  location,
                  style: const TextStyle(color: Color(0xFF66758C)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  color: const Color(0x14D8AD20),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: Color(0xFF123F78),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                eta,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF123F78),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkshopCard extends StatelessWidget {
  const _WorkshopCard({
    required this.name,
    required this.specialty,
    required this.coverage,
  });

  final String name;
  final String specialty;
  final String coverage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF123F78),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0x140B8E43),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text(
                  'Disponible',
                  style: TextStyle(
                    color: Color(0xFF0B8E43),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            specialty,
            style: const TextStyle(color: Color(0xFF55637C)),
          ),
          const SizedBox(height: 8),
          Text(
            coverage,
            style: const TextStyle(
              color: Color(0xFF123F78),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }
}
