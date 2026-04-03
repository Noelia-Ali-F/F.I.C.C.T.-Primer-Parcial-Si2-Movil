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
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1,
          ),
          headlineSmall: TextStyle(
            fontSize: 24,
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
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
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
              const _StatusRow(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
                  child: Column(
                    children: [
                      const SizedBox(height: 18),
                      const _WorkshopIllustration(),
                      const Spacer(),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('WELCOME', style: theme.textTheme.headlineLarge),
                            const SizedBox(height: 8),
                            const Text(
                              'Tu red de asistencia mecánica inmediata.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              const _BottomAuthSheet(),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
      child: Row(
        children: const [
          Text(
            '10:30 AM',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          Spacer(),
          Icon(Icons.signal_cellular_alt_rounded, color: Colors.white, size: 18),
          SizedBox(width: 6),
          Icon(Icons.wifi_rounded, color: Colors.white, size: 18),
          SizedBox(width: 6),
          Icon(Icons.battery_full_rounded, color: Colors.white, size: 18),
        ],
      ),
    );
  }
}

class _WorkshopIllustration extends StatelessWidget {
  const _WorkshopIllustration();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 34,
            child: Container(
              width: 188,
              height: 112,
              decoration: BoxDecoration(
                color: const Color(0x40FFFFFF),
                borderRadius: BorderRadius.circular(32),
              ),
            ),
          ),
          Positioned(
            top: 76,
            child: Row(
              children: [
                Container(width: 14, height: 132, color: const Color(0x88795E21)),
                const SizedBox(width: 28),
                Container(width: 14, height: 124, color: const Color(0x88795E21)),
              ],
            ),
          ),
          Positioned(
            top: 68,
            child: _MiniCar(
              width: 170,
              bodyColor: const Color(0xFFF5F7FA),
              accentColor: const Color(0xFFB7C2D6),
            ),
          ),
          Positioned(
            bottom: 64,
            child: Container(
              width: 272,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0x33A27700),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Positioned(
            bottom: 82,
            child: _MainCar(),
          ),
          const Positioned(left: 8, bottom: 112, child: _MechanicFigure(direction: -1)),
          const Positioned(left: 88, bottom: 46, child: _MechanicFigure(kneeling: true)),
          const Positioned(right: 88, bottom: 52, child: _MechanicFigure(kneeling: true, direction: -1)),
          const Positioned(right: 10, bottom: 112, child: _MechanicFigure()),
          const Positioned(right: 76, top: 126, child: _MechanicFigure(scale: 0.72)),
        ],
      ),
    );
  }
}

class _BottomAuthSheet extends StatelessWidget {
  const _BottomAuthSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Accede a tu cuenta',
            style: TextStyle(
              color: Color(0xFF4E5FB2),
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: 180,
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DashboardScreen()),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF171717),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('INICIAR SESION'),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: 180,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF171717),
                side: const BorderSide(color: Color(0xFFD6D6D6)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('REGISTRATE'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCar extends StatelessWidget {
  const _MiniCar({
    required this.width,
    required this.bodyColor,
    required this.accentColor,
  });

  final double width;
  final Color bodyColor;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final wheel = width * 0.15;

    return SizedBox(
      width: width,
      height: width * 0.55,
      child: Stack(
        children: [
          Positioned(
            left: width * 0.16,
            top: width * 0.04,
            child: Container(
              width: width * 0.46,
              height: width * 0.17,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(width * 0.08),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: wheel * 0.75,
            child: Container(
              height: width * 0.22,
              decoration: BoxDecoration(
                color: bodyColor,
                borderRadius: BorderRadius.circular(width * 0.12),
              ),
            ),
          ),
          Positioned(
            left: width * 0.22,
            bottom: wheel * 1.2,
            child: Container(
              width: width * 0.2,
              height: width * 0.12,
              decoration: BoxDecoration(
                color: const Color(0x66B0BCD0),
                borderRadius: BorderRadius.circular(width * 0.03),
              ),
            ),
          ),
          Positioned(
            right: width * 0.17,
            bottom: wheel * 1.2,
            child: Container(
              width: width * 0.18,
              height: width * 0.12,
              decoration: BoxDecoration(
                color: const Color(0x66B0BCD0),
                borderRadius: BorderRadius.circular(width * 0.03),
              ),
            ),
          ),
          Positioned(left: width * 0.16, bottom: 0, child: _Wheel(size: wheel)),
          Positioned(right: width * 0.16, bottom: 0, child: _Wheel(size: wheel)),
        ],
      ),
    );
  }
}

class _MainCar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 286,
      height: 168,
      child: Stack(
        children: [
          Positioned(
            left: 42,
            top: 8,
            child: Container(
              width: 144,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFB4C4D9),
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 34,
            child: Container(
              height: 74,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFDDE6F1), Color(0xFFA7B8CF)],
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x260B285A),
                    blurRadius: 18,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 56,
            bottom: 86,
            child: Container(
              width: 70,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF3F8),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            right: 56,
            bottom: 86,
            child: Container(
              width: 70,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF3F8),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const Positioned(left: 50, bottom: 16, child: _Wheel(size: 48)),
          const Positioned(right: 50, bottom: 16, child: _Wheel(size: 48)),
          Positioned(
            left: 12,
            bottom: 74,
            child: Container(
              width: 14,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFFD84934),
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 74,
            child: Container(
              width: 14,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFFF2A43A),
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Wheel extends StatelessWidget {
  const _Wheel({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF2E3A4A),
      ),
      child: Center(
        child: Container(
          width: size * 0.42,
          height: size * 0.42,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFD5DCE6),
          ),
        ),
      ),
    );
  }
}

class _MechanicFigure extends StatelessWidget {
  const _MechanicFigure({
    this.direction = 1,
    this.kneeling = false,
    this.scale = 1,
  });

  final int direction;
  final bool kneeling;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..scale(direction * scale, scale),
      child: SizedBox(
        width: 46,
        height: kneeling ? 70 : 92,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              top: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3C7A3),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: 12,
              child: Container(
                width: 20,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Positioned(
              top: 18,
              left: 6,
              child: Transform.rotate(
                angle: -0.5,
                child: Container(
                  width: 22,
                  height: 5,
                  decoration: BorderRadiusBox.blue,
                ),
              ),
            ),
            Positioned(
              top: 44,
              left: kneeling ? 18 : 12,
              child: Container(
                width: 8,
                height: kneeling ? 20 : 32,
                decoration: BorderRadiusBox.navy,
              ),
            ),
            Positioned(
              top: 44,
              right: kneeling ? 10 : 12,
              child: Transform.rotate(
                angle: kneeling ? 1.0 : 0.18,
                child: Container(
                  width: kneeling ? 24 : 8,
                  height: kneeling ? 8 : 32,
                  decoration: BorderRadiusBox.navy,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BorderRadiusBox {
  static BoxDecoration get blue => BoxDecoration(
        color: const Color(0xFF4C94F3),
        borderRadius: BorderRadius.circular(8),
      );

  static BoxDecoration get navy => BoxDecoration(
        color: const Color(0xFF123F78),
        borderRadius: BorderRadius.circular(8),
      );
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
