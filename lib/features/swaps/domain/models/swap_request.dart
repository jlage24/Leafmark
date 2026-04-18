import 'package:cloud_firestore/cloud_firestore.dart';

enum SwapStatus { pending, accepted, rejected }

class SwapRequest {
  final String id;
  final String requesterId;
  final String ownerId;
  final String bookOfferedId;
  final String bookWantedId;
  final SwapStatus status;
  final DateTime createdAt;

  SwapRequest({
    required this.id,
    required this.requesterId,
    required this.ownerId,
    required this.bookOfferedId,
    required this.bookWantedId,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'requesterId': requesterId,
      'ownerId': ownerId,
      'bookOfferedId': bookOfferedId,
      'bookWantedId': bookWantedId,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory SwapRequest.fromMap(Map<String, dynamic> map, String documentId) {
    return SwapRequest(
      id: documentId,
      requesterId: map['requesterId'] ?? '',
      ownerId: map['ownerId'] ?? '',
      bookOfferedId: map['bookOfferedId'] ?? '',
      bookWantedId: map['bookWantedId'] ?? '',
      status: SwapStatus.values.byName(map['status'] ?? 'pending'),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}