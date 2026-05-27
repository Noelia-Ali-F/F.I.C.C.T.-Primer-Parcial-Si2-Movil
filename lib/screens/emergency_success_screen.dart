import 'package:flutter/material.dart';

import '../app_routes.dart';
import '../models/auth_models.dart';
import '../utils/double_back_logout_scope.dart';
import 'client_home_screen.dart';

class EmergencySuccessScreen extends StatelessWidget {
  const EmergencySuccessScreen({
    super.key,
    required this.user,
    this.incidentNumber = 'EMG-2024-000123',
    this.etaLabel = '15 - 20 min',
  });

  final FakeAuthUser user;
  final String incidentNumber;
  final String etaLabel;

  String get _displayIncidentNumber {
    final numericId = int.tryParse(incidentNumber.trim());
    if (numericId == null) {
      return incidentNumber;
    }
    final year = DateTime.now().year;
    return 'EMG-$year-${numericId.toString().padLeft(6, '0')}';
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
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
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
                      Container(
                        width: 88,
                        height: 88,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F7EA),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 54,
                          color: Color(0xFF31A24C),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        '¡Emergencia registrada!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF101828),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Hemos recibido tu solicitud. Un especialista te contactará en breve.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF66758C),
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _SuccessInfoCard(
                        title: 'Número de incidente',
                        value: _displayIncidentNumber,
                        icon: Icons.confirmation_number_outlined,
                        accentColor: const Color(0xFF123F78),
                      ),
                      const SizedBox(height: 14),
                      _SuccessInfoCard(
                        title: 'Tiempo estimado',
                        value: etaLabel,
                        icon: Icons.timer_outlined,
                        accentColor: const Color(0xFFD8AD20),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => ClientHomeScreen(user: user),
                              ),
                              (route) => false,
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF123F78),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Ver Detalles',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => ClientHomeScreen(
                                  user: user,
                                  initialTabIndex: 2,
                                ),
                              ),
                              (route) => false,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF123F78),
                            side: const BorderSide(color: Color(0xFFDCE5F0)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.notifications_active_rounded),
                          label: const Text(
                            'Ver Alertas',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            AppRoutes.login,
                            (route) => false,
                          );
                        },
                        child: const Text(
                          'Volver al inicio',
                          style: TextStyle(
                            color: Color(0xFF123F78),
                            fontWeight: FontWeight.w800,
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
      ),
    );
  }
}

class _SuccessInfoCard extends StatelessWidget {
  const _SuccessInfoCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7ECF3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accentColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF66758C),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF101828),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
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
