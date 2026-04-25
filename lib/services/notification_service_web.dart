import 'dart:async';
import 'dart:html' as html;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:takapp/core/app_navigator.dart';

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
  bool _soundUnlocked = false;

  Future<void> init() async {
    await _requestPermission();
    _unlockSoundAfterUserInteraction();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await _showSystemAwareNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {});
  }

  Future<void> registerTokenForCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final token = await _messaging.getToken(vapidKey: _webVapidKey);

    print('FCM TOKEN = $token');

    if (token == null || token.trim().isEmpty) return;

    await _firestore.collection('users').doc(user.uid).set({
      'fcmToken': token,
      'lastTokenUpdate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _tokenRefreshSub?.cancel();

    _tokenRefreshSub = _messaging.onTokenRefresh.listen((newToken) async {
      print('FCM TOKEN REFRESH = $newToken');

      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      await _firestore.collection('users').doc(currentUser.uid).set({
        'fcmToken': newToken,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  void startServerNotificationListener(String serveurId) {
    _serverNotificationsSub?.cancel();

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('SERVER NOTIFICATIONS LISTENER ERROR = user null');
      return;
    }

    final effectiveServeurId = serveurId.trim().isNotEmpty
        ? serveurId.trim()
        : currentUser.uid;

    if (effectiveServeurId != currentUser.uid) {
      print(
        'SERVER NOTIFICATIONS LISTENER WARNING: serveurId différent du uid connecté. '
        'serveurId=$effectiveServeurId uid=${currentUser.uid}',
      );
    }

    _serverNotificationsSub = _firestore
        .collection('serverNotifications')
        .where('serveurId', isEqualTo: effectiveServeurId)
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) async {
            print('NOTIFICATIONS SNAPSHOT size=${snapshot.docs.length}');

            if (snapshot.docs.isEmpty) return;
            if (_isPopupOpen) return;

            final doc = snapshot.docs.first;
            final data = doc.data();

            if (_alreadyShownNotificationIds.contains(doc.id)) return;

            _alreadyShownNotificationIds.add(doc.id);

            final title = (data['title'] ?? 'Commande prête').toString();
            final body = (data['body'] ?? '').toString();
            final source = (data['source'] ?? 'kitchen').toString();

            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await _playSound(source);

              await _showInAppPopup(
                notificationId: doc.id,
                title: title,
                body: body,
              );
            });
          },
          onError: (error) {
            print('SERVER NOTIFICATIONS LISTENER ERROR = $error');
          },
        );
  }

  void stopServerNotificationListener() {
    _serverNotificationsSub?.cancel();
    _serverNotificationsSub = null;
    _isPopupOpen = false;
    _alreadyShownNotificationIds.clear();
  }

  Stream<int> unreadNotificationsCountStream({String? serveurId}) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream<int>.value(0);
    }

    final effectiveServeurId = serveurId != null && serveurId.trim().isNotEmpty
        ? serveurId.trim()
        : user.uid;

    return _firestore
        .collection('serverNotifications')
        .where('serveurId', isEqualTo: effectiveServeurId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .handleError((error) {
          print('UNREAD NOTIFICATIONS COUNT ERROR = $error');
          return 0;
        });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> unreadNotificationsStream({
    String? serveurId,
  }) {
    final user = _auth.currentUser;

    if (user == null) {
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }

    final effectiveServeurId = serveurId != null && serveurId.trim().isNotEmpty
        ? serveurId.trim()
        : user.uid;

    return _firestore
        .collection('serverNotifications')
        .where('serveurId', isEqualTo: effectiveServeurId)
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('serverNotifications')
        .doc(notificationId)
        .update({
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> markAllAsReadForServer({String? serveurId}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final effectiveServeurId = serveurId != null && serveurId.trim().isNotEmpty
        ? serveurId.trim()
        : user.uid;

    final snapshot = await _firestore
        .collection('serverNotifications')
        .where('serveurId', isEqualTo: effectiveServeurId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    if (html.Notification.permission != 'granted') {
      await html.Notification.requestPermission();
    }
  }

  Future<void> _showSystemAwareNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    if (html.Notification.permission == 'granted') {
      html.Notification(
        notification.title ?? 'Commande prête',
        body: notification.body ?? '',
      );
    }

    final source = (message.data['source'] ?? 'kitchen').toString();
    await _playSound(source);
  }

  void _unlockSoundAfterUserInteraction() {
    html.document.onClick.first.then((_) async {
      if (_soundUnlocked) return;

      try {
        final audio = html.AudioElement('sounds/kitchen_ready.mp3');
        audio.volume = 0;
        await audio.play();
        audio.pause();
        audio.currentTime = 0;
        audio.volume = 1;
        _soundUnlocked = true;
        print('WEB SOUND UNLOCKED');
      } catch (e) {
        print('WEB SOUND UNLOCK FAILED = $e');
      }
    });
  }

  Future<void> _playSound(String source) async {
    final audioPath = source == 'bar'
        ? 'sounds/bar_ready.mp3'
        : 'sounds/kitchen_ready.mp3';

    try {
      final audio = html.AudioElement(audioPath);
      audio.volume = 1;
      await audio.play();
    } catch (e) {
      print('WEB SOUND PLAY ERROR = $e');
    }
  }

  Future<void> _showInAppPopup({
    required String notificationId,
    required String title,
    required String body,
  }) async {
    final navigatorState = appNavigatorKey.currentState;
    final context = navigatorState?.overlay?.context;

    print('SHOW POPUP context=${context != null} title=$title');

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
                            await markNotificationAsRead(notificationId);

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
