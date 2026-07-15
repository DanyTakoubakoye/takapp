import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:takapp/core/app_navigator.dart';

import 'notification_web_helper_stub.dart'
    if (dart.library.html) 'notification_web_helper.dart';

class NotificationService {
  NotificationService._internal();

  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _webVapidKey =
      'BESeTB9jme8KdVL3AtMmY6tczmpLQZUgEHkPdmGbKlf54yuq3CFUUCPkgr2epT7Dk9KNZKifd0fxwuzOzOyGg-U';

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _serverNotificationsSub;

  StreamSubscription<String>? _tokenRefreshSub;

  final Set<String> _alreadyShownNotificationIds = {};
  bool _isPopupOpen = false;
  String _currentEstablishmentId = '';

  Future<void> init() async {
    await requestWebNotificationPermission();
    unlockWebSoundAfterUserInteraction();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await _showSystemAwareNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {});
  }

  Future<void> registerTokenForCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final token = await _messaging.getToken(vapidKey: _webVapidKey);

    print('WEB FCM TOKEN = $token');

    if (token == null || token.trim().isEmpty) return;

    await _firestore.collection('users').doc(user.uid).set({
      'fcmToken': token,
      'lastTokenUpdate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _tokenRefreshSub?.cancel();

    _tokenRefreshSub = _messaging.onTokenRefresh.listen((newToken) async {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      await _firestore.collection('users').doc(currentUser.uid).set({
        'fcmToken': newToken,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  void startServerNotificationListener({
    required String establishmentId,
    required String serveurId,
  }) {
    final safeEstablishmentId = establishmentId.trim();
    final safeServeurId = serveurId.trim();

    if (safeEstablishmentId.isEmpty || safeServeurId.isEmpty) {
      print('WEB NOTIFICATIONS LISTENER ERROR = établissement ou serveur vide');
      return;
    }

    _currentEstablishmentId = safeEstablishmentId;
    _serverNotificationsSub?.cancel();

    _serverNotificationsSub = _firestore
        .collection('serverNotifications')
        .where('establishmentId', isEqualTo: safeEstablishmentId)
        .where('serveurId', isEqualTo: safeServeurId)
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) async {
            if (snapshot.docs.isEmpty) return;
            if (_isPopupOpen) return;

            final doc = snapshot.docs.first;
            final data = doc.data();

            if (_alreadyShownNotificationIds.contains(doc.id)) return;

            _alreadyShownNotificationIds.add(doc.id);

            final title = (data['title'] ?? 'Commande prête').toString();
            final body = (data['body'] ?? '').toString();
            final source = (data['source'] ?? 'kitchen').toString();

            showWebNotification(
              title: title,
              body: body,
              establishmentId: safeEstablishmentId,
              tag: 'takapp_${safeEstablishmentId}_${doc.id}',
            );

            await playWebNotificationSound(
              source,
              establishmentId: safeEstablishmentId,
            );

            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await _showInAppPopup(
                notificationId: doc.id,
                title: title,
                body: body,
                establishmentId: safeEstablishmentId,
              );
            });
          },
          onError: (error) {
            print('WEB SERVER NOTIFICATIONS LISTENER ERROR = $error');
          },
        );
  }

  void stopServerNotificationListener() {
    _serverNotificationsSub?.cancel();
    _serverNotificationsSub = null;
    _isPopupOpen = false;
    _alreadyShownNotificationIds.clear();
    _currentEstablishmentId = '';
  }

  Future<void> markNotificationAsRead(
    String notificationId,
    String establishmentId,
  ) async {
    final safeEstablishmentId = establishmentId.trim();

    if (notificationId.trim().isEmpty || safeEstablishmentId.isEmpty) return;

    final docRef = _firestore
        .collection('serverNotifications')
        .doc(notificationId);

    final doc = await docRef.get();

    if (!doc.exists) return;

    final data = doc.data();

    if (data == null) return;

    if ((data['establishmentId'] ?? '').toString() != safeEstablishmentId) {
      throw Exception('Notification non liée à cet établissement.');
    }

    await docRef.update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _showSystemAwareNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final title = notification.title ?? 'Notification';
    final body = notification.body ?? '';
    final source = (message.data['source'] ?? 'kitchen').toString();

    final establishmentId =
        (message.data['establishmentId'] ?? _currentEstablishmentId).toString();

    if (establishmentId.trim().isEmpty) {
      print('WEB NOTIFICATION ignored: establishmentId manquant');
      return;
    }

    showWebNotification(
      title: title,
      body: body,
      establishmentId: establishmentId,
    );

    await playWebNotificationSound(source, establishmentId: establishmentId);
  }

  Future<void> _showInAppPopup({
    required String notificationId,
    required String title,
    required String body,
    required String establishmentId,
  }) async {
    final navigatorState = appNavigatorKey.currentState;
    final context = navigatorState?.overlay?.context;

    if (context == null) return;

    _isPopupOpen = true;

    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Notification',
      barrierColor: Colors.black.withOpacity(0.20),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 520,
                  constraints: const BoxConstraints(maxWidth: 520),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.shade200),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 18,
                        color: Colors.black26,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.notifications_active,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.of(dialogContext).pop();
                            },
                            borderRadius: BorderRadius.circular(18),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.close),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Align(alignment: Alignment.centerLeft, child: Text(body)),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () async {
                            await markNotificationAsRead(
                              notificationId,
                              establishmentId,
                            );

                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                          },
                          child: const Text('OK'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    _isPopupOpen = false;
  }
}
