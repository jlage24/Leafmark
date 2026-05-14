import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String reporterId;
  final String reportedUid;
  final String reason;
  final String? description;
  final DateTime createdAt;

  Report({
    required this.reporterId,
    required this.reportedUid,
    required this.reason,
    this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'reporterId': reporterId,
    'reportedUid': reportedUid,
    'reason': reason,
    'description': description,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}