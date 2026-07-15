import 'dart:async';

/// =======================================================
/// WEB NOTIFICATION HELPERS - VERSION SAAS SAFE
/// Compatible Flutter Web multi-tenant
/// =======================================================

Future<void> requestWebNotificationPermission() async {
  // Stub volontaire pour plateformes non-web
  // La vraie implémentation web sera dans :
  // web_notification_service_web.dart
}

void showWebNotification({
  required String title,
  required String body,
  String? establishmentId,
  String? tag,
}) {
  // Stub volontaire
}

void unlockWebSoundAfterUserInteraction() {
  // Stub volontaire
}

Future<void> playWebNotificationSound(
  String source, {
  String? establishmentId,
}) async {
  // Stub volontaire
}
