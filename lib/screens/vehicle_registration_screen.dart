import 'package:flutter/material.dart';

import '../models/vehicle_models.dart';
import '../services/vehicle_service.dart';

class VehicleRegistrationResult {
  const VehicleRegistrationResult({
    required this.summary,
    required this.isPrimary,
  });

  final String summary;
  final bool isPrimary;
}

class VehicleRegistrationScreen extends StatefulWidget {
  const VehicleRegistrationScreen({
    super.key,
    required this.clientId,
  });

  final int? clientId;

  @override
  State<VehicleRegistrationScreen> createState() =>
      _VehicleRegistrationScreenState();
}

class _VehicleRegistrationScreenState extends State<VehicleRegistrationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _modelController = TextEditingController(
    text: '2018',
  );
  final TextEditingController _yearController = TextEditingController(
    text: '2018',
  );
  final TextEditingController _plateController = TextEditingController(
    text: '1023HHNNI',
  );

  final List<Color> _availableColors = const [
    Color(0xFFF3F4F6),
    Color(0xFF9CA3AF),
    Color(0xFFD6B256),
    Color(0xFF1F2937),
  ];

  int _selectedColorIndex = 0;
  bool _isPrimaryVehicle = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _saveVehicle() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _isSubmitting) {
      return;
    }

    final clientId = widget.clientId;
    if (clientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se encontró el identificador del cliente autenticado.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final colorLabels = ['blanco', 'gris', 'dorado', 'negro'];
    final vehicleData = VehicleRegistrationData(
      clientId: clientId,
      brand: _brandController.text.trim(),
      model: _modelController.text.trim(),
      year: int.parse(_yearController.text.trim()),
      plate: _plateController.text.trim().toUpperCase(),
      color: colorLabels[_selectedColorIndex],
      isPrimary: _isPrimaryVehicle,
    );

    final response = await VehicleService.registerVehicle(vehicleData);

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);

    if (!response.isSuccess) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Registro no enviado'),
          content: Text(
            response.statusCode == 0
                ? response.message
                : 'Backend: ${response.statusCode}\n${response.message}',
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

    final result = VehicleRegistrationResult(
      summary:
          '${vehicleData.brand} ${vehicleData.model} ${vehicleData.year} · ${vehicleData.plate}',
      isPrimary: _isPrimaryVehicle,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          response.vehicleId == null
              ? response.message
              : '${response.message} ID ${response.vehicleId}.',
        ),
      ),
    );

    Navigator.of(context).pop(result);
  }

  String? _validateRequired(String? value, String fieldName) {
    if ((value ?? '').trim().isEmpty) {
      return 'Ingresa $fieldName.';
    }
    return null;
  }

  String? _validateYear(String? value) {
    final text = (value ?? '').trim();
    final year = int.tryParse(text);
    if (year == null) {
      return 'Ingresa un año válido.';
    }
    if (year < 1950 || year > 2100) {
      return 'Ingresa un año entre 1950 y 2100.';
    }
    return null;
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
                        'Registrar Vehículo',
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
                  'Completa los datos del vehículo con la misma paleta del proyecto.',
                  style: TextStyle(
                    color: Colors.white,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
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
                  child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _VehicleLineField(
                    label: 'Marca',
                    controller: _brandController,
                    hintText: 'Ej: Toyota',
                    validator: (value) => _validateRequired(value, 'la marca'),
                  ),
                  _VehicleLineField(
                    label: 'Modelo',
                    controller: _modelController,
                    hintText: 'Ej: Corolla',
                    validator: (value) => _validateRequired(value, 'el modelo'),
                  ),
                  _VehicleLineField(
                    label: 'Año',
                    controller: _yearController,
                    hintText: 'Ej: 2018',
                    keyboardType: TextInputType.number,
                    validator: _validateYear,
                  ),
                  _VehicleLineField(
                    label: 'Matrícula',
                    controller: _plateController,
                    hintText: 'Ej: 1023HHNNI',
                    textCapitalization: TextCapitalization.characters,
                    validator: (value) => _validateRequired(value, 'la matrícula'),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Color',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF101828),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: List.generate(_availableColors.length, (index) {
                      final isSelected = index == _selectedColorIndex;
                      return Padding(
                        padding: EdgeInsets.only(
                          right: index == _availableColors.length - 1 ? 0 : 10,
                        ),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedColorIndex = index);
                          },
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: _availableColors[index],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF2E6BB2)
                                    : const Color(0xFFD0D5DD),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 18,
                                    color: Color(0xFF2E6BB2),
                                  )
                                : null,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 18),
                  InkWell(
                    onTap: () {
                      setState(() => _isPrimaryVehicle = !_isPrimaryVehicle);
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Icon(
                            _isPrimaryVehicle
                                ? Icons.check_circle_outline_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: const Color(0xFF66758C),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Seleccionar como vehículo principal',
                              style: TextStyle(
                                color: Color(0xFF55637C),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF66758C),
                            side: const BorderSide(color: Color(0xFFD0D5DD)),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: FilledButton(
                          onPressed: _saveVehicle,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFD8AD20),
                            foregroundColor: const Color(0xFF123F78),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF123F78),
                                  ),
                                )
                              : const Text(
                                  'Guardar',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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

class _VehicleLineField extends StatelessWidget {
  const _VehicleLineField({
    required this.label,
    required this.controller,
    required this.validator,
    this.hintText,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController controller;
  final String? Function(String?) validator;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFEACB63)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF101828),
              ),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              validator: validator,
              keyboardType: keyboardType,
              textCapitalization: textCapitalization,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF344054),
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: hintText,
                hintStyle: const TextStyle(
                  color: Color(0xFF98A2B3),
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                errorStyle: const TextStyle(height: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
