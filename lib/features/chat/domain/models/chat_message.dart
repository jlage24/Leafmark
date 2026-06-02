import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, proposal, counterOffer }

class ChatMessage {
  final String id;
  final String senderId;
  final MessageType type;
  final String? text;
  final String? bookOfferedId;
  final String? bookOfferedOwnerId;
  final String? bookWantedId;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.type,
    this.text,
    this.bookOfferedId,
    this.bookOfferedOwnerId,
    this.bookWantedId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'senderId': senderId,
    'type': type.name,
    'text': text,
    'bookOfferedId': bookOfferedId,
    'bookOfferedOwnerId': bookOfferedOwnerId,
    'bookWantedId': bookWantedId,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) =>
      ChatMessage(
        id: id,
        senderId: map['senderId'] as String,
        type: MessageType.values.byName(map['type'] as String),
        text: map['text'] as String?,
        bookOfferedId: map['bookOfferedId'] as String?,
        bookOfferedOwnerId: map['bookOfferedOwnerId'] as String?,
        bookWantedId: map['bookWantedId'] as String?,
        createdAt: (map['createdAt'] as Timestamp).toDate(),
      );
}
