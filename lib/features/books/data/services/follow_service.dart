import 'package:cloud_firestore/cloud_firestore.dart';

class FollowService {
  final FirebaseFirestore _db;

  FollowService({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  Future<void> followUser(String followerId, String followedId) async {
    if (followerId.isEmpty || followedId.isEmpty || followerId == followedId) return;

    final batch = _db.batch();

    // Add the followed user to the current user's 'following' subcollection
    final followingRef = _db.collection('users').doc(followerId).collection('following').doc(followedId);
    batch.set(followingRef, {
      'followedUid': followedId,
      'followedAt': FieldValue.serverTimestamp(),
    });

    // Add the current user to the target user's 'followers' subcollection
    final followersRef = _db.collection('users').doc(followedId).collection('followers').doc(followerId);
    batch.set(followersRef, {
      'followerUid': followerId,
      'followedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> unfollowUser(String followerId, String followedId) async {
    final batch = _db.batch();

    final followingRef = _db.collection('users').doc(followerId).collection('following').doc(followedId);
    batch.delete(followingRef);

    final followersRef = _db.collection('users').doc(followedId).collection('followers').doc(followerId);
    batch.delete(followersRef);

    await batch.commit();
  }

  Stream<bool> isFollowingStream(String followerId, String followedId) {
    if (followerId.isEmpty || followedId.isEmpty) return Stream.value(false);
    return _db
        .collection('users')
        .doc(followerId)
        .collection('following')
        .doc(followedId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Stream<int> getFollowersCount(String uid) {
    if (uid.isEmpty) return Stream.value(0);
    return _db.collection('users').doc(uid).collection('followers').snapshots().map((snap) => snap.docs.length);
  }
}