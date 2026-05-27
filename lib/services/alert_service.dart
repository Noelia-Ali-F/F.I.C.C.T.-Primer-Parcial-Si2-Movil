import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

enum AlertCategory { success, warning, info }

class AppAlert {
  const AppAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.category,
    this.isUnread = true,
    this.sourceKey,
    this.actionType,
    this.actionPayload,
  });

  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final AlertCategory category;
  final bool isUnread;
  final String? sourceKey;
  final String? actionType;
  final Map<String, dynamic>? actionPayload;

  AppAlert copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? createdAt,
    AlertCategory? category,
    bool? isUnread,
    String? sourceKey,
    String? actionType,
    Map<String, dynamic>? actionPayload,
  }) {
    return AppAlert(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
      isUnread: isUnread ?? this.isUnread,
      sourceKey: sourceKey ?? this.sourceKey,
      actionType: actionType ?? this.actionType,
      actionPayload: actionPayload ?? this.actionPayload,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'category': category.name,
      'isUnread': isUnread,
      'sourceKey': sourceKey,
      'actionType': actionType,
      'actionPayload': actionPayload,
    };
  }

  static AppAlert fromJson(Map<String, dynamic> json) {
    return AppAlert(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      category: AlertCategory.values.byName(json['category'] as String),
      isUnread: json['isUnread'] as bool? ?? true,
      sourceKey: json['sourceKey'] as String?,
      actionType: json['actionType'] as String?,
      actionPayload: (json['actionPayload'] as Map?)?.cast<String, dynamic>(),
    );
  }
}

class AlertService {
  AlertService._();

  static const String _storageFileName = 'app_alerts.json';
  static bool _hydrated = false;

  static final ValueNotifier<List<AppAlert>> alerts =
      ValueNotifier<List<AppAlert>>(_initialAlerts);

  static final List<AppAlert> _initialAlerts = [
    AppAlert(
      id: 'welcome-alert',
      title: 'Centro de alertas habilitado',
      message:
          'Aquí verás actualizaciones de tu emergencia, novedades del taller y avisos importantes.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      category: AlertCategory.info,
    ),
  ];

  static void addAlert({
    required String title,
    required String message,
    required AlertCategory category,
    String? sourceKey,
    String? actionType,
    Map<String, dynamic>? actionPayload,
  }) {
    // Evita duplicados cuando la misma push entra por foreground/open/background.
    if (sourceKey != null &&
        alerts.value.any((item) => item.sourceKey == sourceKey)) {
      return;
    }

    final nextAlert = AppAlert(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      message: message,
      createdAt: DateTime.now(),
      category: category,
      sourceKey: sourceKey,
      actionType: actionType,
      actionPayload: actionPayload,
    );

    alerts.value = [nextAlert, ...alerts.value];
    unawaited(_persistAlerts());
  }

  static void markAllAsRead() {
    alerts.value = alerts.value
        .map((item) => item.isUnread ? item.copyWith(isUnread: false) : item)
        .toList(growable: false);
    unawaited(_persistAlerts());
  }

  static void markAsRead(String alertId) {
    alerts.value = alerts.value
        .map(
          (item) => item.id == alertId && item.isUnread
              ? item.copyWith(isUnread: false)
              : item,
        )
        .toList(growable: false);
    unawaited(_persistAlerts());
  }

  static int get unreadCount =>
      alerts.value.where((item) => item.isUnread).length;

  static void registerEmergencySubmitted({
    required String incidentNumber,
    required String vehicleName,
    required String problemType,
    String? etaLabel,
  }) {
    addAlert(
      title: 'Emergencia registrada',
      message:
          'Tu incidente $incidentNumber para $vehicleName por $problemType fue recibido correctamente.',
      category: AlertCategory.success,
    );

    addAlert(
      title: 'Seguimiento activado',
      message: etaLabel == null || etaLabel.trim().isEmpty
          ? 'Te notificaremos cuando un taller tome tu caso.'
          : 'Tiempo estimado de atención: $etaLabel.',
      category: AlertCategory.info,
    );
  }

  static void registerEmergencyFailed(String message) {
    addAlert(
      title: 'No se pudo enviar la emergencia',
      message: message,
      category: AlertCategory.warning,
    );
  }

  static Future<void> hydrate() async {
    if (_hydrated) {
      return;
    }

    try {
      // Las alertas viven en almacenamiento local para no depender solo de la push visible.
      final file = await _alertsFile();
      if (await file.exists()) {
        final raw = await file.readAsString();
        final decoded = jsonDecode(raw) as List<dynamic>;
        alerts.value = decoded
            .map((item) => AppAlert.fromJson(item as Map<String, dynamic>))
            .toList(growable: false);
      } else {
        await _persistAlerts();
      }
    } catch (_) {
      alerts.value = List<AppAlert>.from(_initialAlerts, growable: false);
    }

    _hydrated = true;
  }

  static void registerPushNotification({
    required String? title,
    required String? message,
    required Map<String, dynamic> data,
    String? sourceKey,
  }) {
    // Normaliza la push del backend a una alerta interna que la UI sí puede renderizar.
    final type = (data['type'] ?? '').toString().trim().toLowerCase();
    final alertTitle = (title ?? '').trim();
    final alertMessage = (message ?? '').trim();
    final workshopName = (data['workshop_name'] ?? '').toString().trim();
    final technicianName = (data['technician_name'] ?? '').toString().trim();
    final incidentDescription =
        (data['incident_description'] ?? '').toString().trim();

    switch (type) {
      case 'emergency_accepted':
        addAlert(
          title: alertTitle.isEmpty ? 'Emergencia aceptada' : alertTitle,
          message: alertMessage.isEmpty
              ? _buildEmergencyAcceptedMessage(
                  workshopName: workshopName,
                  incidentDescription: incidentDescription,
                )
              : alertMessage,
          category: AlertCategory.success,
          sourceKey: sourceKey,
        );
        return;
      case 'technician_assigned':
        addAlert(
          title: alertTitle.isEmpty ? 'Técnico asignado' : alertTitle,
          message: alertMessage.isEmpty
              ? _buildTechnicianAssignedMessage(
                  technicianName: technicianName,
                  workshopName: workshopName,
                  incidentDescription: incidentDescription,
                )
              : alertMessage,
          category: AlertCategory.info,
          sourceKey: sourceKey,
          // La alerta conserva el payload necesario para abrir luego el mapa desde Historial/Alertas.
          actionType: 'open_technician_map',
          actionPayload: {
            'emergency_id': data['emergency_id']?.toString(),
            'workshop_id': data['workshop_id']?.toString(),
            'workshop_name': workshopName,
            'technician_id': data['technician_id']?.toString(),
            'technician_name': technicianName,
            'incident_description': incidentDescription,
            'latitude': data['latitude']?.toString() ??
                data['technician_latitude']?.toString() ??
                data['workshop_latitude']?.toString(),
            'longitude': data['longitude']?.toString() ??
                data['technician_longitude']?.toString() ??
                data['workshop_longitude']?.toString(),
          },
        );
        return;
      default:
        addAlert(
          title: alertTitle.isEmpty ? 'Nueva notificación' : alertTitle,
          message: alertMessage.isEmpty
              ? 'Recibiste una actualización relacionada con tu asistencia.'
              : alertMessage,
          category: AlertCategory.info,
          sourceKey: sourceKey,
        );
    }
  }

  static Future<File> _alertsFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_storageFileName');
  }

  static Future<void> _persistAlerts() async {
    try {
      final file = await _alertsFile();
      final payload = jsonEncode(
        alerts.value.map((item) => item.toJson()).toList(growable: false),
      );
      await file.writeAsString(payload, flush: true);
    } catch (_) {
      // Ignoramos errores locales de persistencia y mantenemos las alertas en memoria.
    }
  }

  static String _buildEmergencyAcceptedMessage({
    required String workshopName,
    required String incidentDescription,
  }) {
    if (workshopName.isNotEmpty && incidentDescription.isNotEmpty) {
      return '$workshopName aceptó tu emergencia: $incidentDescription';
    }
    if (workshopName.isNotEmpty) {
      return '$workshopName aceptó tu emergencia.';
    }
    if (incidentDescription.isNotEmpty) {
      return 'Tu emergencia fue aceptada: $incidentDescription';
    }
    return 'Tu solicitud ya fue recibida por el taller.';
  }

  static String _buildTechnicianAssignedMessage({
    required String technicianName,
    required String workshopName,
    required String incidentDescription,
  }) {
    if (technicianName.isNotEmpty &&
        workshopName.isNotEmpty &&
        incidentDescription.isNotEmpty) {
      return '$technicianName de $workshopName atenderá: $incidentDescription';
    }
    if (technicianName.isNotEmpty && workshopName.isNotEmpty) {
      return '$technicianName de $workshopName atenderá tu emergencia.';
    }
    if (technicianName.isNotEmpty && incidentDescription.isNotEmpty) {
      return '$technicianName atenderá: $incidentDescription';
    }
    return 'Ya se asignó un técnico para atender tu emergencia.';
  }
}
