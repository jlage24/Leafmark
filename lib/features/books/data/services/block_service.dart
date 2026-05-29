import 'package:cloud_firestore/cloud_firestore.dart';

class BlockService {
  final FirebaseFirestore _db;

  BlockService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;


// Blocks a user by saving them
  Future<void> blockUser(String currentUid, String targetUid) async {
    if (currentUid.isEmpty || targetUid.isEmpty || currentUid == targetUid) {
      throw ArgumentError('Invalid block operation');
    }

    final batch = _db.batch();

    final blockRef = _db.collection('users').doc(currentUid).collection('blocked_users').doc(targetUid);
    batch.set(blockRef, {
      'blockedUid': targetUid,
      'blockedAt': FieldValue.serverTimestamp(),
    });

    final currentUserFollowingRef = _db.collection('users').doc(currentUid).collection('following').doc(targetUid);
    final targetUserFollowersRef = _db.collection('users').doc(targetUid).collection('followers').doc(currentUid);

    final targetUserFollowingRef = _db.collection('users').doc(targetUid).collection('following').doc(currentUid);
    final currentUserFollowersRef = _db.collection('users').doc(currentUid).collection('followers').doc(targetUid);

    batch.delete(currentUserFollowingRef);
    batch.delete(targetUserFollowersRef);
    batch.delete(targetUserFollowingRef);
    batch.delete(currentUserFollowersRef);

    await batch.commit();
  }
  // Unblocks a user
  Future<void> unblockUser(String currentUid, String targetUid) async {
    await _db
        .collection('users')
        .doc(currentUid)
        .collection('blocked_users')
        .doc(targetUid)
        .delete();
  }

  // Stream to get the IDs of users blocked by the current user in real-time
  Stream<List<String>> getBlockedUsersStream(String currentUid) {
    if (currentUid.isEmpty) return Stream.value([]);

    return _db
        .collection('users')
        .doc(currentUid)
        .collection('blocked_users')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.id).toList());
  }

  // Performs a one-time check to see if a block exists
  Future<bool> isBlocked(String currentUid, String targetUid) async {
    final doc = await _db
        .collection('users')
        .doc(currentUid)
        .collection('blocked_users')
        .doc(targetUid)
        .get();
    return doc.exists;
  }

  // Checks if there is a mutual block relationship (important for Swaps)
  Future<bool> hasBlockRelationship(String uid1, String uid2) async {
    final blockedBy1 = await isBlocked(uid1, uid2);
    if (blockedBy1) return true;
    final blockedBy2 = await isBlocked(uid2, uid1);
    return blockedBy2;
  }
}