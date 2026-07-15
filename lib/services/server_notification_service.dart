import 'package:cloud_firestore/cloud_firestore.dart';

class ServerNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// =========================
  /// HELPERS SAAS
  /// =========================

  CollectionReference<Map<String, dynamic>> _col({
    required String establishmentId,
  }) {
    return _firestore
        .collection('establishments')
        .doc(establishmentId)
        .collection('serverNotifications');
  }

  void _validateEstablishmentId(String establishmentId) {
    if (establishmentId.trim().isEmpty) {
      throw Exception('Établissement introuvable.');
    }
  }

  /// =========================
  /// STREAM NOTIFICATIONS
  /// =========================

  Stream<QuerySnapshot<Map<String, dynamic>>> streamNotificationsForServer({
    required String establishmentId,
    required String serveurId,
  }) {
    _validateEstablishmentId(establishmentId);

    return _col(establishmentId: establishmentId)
        .where('serveurId', isEqualTo: serveurId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// =========================
  /// UNREAD COUNT
  /// =========================

  Stream<int> streamUnreadCountForServer({
    required String establishmentId,
    required String serveurId,
  }) {
    _validateEstablishmentId(establishmentId);

    return _col(establishmentId: establishmentId)
        .where('serveurId', isEqualTo: serveurId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// =========================
  /// MARK ALL AS READ
  /// =========================

  Future<void> markAllAsReadForServer({
    required String establishmentId,
    required String serveurId,
  }) async {
    _validateEstablishmentId(establishmentId);

    final snapshot = await _col(establishmentId: establishmentId)
        .where('serveurId', isEqualTo: serveurId)
        .where('isRead', isEqualTo: false)
        .get();

    if (snapshot.docs.isEmpty) return;

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

  /// =========================
  /// MARK ONE AS READ
  /// =========================

  Future<void> markAsRead({
    required String establishmentId,
    required String notificationId,
  }) async {
    _validateEstablishmentId(establishmentId);

    await _col(establishmentId: establishmentId).doc(notificationId).update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
