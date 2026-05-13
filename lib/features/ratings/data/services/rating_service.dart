import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/rating.dart';

class RatingService {
  final FirebaseFirestore _firestore;

  RatingService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> submitRating(Rating rating) async {
    await _firestore.collection('ratings').doc(rating.id).set(rating.toMap());
  }

  Stream<List<Rating>> getRatingsForUser(String uid) {
    return _firestore
        .collection('ratings')
        .where('revieweeId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Rating.fromDocument(doc))
        .toList());
  }

  Future<bool> hasRated(String swapId, String reviewerId) async {
    final querySnapshot = await _firestore
        .collection('ratings')
        .where('swapId', isEqualTo: swapId)
        .where('reviewerId', isEqualTo: reviewerId)
        .limit(1)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }
}