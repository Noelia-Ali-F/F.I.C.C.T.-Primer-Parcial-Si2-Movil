import 'package:flutter/material.dart';

import 'models/auth_models.dart';
import 'screens/client_home_screen.dart';
import 'screens/dashboard_screen.dart';
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
  static const otpRequest = '/otp-request';
  static const otpVerification = '/otp-verification';

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
      case otpRequest:
        return MaterialPageRoute(builder: (_) => const OtpRequestScreen());
      case otpVerification:
        return MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            phoneNumber: settings.arguments as String,
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
