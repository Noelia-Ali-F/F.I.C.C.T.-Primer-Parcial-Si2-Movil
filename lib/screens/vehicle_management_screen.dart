import 'package:flutter/material.dart';

import 'vehicle_edit_screen.dart';
import 'vehicle_registration_screen.dart';

class VehicleManagementScreen extends StatefulWidget {
  const VehicleManagementScreen({
    super.key,
    required this.initialVehicles,
  });

  final List<String> initialVehicles;

  @override
  State<VehicleManagementScreen> createState() => _VehicleManagementScreenState();
}

class _VehicleManagementScreenState extends State<VehicleManagementScreen> {
  late final List<String> _vehicles = List<String>.from(widget.initialVehicles);

  Future<void> _openVehicleRegistrationScreen() async {
    final result = await Navigator.of(context).push<VehicleRegistrationResult>(
      MaterialPageRoute(
        builder: (_) => const VehicleRegistrationScreen(),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      if (result.isPrimary) {
        _vehicles.insert(0, '${result.summary} · Principal');
      } else {
        _vehicles.add(result.summary);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vehículo agregado correctamente.'),
      ),
    );
  }

  Future<void> _openVehicleEditScreen({
    required int index,
    required String title,
    required String subtitle,
    required bool isPrimary,
  }) async {
    final result = await Navigator.of(context).push<VehicleEditResult>(
      MaterialPageRoute(
        builder: (_) => VehicleEditScreen(
          args: VehicleEditArgs(
            title: title,
            subtitle: subtitle,
            isPrimary: isPrimary,
          ),
        ),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      if (result.isPrimary) {
        for (var i = 0; i < _vehicles.length; i++) {
          _vehicles[i] = _vehicles[i].replaceAll(' · Principal', '');
        }
      }

      _vehicles[index] = result.isPrimary
          ? '${result.summary} · Principal'
          : result.summary;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vehículo actualizado correctamente.'),
      ),
    );
  }

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
                        'MIS VEHÍCULOS',
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
                  'Administra tus vehículos con la identidad visual del proyecto.',
                  style: TextStyle(
                    color: Colors.white,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
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
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF123F78),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gestión de vehículos',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Selecciona un vehículo activo, edítalo o agrega uno nuevo.',
                              style: TextStyle(
                                color: Color(0xE8FFFFFF),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...List.generate(_vehicles.length, (index) {
                        final vehicle = _vehicles[index];
                        final parts = vehicle.split('·');
                        final title = parts.first.trim();
                        final subtitle = parts.length > 1
                            ? parts.sublist(1).join(' · ').trim()
                            : 'Vehículo registrado';
                        final isPrimary = vehicle.contains('Principal') || index == 0;

                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == _vehicles.length - 1 ? 0 : 12,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEE),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFEACB63)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 62,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: const Color(0xFFEACB63),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.directions_car_filled_rounded,
                                        size: 34,
                                        color: Color(0xFF123F78),
                                      ),
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
                                              color: Color(0xFF101828),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            subtitle,
                                            style: const TextStyle(
                                              color: Color(0xFF66758C),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isPrimary)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4D8E50),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: const Text(
                                          'ACTIVO',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      )
                                    else
                                      const Icon(
                                        Icons.check_rounded,
                                        color: Color(0xFF4D8E50),
                                        size: 26,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () {
                                      _openVehicleEditScreen(
                                        index: index,
                                        title: title,
                                        subtitle: subtitle,
                                        isPrimary: isPrimary,
                                      );
                                    },
                                    icon: const Icon(Icons.edit_rounded, size: 18),
                                    label: const Text('Editar'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF123F78),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: _openVehicleRegistrationScreen,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7DB),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFEACB63)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_rounded, color: Color(0xFF123F78)),
                              SizedBox(width: 10),
                              Text(
                                'Agregar Vehículo',
                                style: TextStyle(
                                  color: Color(0xFF123F78),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _openVehicleRegistrationScreen,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFD8AD20),
                            foregroundColor: const Color(0xFF123F78),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text(
                            'Agregar Vehículo',
                            style: TextStyle(fontWeight: FontWeight.w900),
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
      ),
    );
  }
}
