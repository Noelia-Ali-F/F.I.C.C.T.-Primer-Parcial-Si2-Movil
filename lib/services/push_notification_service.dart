import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'alert_service.dart';
import 'push_device_registration_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    await AlertService.hydrate();
    // En background no navegamos; solo persistimos para que la alerta exista al abrir la app.
    AlertService.registerPushNotification(
      title: message.notification?.title,
      message: message.notification?.body,
      data: message.data,
      sourceKey: _messageSourceKey(message),
    );
  } catch (_) {
    return;
  }
  log(
    'FCM background message: ${message.messageId} '
    'data=${message.data}',
    name: 'PushNotificationService',
  );
}

class PushNotificationService {
  PushNotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    // El servicio se inicia una sola vez y conecta todos los listeners de FCM.
    await AlertService.hydrate();
    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
    );

    await _requestPermissions();
    await _configureForegroundPresentation();
    await _logInitialToken();
    _listenToTokenRefresh();
    _listenToForegroundMessages();
    _listenToNotificationOpens();
    await _handleInitialMessage();

    _initialized = true;
  }

  static Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    log(
      'FCM permission status: ${settings.authorizationStatus}',
      name: 'PushNotificationService',
    );
  }

  static Future<void> _configureForegroundPresentation() async {
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> _logInitialToken() async {
    final token = await _messaging.getToken();
    log('FCM token: $token', name: 'PushNotificationService');
  }

  static void _listenToTokenRefresh() {
    _messaging.onTokenRefresh.listen((token) {
      log('FCM token refreshed: $token', name: 'PushNotificationService');
      PushDeviceRegistrationService.registerRefreshedToken(token);
    });
  }

  static void _listenToForegroundMessages() {
    FirebaseMessaging.onMessage.listen((message) {
      // Cuando la app está abierta, usamos el mismo flujo de AlertService para no duplicar lógica.
      AlertService.registerPushNotification(
        title: message.notification?.title,
        message: message.notification?.body,
        data: message.data,
        sourceKey: _messageSourceKey(message),
      );
      log(
        'FCM foreground message: ${message.messageId} '
        'title=${message.notification?.title} '
        'body=${message.notification?.body} '
        'data=${message.data}',
        name: 'PushNotificationService',
      );
    });
  }

  static void _listenToNotificationOpens() {
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      AlertService.registerPushNotification(
        title: message.notification?.title,
        message: message.notification?.body,
        data: message.data,
        sourceKey: _messageSourceKey(message),
      );
      log(
        'FCM notification opened: ${message.messageId} data=${message.data}',
        name: 'PushNotificationService',
      );
      // El tap del sistema ya no navega directo; solo despierta la app y deja la acción en la alerta.
      _handleNotificationOpen(message);
    });
  }

  static Future<void> _handleInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage == null) {
      return;
    }

    AlertService.registerPushNotification(
      title: initialMessage.notification?.title,
      message: initialMessage.notification?.body,
      data: initialMessage.data,
      sourceKey: _messageSourceKey(initialMessage),
    );
    log(
      'FCM initial message: ${initialMessage.messageId} '
      'data=${initialMessage.data}',
      name: 'PushNotificationService',
    );
    _handleNotificationOpen(initialMessage);
  }

  static void _handleNotificationOpen(RemoteMessage message) {
    final type = message.data['type']?.toString().trim().toLowerCase();
    if (type == null) {
      return;
    }

    // La navegación real se resuelve desde la UI al tocar la fila correspondiente.
    log(
      'FCM notification tap type=$type data=${message.data}',
      name: 'PushNotificationService',
    );
  }
}

String _messageSourceKey(RemoteMessage message) {
  final messageId = message.messageId;
  if (messageId != null && messageId.trim().isNotEmpty) {
    return messageId;
  }

  return [
    message.data['type'],
    message.data['emergency_id'],
    message.data['workshop_id'],
    message.data['technician_id'],
    message.notification?.title,
    message.notification?.body,
  ].join('|');
}
