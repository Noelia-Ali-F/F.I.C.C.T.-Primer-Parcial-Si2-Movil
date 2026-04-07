import 'package:flutter/material.dart';

import '../app_routes.dart';

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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    children: [
                      const _StatusRow(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
                        child: Column(
                          children: [
                            const SizedBox(height: 18),
                            const _WorkshopIllustration(),
                            const SizedBox(height: 24),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'BIENVENIDO',
                                    style: theme.textTheme.headlineLarge,
                                  ),
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
                      const SizedBox(height: 16),
                      const _BottomAuthSheet(),
                    ],
                  ),
                ),
              );
            },
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
    return const Padding(
      padding: EdgeInsets.fromLTRB(18, 10, 18, 0),
      child: Row(
        children: [
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
            child: const _MiniCar(
              width: 170,
              bodyColor: Color(0xFFF5F7FA),
              accentColor: Color(0xFFB7C2D6),
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
          const Positioned(bottom: 82, child: _MainCar()),
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
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.login),
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
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.registration),
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
  const _MainCar();

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
      transform: Matrix4.identity()..scale(direction * scale, scale),
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
