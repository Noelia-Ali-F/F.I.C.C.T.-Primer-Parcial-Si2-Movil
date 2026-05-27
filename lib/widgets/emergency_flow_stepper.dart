import 'package:flutter/material.dart';

class EmergencyFlowStepper extends StatelessWidget {
  const EmergencyFlowStepper({
    super.key,
    required this.currentStep,
    this.helperText,
  });

  final int currentStep;
  final String? helperText;

  static const List<String> _steps = [
    'Vehiculo',
    'Problema',
    'Evidencia',
    'Ubicacion',
    'Confirmar',
    'Registrada',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7ECF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120B285A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_steps.length, (index) {
                final completed = index < currentStep;
                final active = index == currentStep;
                final circleColor = completed || active
                    ? const Color(0xFF6C63FF)
                    : const Color(0xFFE9EDF5);
                final textColor = active
                    ? const Color(0xFF4E46D4)
                    : completed
                    ? const Color(0xFF123F78)
                    : const Color(0xFFB3BDCC);

                return Padding(
                  padding: EdgeInsets.only(
                    right: index == _steps.length - 1 ? 0 : 18,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: circleColor,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: completed || active
                                    ? Colors.white
                                    : const Color(0xFF98A2B3),
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          if (index != _steps.length - 1)
                            Container(
                              width: 28,
                              height: 2,
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              color: index < currentStep
                                  ? const Color(0xFF6C63FF)
                                  : const Color(0xFFE9EDF5),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _steps[index],
                        style: TextStyle(
                          color: textColor,
                          fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          if ((helperText ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              helperText!,
              style: const TextStyle(
                color: Color(0xFF66758C),
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
