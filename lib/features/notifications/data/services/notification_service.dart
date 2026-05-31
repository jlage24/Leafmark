import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/app_notification.dart';

class NotificationService {
  final FirebaseFirestore _db;

  NotificationService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _db.collection('notifications');

  DocumentReference<Map<String, dynamic>> notificationDocument([
    String? notificationId,
  ]) {
    return notificationId == null
        ? _notifications.doc()
        : _notifications.doc(notificationId);
  }

  Future<void> createNotification(
      AppNotification notification, {
        String? notificationId,
      }) async {
    await notificationDocument(notificationId).set(notification.toMap());
  }

  Stream<List<AppNotification>> notificationsForUser(String uid) {
    if (uid.isEmpty) return Stream.value([]);

    return _notifications
        .where('recipientId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => AppNotification.fromMap(doc.data(), doc.id))
          .toList(),
    );
  }

  Stream<int> unreadCount(String uid) {
    if (uid.isEmpty) return Stream.value(0);

    return _notifications
        .where('recipientId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> markAsRead(String notificationId) async {
    await _notifications.doc(notificationId).update({'isRead': true});
  }

  Future<void> markAllAsRead(String uid) async {
    final unread = await _notifications
        .where('recipientId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _db.batch();

    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  Future<void> deleteNotification(String notificationId) async {
    await _notifications.doc(notificationId).delete();
  }

  Future<void> clearAllForUser(String uid) async {
    if (uid.isEmpty) return;

    final snapshot = await _notifications
        .where('recipientId', isEqualTo: uid)
        .get();

    final batch = _db.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}