import 'dart:html' as html;

import 'package:flutter/foundation.dart';

/// =======================================================
/// WEB NOTIFICATION HELPERS - VERSION SAAS
/// =======================================================
///
/// Compatible Flutter Web multi-tenant.
///
/// Cette version :
/// - ajoute establishmentId
/// - ajoute tags multi-tenant
/// - évite collisions notifications
/// - évite collisions audio SaaS
/// - sécurise autoplay navigateur
///
/// =======================================================

bool _webSoundUnlocked = false;

/// =======================================================
/// REQUEST NOTIFICATION PERMISSION
/// =======================================================

Future<void> requestWebNotificationPermission() async {
  try {
    if (html.Notification.permission != 'granted') {
      await html.Notification.requestPermission();
    }
  } catch (e) {
    debugPrint('WEB NOTIFICATION PERMISSION ERROR = $e');
  }
}

/// =======================================================
/// SHOW WEB NOTIFICATION
/// =======================================================

void showWebNotification({
  required String title,
  required String body,

  /// SAAS
  required String establishmentId,

  /// optionnel
  String? tag,
}) {
  try {
    if (html.Notification.permission != 'granted') {
      return;
    }

    final notificationTag = tag ?? 'takapp_$establishmentId';

    html.Notification(title, body: body, tag: notificationTag);
  } catch (e) {
    debugPrint('WEB NOTIFICATION ERROR = $e');
  }
}

/// =======================================================
/// UNLOCK WEB SOUND
/// =======================================================

void unlockWebSoundAfterUserInteraction() {
  if (_webSoundUnlocked) return;

  html.document.onClick.first.then((_) async {
    try {
      final audio = html.AudioElement('sounds/kitchen_ready.mp3');

      audio.volume = 0;

      await audio.play();

      audio.pause();

      audio.currentTime = 0;

      audio.volume = 1;

      _webSoundUnlocked = true;

      debugPrint('WEB SOUND UNLOCKED');
    } catch (e) {
      debugPrint('WEB SOUND UNLOCK FAILED = $e');
    }
  });
}

/// =======================================================
/// PLAY NOTIFICATION SOUND
/// =======================================================

Future<void> playWebNotificationSound(
  String source, {

  /// SAAS
  required String establishmentId,
}) async {
  try {
    if (!_webSoundUnlocked) {
      debugPrint(
        'WEB SOUND BLOCKED '
        '(interaction utilisateur requise)',
      );

      return;
    }

    final audioPath = source == 'bar' || source == 'bar_new_order'
        ? 'sounds/bar_ready.mp3'
        : 'sounds/kitchen_ready.mp3';

    final audio = html.AudioElement(audioPath);

    audio.volume = 1;

    /// important pour SaaS multi notifications
    audio.preload = 'auto';

    /// évite cache étrange navigateur
    audio.setAttribute('data-establishment-id', establishmentId);

    await audio.play();
  } catch (e) {
    debugPrint('WEB SOUND PLAY ERROR = $e');
  }
}
