import 'package:flutter/material.dart';

import '../app_routes.dart';

class OtpRequestScreen extends StatefulWidget {
  const OtpRequestScreen({super.key});

  @override
  State<OtpRequestScreen> createState() => _OtpRequestScreenState();
}

class _OtpRequestScreenState extends State<OtpRequestScreen> {
  final TextEditingController _phoneController = TextEditingController(
    text: '+968 8943050',
  );

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _phoneController.text.trim().isNotEmpty;

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
                'OTP Verification',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 26),
              const Text(
                'We will send you on One Tme Presword\non this mobile number',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
              ),
              const SizedBox(height: 70),
              const Text(
                'Enter Mobile Number',
                style: TextStyle(fontSize: 12, color: Color(0xA6000000)),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 190),
                child: TextField(
                  controller: _phoneController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: Colors.black,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.only(bottom: 8),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xB3000000), width: 1.5),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xB3000000), width: 1.5),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black, width: 1.8),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: 180,
                child: FilledButton(
                  onPressed: canContinue
                      ? () => Navigator.of(context).pushNamed(
                            AppRoutes.otpVerification,
                            arguments: _phoneController.text.trim(),
                          )
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'GET OTP',
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
        ),
        const Spacer(),
      ],
    );
  }
}
