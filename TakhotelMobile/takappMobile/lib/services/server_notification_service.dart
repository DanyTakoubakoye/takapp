import 'package:cloud_firestore/cloud_firestore.dart';

class ServerNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> streamNotificationsForServer(
    String serveurId,
  ) {
    return _firestore
        .collection('serverNotifications')
        .where('serveurId', isEqualTo: serveurId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection('serverNotifications')
        .doc(notificationId)
        .update({'isRead': true});
  }
}
