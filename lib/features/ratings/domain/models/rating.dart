import 'package:cloud_firestore/cloud_firestore.dart';

class Rating {
  final String id;
  final String reviewerId;
  final String revieweeId;
  final String swapId;
  final int rating;
  final int bookConditionRating;
  final String? comment;
  final DateTime createdAt;

  Rating({
    required this.id,
    required this.reviewerId,
    required this.revieweeId,
    required this.swapId,
    required this.rating,
    required this.bookConditionRating,
    this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'reviewerId': reviewerId,
      'revieweeId': revieweeId,
      'swapId': swapId,
      'rating': rating,
      'bookConditionRating': bookConditionRating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory Rating.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Rating(
      id: doc.id,
      reviewerId: data['reviewerId'] ?? '',
      revieweeId: data['revieweeId'] ?? '',
      swapId: data['swapId'] ?? '',
      rating: data['rating']?.toInt() ?? 0,
      bookConditionRating: data['bookConditionRating']?.toInt() ?? 0,
      comment: data['comment'],
      createdAt: (data['createdAt'] as Timestamp)
          .toDate(), // Convert back to DateTime
    );
  }
}
