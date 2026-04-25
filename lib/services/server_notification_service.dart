import 'package:cloud_firestore/cloud_firestore.dart';

class ServerNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('serverNotifications');

  Stream<QuerySnapshot<Map<String, dynamic>>> streamNotificationsForServer(
    String serveurId,
  ) {
    return _col
        .where('serveurId', isEqualTo: serveurId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> markAllAsReadForServer(String serveurId) async {
    final snapshot = await _col
        .where('serveurId', isEqualTo: serveurId)
        .where('isRead', isEqualTo: false)
        .get();

    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> markAsRead(String notificationId) async {
    await _col.doc(notificationId).update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }
}
