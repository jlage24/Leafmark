import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatStatus { active, accepted, completed, cancelled }

class ChatMetadata {
  final String swapId;
  final List<String> participantIds;
  final ChatStatus status;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final Map<String, DateTime> lastReadAt;
  final List<String> typingUids;
  final List<String> hiddenBy;

  const ChatMetadata({
    required this.swapId,
    required this.participantIds,
    required this.status,
    this.lastMessage,
    this.lastMessageAt,
    this.lastReadAt = const {},
    this.typingUids = const [],
    this.hiddenBy = const [],
  });

  Map<String, dynamic> toMap() => {
    'swapId': swapId,
    'participantIds': participantIds,
    'status': status.name,
    'lastMessage': lastMessage,
    'lastMessageAt': lastMessageAt != null
        ? Timestamp.fromDate(lastMessageAt!)
        : null,
    'hiddenBy': hiddenBy,
  };

  factory ChatMetadata.fromMap(Map<String, dynamic> map) {
    final rawRead = map['lastReadAt'] as Map<String, dynamic>?;
    final lastReadAt = rawRead != null
        ? rawRead.map((k, v) => MapEntry(k, (v as Timestamp).toDate()))
        : <String, DateTime>{};

    final rawTyping = map['typingUids'];
    final typingUids = rawTyping != null
        ? List<String>.from(rawTyping as List)
        : <String>[];
        
    final rawHidden = map['hiddenBy'];
    final hiddenBy = rawHidden != null
        ? List<String>.from(rawHidden as List)
        : <String>[];

    final rawStatus = map['status'] as String? ?? ChatStatus.active.name;
    final normalizedStatus = rawStatus == 'exchanged'
        ? ChatStatus.completed.name
        : rawStatus;

    return ChatMetadata(
      swapId: map['swapId'] as String,
      participantIds: List<String>.from(map['participantIds']),
      status: ChatStatus.values.byName(normalizedStatus),
      lastMessage: map['lastMessage'] as String?,
      lastMessageAt: map['lastMessageAt'] != null
          ? (map['lastMessageAt'] as Timestamp).toDate()
          : null,
      lastReadAt: lastReadAt,
      typingUids: typingUids,
      hiddenBy: hiddenBy,
    );
  }
}
