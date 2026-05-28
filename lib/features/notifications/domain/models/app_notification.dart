import 'package:cloud_firestore/cloud_firestore.dart';

enum AppNotificationType {
  swapRequest,
  chatMessage,
  proposal,
  counterOffer,
  swapAccepted,
}

class AppNotification {
  final String id;
  final String recipientId;
  final String senderId;
  final AppNotificationType type;
  final String title;
  final String body;
  final String? swapId;
  final String? chatId;
  final String? swapRequestId;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.recipientId,
    required this.senderId,
    required this.type,
    required this.title,
    required this.body,
    this.swapId,
    this.chatId,
    this.swapRequestId,
    required this.isRead,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'recipientId': recipientId,
      'senderId': senderId,
      'type': type.name,
      'title': title,
      'body': body,
      'swapId': swapId,
      'chatId': chatId,
      'swapRequestId': swapRequestId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map, String id) {
    return AppNotification(
      id: id,
      recipientId: map['recipientId'] as String,
      senderId: map['senderId'] as String,
      type: AppNotificationType.values.byName(map['type'] as String),
      title: map['title'] as String,
      body: map['body'] as String,
      swapId: map['swapId'] as String?,
      chatId: map['chatId'] as String?,
      swapRequestId: map['swapRequestId'] as String?,
      isRead: map['isRead'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}