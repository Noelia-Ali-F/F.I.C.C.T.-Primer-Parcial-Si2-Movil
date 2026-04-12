import 'package:flutter/material.dart';

class VehicleEditArgs {
  const VehicleEditArgs({
    required this.title,
    required this.subtitle,
    required this.isPrimary,
  });

  final String title;
  final String subtitle;
  final bool isPrimary;
}

class VehicleEditResult {
  const VehicleEditResult({
    required this.summary,
    required this.isPrimary,
  });

  final String summary;
  final bool isPrimary;
}

class VehicleEditScreen extends StatefulWidget {
  const VehicleEditScreen({
    super.key,
    required this.args,
  });

  final VehicleEditArgs args;

  @override
  State<VehicleEditScreen> createState() => _VehicleEditScreenState();
}

class _VehicleEditScreenState extends State<VehicleEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _yearController;
  late final TextEditingController _plateController;

  final List<Color> _availableColors = const [
    Color(0xFFF3F4F6),
    Color(0xFF6C98D1),
    Color(0xFF8D99AE),
  ];

  int _selectedColorIndex = 1;
  late bool _isPrimaryVehicle = widget.args.isPrimary;

  @override
  void initState() {
    super.initState();
    final titleParts = widget.args.title.split(' ');
    final subtitleParts = widget.args.subtitle.split('·');

    _brandController = TextEditingController(
      text: titleParts.isNotEmpty ? titleParts.first : 'Marca',
    );
    _modelController = TextEditingController(
      text: titleParts.length > 1 ? titleParts.sublist(1).join(' ') : widget.args.title,
    );
    _yearController = TextEditingController(
      text: subtitleParts.isNotEmpty
          ? subtitleParts.first.replaceAll(RegExp(r'[^0-9]'), '')
          : '2016',
    );
    _plateController = TextEditingController(
      text: subtitleParts.length > 1
          ? subtitleParts.last.replaceAll('Principal', '').trim()
          : widget.args.subtitle,
    );
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value, String label) {
    if ((value ?? '').trim().isEmpty) {
      return 'Ingresa $label.';
    }
    return null;
  }

  String? _validateYear(String? value) {
    final year = int.tryParse((value ?? '').trim());
    if (year == null) {
      return 'Ingresa un año válido.';
    }
    if (year < 1950 || year > 2100) {
      return 'Ingresa un año entre 1950 y 2100.';
    }
    return null;
  }

  void _save() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    Navigator.of(context).pop(
      VehicleEditResult(
        summary:
            '${_brandController.text.trim()} ${_modelController.text.trim()} · ${_yearController.text.trim()} · ${_plateController.text.trim()}',
        isPrimary: _isPrimaryVehicle,
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
                        'Editar Vehículo',
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
                  'Actualiza la información del vehículo con los colores del proyecto.',
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
                  _EditLineField(
                    label: 'Marca',
                    controller: _brandController,
                    validator: (value) => _validateRequired(value, 'la marca'),
                    suffixIcon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF66758C),
                    ),
                  ),
                  _EditLineField(
                    label: 'Modelo',
                    controller: _modelController,
                    validator: (value) => _validateRequired(value, 'el modelo'),
                  ),
                  _EditLineField(
                    label: 'Año',
                    controller: _yearController,
                    keyboardType: TextInputType.number,
                    validator: _validateYear,
                  ),
                  _EditLineField(
                    label: 'Matrícula',
                    controller: _plateController,
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
                            width: 36,
                            height: 36,
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
                                    Icons.radio_button_checked_rounded,
                                    size: 18,
                                    color: Colors.white,
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
                                ? Icons.check_box_rounded
                                : Icons.check_box_outline_blank_rounded,
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
                          onPressed: _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFD8AD20),
                            foregroundColor: const Color(0xFF123F78),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
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

class _EditLineField extends StatelessWidget {
  const _EditLineField({
    required this.label,
    required this.controller,
    required this.validator,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.suffixIcon,
  });

  final String label;
  final TextEditingController controller;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final Widget? suffixIcon;

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
                border: InputBorder.none,
                errorStyle: const TextStyle(height: 0.8),
                suffixIcon: suffixIcon,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
