import 'package:flutter/material.dart';

/// Mga abiso na ginagawa ng app mula sa totoong panahon, presyo at mga tanim ng farmer.
enum NotificationType { stormAlert, rainAlert, heatAlert, harvestReady, harvestSoon, marketUp, marketDown, plantingNow }

class AppNotification {
  final NotificationType type;
  final IconData icon;
  final DateTime time;

  /// ID ng pananim (hal. 'Rice') kung may kinalaman sa isang pananim.
  final String? crop;

  /// Numerong ginagamit sa teksto (mm ng ulan, heat index, % ng presyo, o bilang ng araw).
  final int value;
  bool isRead;

  AppNotification({
    required this.type,
    required this.icon,
    required this.time,
    this.crop,
    this.value = 0,
    this.isRead = false,
  });

  /// Ginagamit ng provider sa markNotificationRead(id).
  String get id => '${type.name}-${crop ?? ''}';
}