import 'package:flutter/material.dart';

import 'app_navigation.dart';
import 'app_routes.dart';
import 'screens/welcome_screen.dart';

class TallerAcbApp extends StatefulWidget {
  const TallerAcbApp({super.key});

  @override
  State<TallerAcbApp> createState() => _TallerAcbAppState();
}

class _TallerAcbAppState extends State<TallerAcbApp> {
  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF123F78);
    const gold = Color(0xFFD8AD20);
    const canvas = Color(0xFFF4F7FB);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Taller ACB',
      navigatorKey: appNavigatorKey,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: canvas,
        colorScheme: ColorScheme.fromSeed(
          seedColor: navy,
          primary: navy,
          secondary: gold,
          surface: Colors.white,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1,
          ),
          headlineSmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: navy,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: navy,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Color(0xFF55637C),
          ),
        ),
      ),
      onGenerateRoute: AppRoutes.onGenerateRoute,
      home: const WelcomeScreen(),
    );
  }
}
