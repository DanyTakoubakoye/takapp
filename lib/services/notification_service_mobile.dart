import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:takapp/core/app_navigator.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _serverNotificationsSub;

  final Set<String> _alreadyShownNotificationIds = {};
  bool _isPopupOpen = false;

  // ⚠️ Nouveaux IDs de channel
  static const String kitchenChannelId = 'kitchen_ready_channel_v5';
  static const String barChannelId = 'bar_ready_channel_v5';

  Future<void> init() async {
    await _requestPermission();
    await _initLocalNotifications();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await _showSystemAwareNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {});
  }

  Future<void> registerTokenForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await _messaging.getToken();

    print('FCM TOKEN = $token');

    if (token == null || token.trim().isEmpty) return;

    await _firestore.collection('users').doc(user.uid).set({
      'fcmToken': token,
      'lastTokenUpdate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _messaging.onTokenRefresh.listen((newToken) async {
      print('FCM TOKEN REFRESH = $newToken');

      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': newToken,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> _showLocalNotificationFromFirestore({
    required String notificationId,
    required String title,
    required String body,
    required String source,
  }) async {
    final channelId = source == 'bar' ? barChannelId : kitchenChannelId;

    final channelName = source == 'bar' ? 'Bar prêt' : 'Cuisine prête';

    final channelDescription = source == 'bar'
        ? 'Notifications quand une commande bar est prête'
        : 'Notifications quand une commande cuisine est prête';

    final AndroidNotificationSound sound = source == 'bar'
        ? const RawResourceAndroidNotificationSound('bar_ready')
        : const RawResourceAndroidNotificationSound('kitchen_ready');

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: sound,
    );

    final details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      id: notificationId.hashCode,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  void startServerNotificationListener(String serveurId) {
    print('START LISTENER serveurId=$serveurId');

    _serverNotificationsSub?.cancel();

    _serverNotificationsSub = _firestore
        .collection('serverNotifications')
        .where('serveurId', isEqualTo: serveurId)
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

            final title = (data['title'] ?? '').toString();
            final body = (data['body'] ?? '').toString();

            final source = (data['source'] ?? 'kitchen').toString();

            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await _showLocalNotificationFromFirestore(
                notificationId: doc.id,
                title: title,
                body: body,
                source: source,
              );

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

  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore
        .collection('serverNotifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.requestNotificationsPermission();
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(settings: initSettings);

    const kitchenChannel = AndroidNotificationChannel(
      kitchenChannelId,
      'Cuisine prête',
      description: 'Notifications quand une commande cuisine est prête',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('kitchen_ready'),
    );

    const barChannel = AndroidNotificationChannel(
      barChannelId,
      'Bar prêt',
      description: 'Notifications quand une commande bar est prête',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('bar_ready'),
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(kitchenChannel);
    await androidPlugin?.createNotificationChannel(barChannel);
  }

  Future<void> _showSystemAwareNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final source = (message.data['source'] ?? 'kitchen').toString();

    final channelId = source == 'bar' ? barChannelId : kitchenChannelId;

    final channelName = source == 'bar' ? 'Bar prêt' : 'Cuisine prête';

    final channelDescription = source == 'bar'
        ? 'Notifications quand une commande bar est prête'
        : 'Notifications quand une commande cuisine est prête';

    final AndroidNotificationSound sound = source == 'bar'
        ? const RawResourceAndroidNotificationSound('bar_ready')
        : const RawResourceAndroidNotificationSound('kitchen_ready');

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: sound,
    );

    final details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      id: notification.hashCode,
      title:
          notification.title ??
          (source == 'bar' ? 'Commande bar prête' : 'Commande prête'),
      body: notification.body ?? '',
      notificationDetails: details,
    );
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
