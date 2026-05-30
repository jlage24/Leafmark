import 'package:cloud_firestore/cloud_firestore.dart';
import 'block_service.dart';
import '../../../notifications/data/services/notification_service.dart';
import '../../../notifications/domain/models/app_notification.dart';

class FollowService {
  final FirebaseFirestore _db;
  final BlockService _blockService;
  final NotificationService _notificationService;

  FollowService({
    FirebaseFirestore? firestore,
    BlockService? blockService,
    NotificationService? notificationService,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _blockService = blockService ?? BlockService(),
        _notificationService = notificationService ?? NotificationService();

  Future<void> followUser(String followerId, String followedId) async {
    if (followerId.isEmpty || followedId.isEmpty || followerId == followedId) {
      return;
    }

    final hasBlock = await _blockService.hasBlockRelationship(
      followerId,
      followedId,
    );

    if (hasBlock) {
      throw Exception('Cannot follow user. The user is blocked.');
    }

    final senderInfo = await fetchUserInfo(followerId);
    final senderName = senderInfo['displayName'] ?? 'Someone';

    final batch = _db.batch();

    final followingRef = _db
        .collection('users')
        .doc(followerId)
        .collection('following')
        .doc(followedId);

    batch.set(followingRef, {
      'followedUid': followedId,
      'followedAt': FieldValue.serverTimestamp(),
    });

    final followersRef = _db
        .collection('users')
        .doc(followedId)
        .collection('followers')
        .doc(followerId);

    batch.set(followersRef, {
      'followerUid': followerId,
      'followedAt': FieldValue.serverTimestamp(),
    });

    final notificationRef = _notificationService.notificationDocument(
      'follow_${followerId}_$followedId',
    );

    batch.set(
      notificationRef,
      AppNotification(
        id: '',
        recipientId: followedId,
        senderId: followerId,
        senderDisplayName: senderName,
        senderPhotoUrl: senderInfo['photoUrl'],
        type: AppNotificationType.newFollower,
        title: 'New follower',
        body: '$senderName started following you.',
        isRead: false,
        createdAt: DateTime.now(),
      ).toMap(),
    );

    await batch.commit();
  }

  Future<void> unfollowUser(String followerId, String followedId) async {
    final batch = _db.batch();

    final followingRef = _db
        .collection('users')
        .doc(followerId)
        .collection('following')
        .doc(followedId);

    batch.delete(followingRef);

    final followersRef = _db
        .collection('users')
        .doc(followedId)
        .collection('followers')
        .doc(followerId);

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

    return _db
        .collection('users')
        .doc(uid)
        .collection('followers')
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Stream<int> getFollowingCount(String uid) {
    if (uid.isEmpty) return Stream.value(0);

    return _db
        .collection('users')
        .doc(uid)
        .collection('following')
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Stream<List<String>> getFollowers(String uid) {
    if (uid.isEmpty) return Stream.value([]);

    return _db
        .collection('users')
        .doc(uid)
        .collection('followers')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.id).toList());
  }

  Stream<List<String>> getFollowing(String uid) {
    if (uid.isEmpty) return Stream.value([]);

    return _db
        .collection('users')
        .doc(uid)
        .collection('following')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.id).toList());
  }

  Future<Map<String, String?>> fetchUserInfo(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();

      if (!doc.exists) {
        return {
          'displayName': null,
          'photoUrl': null,
        };
      }

      final data = doc.data()!;

      return {
        'displayName': data['displayName'] as String?,
        'photoUrl': data['profilePictureUrl'] as String?,
      };
    } catch (_) {
      return {
        'displayName': null,
        'photoUrl': null,
      };
    }
  }
}