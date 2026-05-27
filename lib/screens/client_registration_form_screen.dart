import 'package:flutter/material.dart';

import '../app_routes.dart';
import '../services/client_registration_service.dart';
import '../services/push_device_registration_service.dart';

class ClientRegistrationData {
  const ClientRegistrationData({
    required this.identityCard,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
  });

  final String identityCard;
  final String fullName;
  final String email;
  final String phone;
  final String password;
}

class ClientRegistrationFormScreen extends StatefulWidget {
  const ClientRegistrationFormScreen({super.key});

  @override
  State<ClientRegistrationFormScreen> createState() =>
      _ClientRegistrationFormScreenState();
}

class _ClientRegistrationFormScreenState
    extends State<ClientRegistrationFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _identityCardController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _acceptTerms = false;
  bool _isSubmitting = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _identityCardController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debes aceptar los términos y condiciones para continuar.',
          ),
        ),
      );
      return;
    }

    if (_isSubmitting) {
      return;
    }

    final data = ClientRegistrationData(
      identityCard: _identityCardController.text.trim(),
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
    );

    setState(() => _isSubmitting = true);

    final result = await ClientRegistrationService.registerClient(data);

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);

    if (!result.isSuccess) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Registro no enviado'),
          content: Text(
            result.statusCode == 0
                ? result.message
                : 'Backend: ${result.statusCode}\n${result.message}',
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

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Registro confirmado'),
        content: Text(
          result.clientId == null
              ? 'Backend: ${result.statusCode}\nEl cliente fue creado correctamente.'
              : 'Backend: ${result.statusCode}\nCliente creado con ID ${result.clientId}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    if (!mounted) {
      return;
    }

    if (result.clientId != null) {
      await PushDeviceRegistrationService.updateCurrentClientUserId(
        result.clientId,
      );
    }

    Navigator.of(context).pushNamed(
      AppRoutes.clientRegistrationSuccess,
      arguments: data,
    );
  }

  String? _validateName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Ingresa tu nombre completo.';
    }
    if (text.length < 6) {
      return 'El nombre debe tener al menos 6 caracteres.';
    }
    return null;
  }

  String? _validateIdentityCard(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return 'Ingresa tu carnet de identidad.';
    }
    if (digits.length < 6) {
      return 'El carnet debe tener al menos 6 dígitos.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (text.isEmpty) {
      return 'Ingresa tu correo electrónico.';
    }
    if (!emailRegex.hasMatch(text)) {
      return 'Ingresa un correo válido.';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return 'Ingresa tu número de celular.';
    }
    if (digits.length < 8) {
      return 'El teléfono debe tener al menos 8 dígitos.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) {
      return 'Ingresa una contraseña.';
    }
    if (text.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres.';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if ((value ?? '').isEmpty) {
      return 'Confirma tu contraseña.';
    }
    if (value != _passwordController.text) {
      return 'Las contraseñas no coinciden.';
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
                        'Registro de Cliente',
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
                  'Completa tus datos para crear una cuenta con la identidad visual del proyecto.',
                  style: TextStyle(
                    color: Colors.white,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
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
                                'Datos del cliente',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Ingresa tus datos personales para crear tu cuenta.',
                                style: TextStyle(
                                  color: Color(0xE8FFFFFF),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _RegistrationField(
                          label: 'Carnet de identidad',
                          hintText: 'Ej: 12345678',
                          controller: _identityCardController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          validator: _validateIdentityCard,
                        ),
                        const SizedBox(height: 16),
                        _RegistrationField(
                          label: 'Nombre completo',
                          hintText: 'Ej: Juan Pérez Gómez',
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          validator: _validateName,
                        ),
                        const SizedBox(height: 16),
                        _RegistrationField(
                          label: 'Correo electrónico',
                          hintText: 'ejemplo@correo.com',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 16),
                        _RegistrationField(
                          label: 'Teléfono / Celular',
                          hintText: 'Ej: 71234567',
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          validator: _validatePhone,
                          suffixIcon: const Icon(
                            Icons.phone_rounded,
                            color: Color(0xFF123F78),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _RegistrationField(
                          label: 'Contraseña',
                          hintText: '••••••••',
                          controller: _passwordController,
                          obscureText: !_showPassword,
                          textInputAction: TextInputAction.next,
                          validator: _validatePassword,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() => _showPassword = !_showPassword);
                            },
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: const Color(0xFF123F78),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _RegistrationField(
                          label: 'Confirmar contraseña',
                          hintText: '••••••••',
                          controller: _confirmPasswordController,
                          obscureText: !_showConfirmPassword,
                          textInputAction: TextInputAction.done,
                          validator: _validateConfirmPassword,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(
                                () => _showConfirmPassword = !_showConfirmPassword,
                              );
                            },
                            icon: Icon(
                              _showConfirmPassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: const Color(0xFF123F78),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7DB),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFEACB63)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: _acceptTerms,
                                activeColor: const Color(0xFF123F78),
                                checkColor: const Color(0xFFD8AD20),
                                onChanged: (value) {
                                  setState(() => _acceptTerms = value ?? false);
                                },
                              ),
                              const Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(top: 12),
                                  child: Text(
                                    'Acepto los términos y condiciones y la política de privacidad.',
                                    style: TextStyle(
                                      color: Color(0xFF55637C),
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isSubmitting ? null : _submitForm,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFD8AD20),
                              foregroundColor: const Color(0xFF123F78),
                              padding: const EdgeInsets.symmetric(vertical: 16),
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
                                    'Crear cuenta',
                                    style: TextStyle(fontWeight: FontWeight.w900),
                                  ),
                          ),
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

class _RegistrationField extends StatelessWidget {
  const _RegistrationField({
    required this.label,
    required this.hintText,
    required this.controller,
    required this.validator,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.suffixIcon,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final String? Function(String?) validator;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF123F78),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: const Color(0xFFFFFBEE),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEACB63)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEACB63)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF123F78), width: 1.4),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD92D20)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD92D20), width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}
