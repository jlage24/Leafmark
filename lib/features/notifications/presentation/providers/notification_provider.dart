import 'package:flutter/material.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/services/notification_service.dart';
import '../../domain/models/app_notification.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service;
  final AuthProvider _auth;

  NotificationProvider({
    NotificationService? service,
    required AuthProvider auth,
  })  : _service = service ?? NotificationService(),
        _auth = auth;

  String get _uid => _auth.user?.uid ?? '';

  Stream<List<AppNotification>> notifications() {
    return _service.notificationsForUser(_uid);
  }

  Stream<int> unreadCount() {
    return _service.unreadCount(_uid);
  }

  Future<void> markAsRead(String notificationId) {
    return _service.markAsRead(notificationId);
  }

  Future<void> markAllAsRead() {
    return _service.markAllAsRead(_uid);
  }

  Future<void> deleteNotification(String notificationId) {
    return _service.deleteNotification(notificationId);
  }

  Future<void> clearAll() {
    return _service.clearAllForUser(_uid);
  }
}