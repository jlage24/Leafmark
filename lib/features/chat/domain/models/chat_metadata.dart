import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatStatus { active, completed, cancelled }

class ChatMetadata {
  final String swapId;
  final List<String> participantIds;
  final ChatStatus status;
  final String? lastMessage;
  final DateTime? lastMessageAt;

  const ChatMetadata({
    required this.swapId,
    required this.participantIds,
    required this.status,
    this.lastMessage,
    this.lastMessageAt,
  });

  Map<String, dynamic> toMap() => {
    'swapId': swapId,
    'participantIds': participantIds,
    'status': status.name,
    'lastMessage': lastMessage,
    'lastMessageAt': lastMessageAt != null
        ? Timestamp.fromDate(lastMessageAt!)
        : null,
  };

  factory ChatMetadata.fromMap(Map<String, dynamic> map) => ChatMetadata(
    swapId: map['swapId'] as String,
    participantIds: List<String>.from(map['participantIds']),
    status: ChatStatus.values.byName(map['status'] as String),
    lastMessage: map['lastMessage'] as String?,
    lastMessageAt: map['lastMessageAt'] != null
        ? (map['lastMessageAt'] as Timestamp).toDate()
        : null,
  );
}