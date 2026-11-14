import 'package:flutter/material.dart';

/// Mga abiso na ginagawa ng app mula sa totoong panahon, presyo, mga tanim ng farmer, at anunsyo ng admin/MAO.
enum NotificationType { stormAlert, rainAlert, heatAlert, harvestReady, harvestSoon, marketUp, marketDown, plantingNow, announcement }

class AppNotification {
  final NotificationType type;
  final IconData icon;
  final DateTime time;

  /// ID ng pananim (hal. 'Rice') kung may kinalaman sa isang pananim.
  final String? crop;

  /// Numerong ginagamit sa teksto (mm ng ulan, heat index, % ng presyo, o bilang ng araw).
  final int value;

  /// Pamagat at nilalaman kung anunsyo mula sa Admin / MAO.
  final String? announcementTitle;
  final String? announcementContent;
  final String? category;
  bool isRead;

  AppNotification({
    required this.type,
    required this.icon,
    required this.time,
    this.crop,
    this.value = 0,
    this.announcementTitle,
    this.announcementContent,
    this.category,
    this.isRead = false,
  });

  /// Ginagamit ng provider sa markNotificationRead(id).
  String get id {
    if (type == NotificationType.announcement) {
      return 'announcement-${announcementTitle ?? ''}-${time.millisecondsSinceEpoch}';
    }
    return '${type.name}-${crop ?? ''}';
  }
}