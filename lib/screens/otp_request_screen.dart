import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_routes.dart';
import '../models/auth_models.dart';
import 'otp_verification_screen.dart';

class OtpRequestArgs {
  const OtpRequestArgs({
    this.email,
    this.accountType = UserRole.client,
  });

  final String? email;
  final UserRole accountType;
}

class OtpRequestScreen extends StatefulWidget {
  const OtpRequestScreen({
    super.key,
    this.args,
  });

  final OtpRequestArgs? args;

  @override
  State<OtpRequestScreen> createState() => _OtpRequestScreenState();
}

class _OtpRequestScreenState extends State<OtpRequestScreen> {
  static const String _countryPrefix = '+591';

  final TextEditingController _phoneController = TextEditingController();

  String get _normalizedPhoneNumber =>
      '$_countryPrefix ${_phoneController.text}';

  bool get _canContinue => _phoneController.text.trim().length == 8;

  void _handlePhoneChanged(String value) {
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    final normalizedDigits =
        digitsOnly.startsWith('591') ? digitsOnly.substring(3) : digitsOnly;
    final limitedDigits = normalizedDigits.length > 8
        ? normalizedDigits.substring(0, 8)
        : normalizedDigits;

    if (limitedDigits != value) {
      _phoneController.value = TextEditingValue(
        text: limitedDigits,
        selection: TextSelection.collapsed(offset: limitedDigits.length),
      );
    }

    setState(() {});
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6C40E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              const SizedBox(height: 8),
              _OtpTopBar(onBack: () => Navigator.of(context).pop()),
              const Spacer(),
              const Text(
                'Verificación OTP',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 26),
              const Text(
                'Te enviaremos una contraseña de un solo uso\nal siguiente número de celular',
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
              ),
              const SizedBox(height: 70),
              const Text(
                'Ingresa tu número de celular',
                style: TextStyle(fontSize: 12, color: Color(0xA6000000)),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x12000000),
                            blurRadius: 14,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Text(
                            _countryPrefix,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                              color: Colors.black,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            color: const Color(0x26000000),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              textAlign: TextAlign.left,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(8),
                              ],
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                                color: Colors.black,
                              ),
                              decoration: const InputDecoration(
                                hintText: '71234567',
                                hintStyle: TextStyle(
                                  color: Color(0x66000000),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.1,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                counterText: '',
                              ),
                              onChanged: _handlePhoneChanged,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _canContinue
                          ? 'Se enviará el código a $_normalizedPhoneNumber'
                          : 'Número fijo Bolivia: +591 seguido de 8 dígitos',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: Color(0xB3000000),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: 180,
                child: FilledButton(
                  onPressed: _canContinue
                      ? () => Navigator.of(context).pushNamed(
                            AppRoutes.otpVerification,
                            arguments: OtpVerificationArgs(
                              phoneNumber: _normalizedPhoneNumber,
                              email: widget.args?.email,
                              accountType:
                                  widget.args?.accountType ?? UserRole.client,
                            ),
                          )
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    disabledBackgroundColor: const Color(0x66FFFFFF),
                    disabledForegroundColor: const Color(0x66000000),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'OBTENER OTP',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpTopBar extends StatelessWidget {
  const _OtpTopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
        ),
        const Spacer(),
      ],
    );
  }
}
