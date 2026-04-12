import 'package:flutter/material.dart';

import 'models/auth_models.dart';
import 'screens/client_email_otp_screen.dart';
import 'screens/client_registration_form_screen.dart';
import 'screens/client_registration_success_screen.dart';
import 'screens/client_registration_validation_screen.dart';
import 'screens/client_home_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/emergency_request_screen.dart';
import 'screens/login_screen.dart';
import 'screens/otp_request_screen.dart';
import 'screens/otp_verification_screen.dart';
import 'screens/registration_selection_screen.dart';
import 'screens/workshop_home_screen.dart';

class AppRoutes {
  static const login = '/login';
  static const registration = '/registration';
  static const clientHome = '/client-home';
  static const workshopHome = '/workshop-home';
  static const dashboard = '/dashboard';
  static const emergencyRequest = '/emergency-request';
  static const otpRequest = '/otp-request';
  static const otpVerification = '/otp-verification';
  static const clientRegistrationForm = '/client-registration-form';
  static const clientRegistrationValidation = '/client-registration-validation';
  static const clientEmailOtp = '/client-email-otp';
  static const clientRegistrationSuccess = '/client-registration-success';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case registration:
        return MaterialPageRoute(
          builder: (_) => const RegistrationSelectionScreen(),
        );
      case clientHome:
        return MaterialPageRoute(
          builder: (_) =>
              ClientHomeScreen(user: settings.arguments as FakeAuthUser),
        );
      case workshopHome:
        return MaterialPageRoute(
          builder: (_) =>
              WorkshopHomeScreen(user: settings.arguments as FakeAuthUser),
        );
      case dashboard:
        return MaterialPageRoute(
          builder: (_) =>
              DashboardScreen(user: settings.arguments as FakeAuthUser?),
        );
      case emergencyRequest:
        return MaterialPageRoute(
          builder: (_) => EmergencyRequestScreen(
            args: settings.arguments as EmergencyRequestArgs,
          ),
        );
      case otpRequest:
        return MaterialPageRoute(builder: (_) => const OtpRequestScreen());
      case otpVerification:
        return MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            phoneNumber: settings.arguments as String,
          ),
        );
      case clientRegistrationForm:
        return MaterialPageRoute(
          builder: (_) => const ClientRegistrationFormScreen(),
        );
      case clientRegistrationValidation:
        return MaterialPageRoute(
          builder: (_) => ClientRegistrationValidationScreen(
            data: settings.arguments as ClientRegistrationData,
          ),
        );
      case clientEmailOtp:
        return MaterialPageRoute(
          builder: (_) => ClientEmailOtpScreen(
            data: settings.arguments as ClientRegistrationData,
          ),
        );
      case clientRegistrationSuccess:
        return MaterialPageRoute(
          builder: (_) => ClientRegistrationSuccessScreen(
            data: settings.arguments as ClientRegistrationData,
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Ruta no encontrada: ${settings.name}'),
            ),
          ),
        );
    }
  }
}
