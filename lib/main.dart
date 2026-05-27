import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'services/alert_service.dart';
import 'services/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AlertService.hydrate();
  try {
    await Firebase.initializeApp();
    await PushNotificationService.initialize();
  } catch (error, stackTrace) {
    log(
      'Firebase/FCM no quedó inicializado. Verifica google-services.json y '
      'GoogleService-Info.plist. Error: $error',
      name: 'main',
      stackTrace: stackTrace,
    );
  }
  runApp(const TallerAcbApp());
}
