import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leafmark/features/books/data/services/block_service.dart';
import 'package:leafmark/features/books/data/services/follow_service.dart';
import 'package:leafmark/features/notifications/data/services/notification_service.dart';

void main() {
  late FakeFirebaseFirestore fakeDb;
  late BlockService blockService;
  late NotificationService notificationService;
  late FollowService followService;

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    blockService = BlockService(firestore: fakeDb);
    notificationService = NotificationService(firestore: fakeDb);
    followService = FollowService(
      firestore: fakeDb,
      blockService: blockService,
      notificationService: notificationService,
    );
  });

  Future<void> createUser(String uid, String displayName) async {
    await fakeDb.collection('users').doc(uid).set({
      'displayName': displayName,
      'profilePictureUrl': '$uid-photo',
    });
  }

  group('FollowService Unit Tests', () {
    test('followUser creates following and follower documents', () async {
      await createUser('userA', 'Alice');

      await followService.followUser('userA', 'userB');

      final followingSnap = await fakeDb
          .collection('users')
          .doc('userA')
          .collection('following')
          .doc('userB')
          .get();

      final followerSnap = await fakeDb
          .collection('users')
          .doc('userB')
          .collection('followers')
          .doc('userA')
          .get();

      expect(followingSnap.exists, isTrue);
      expect(followingSnap['followedUid'], 'userB');
      expect(followingSnap.data()!.containsKey('followedAt'), isTrue);

      expect(followerSnap.exists, isTrue);
      expect(followerSnap['followerUid'], 'userA');
      expect(followerSnap.data()!.containsKey('followedAt'), isTrue);
    });

    test('followUser creates new follower notification', () async {
      await createUser('userA', 'Alice');

      await followService.followUser('userA', 'userB');

      final snap = await fakeDb
          .collection('notifications')
          .doc('follow_userA_userB')
          .get();

      expect(snap.exists, isTrue);
      expect(snap['recipientId'], 'userB');
      expect(snap['senderId'], 'userA');
      expect(snap['senderDisplayName'], 'Alice');
      expect(snap['senderPhotoUrl'], 'userA-photo');
      expect(snap['title'], 'New follower');
      expect(snap['body'], 'Alice started following you.');
      expect(snap['isRead'], isFalse);
    });

    test('unfollowUser removes following and follower documents', () async {
      await followService.followUser('userA', 'userB');

      await followService.unfollowUser('userA', 'userB');

      final followingSnap = await fakeDb
          .collection('users')
          .doc('userA')
          .collection('following')
          .doc('userB')
          .get();

      final followerSnap = await fakeDb
          .collection('users')
          .doc('userB')
          .collection('followers')
          .doc('userA')
          .get();

      expect(followingSnap.exists, isFalse);
      expect(followerSnap.exists, isFalse);
    });

    test(
      'followUser throws exception when users have block relationship',
      () async {
        await blockService.blockUser('userA', 'userB');

        await expectLater(
          followService.followUser('userA', 'userB'),
          throwsException,
        );

        final followingSnap = await fakeDb
            .collection('users')
            .doc('userA')
            .collection('following')
            .doc('userB')
            .get();

        final followerSnap = await fakeDb
            .collection('users')
            .doc('userB')
            .collection('followers')
            .doc('userA')
            .get();

        final notificationSnap = await fakeDb.collection('notifications').get();

        expect(followingSnap.exists, isFalse);
        expect(followerSnap.exists, isFalse);
        expect(notificationSnap.docs, isEmpty);
      },
    );

    test('followUser does nothing for self follow', () async {
      await followService.followUser('userA', 'userA');

      final followingSnap = await fakeDb
          .collection('users')
          .doc('userA')
          .collection('following')
          .get();

      final followerSnap = await fakeDb
          .collection('users')
          .doc('userA')
          .collection('followers')
          .get();

      final notificationSnap = await fakeDb.collection('notifications').get();

      expect(followingSnap.docs, isEmpty);
      expect(followerSnap.docs, isEmpty);
      expect(notificationSnap.docs, isEmpty);
    });

    test('followUser does nothing for empty user id', () async {
      await followService.followUser('', 'userB');
      await followService.followUser('userA', '');

      final userAFollowingSnap = await fakeDb
          .collection('users')
          .doc('userA')
          .collection('following')
          .get();

      final userBFollowersSnap = await fakeDb
          .collection('users')
          .doc('userB')
          .collection('followers')
          .get();

      final notificationSnap = await fakeDb.collection('notifications').get();

      expect(userAFollowingSnap.docs, isEmpty);
      expect(userBFollowersSnap.docs, isEmpty);
      expect(notificationSnap.docs, isEmpty);
    });

    test(
      'isFollowingStream returns true after follow and false after unfollow',
      () async {
        await followService.followUser('userA', 'userB');

        final afterFollow = await followService
            .isFollowingStream('userA', 'userB')
            .first;

        await followService.unfollowUser('userA', 'userB');

        final afterUnfollow = await followService
            .isFollowingStream('userA', 'userB')
            .first;

        expect(afterFollow, isTrue);
        expect(afterUnfollow, isFalse);
      },
    );

    test('isFollowingStream returns false for empty user id', () async {
      final result = await followService.isFollowingStream('', 'userB').first;

      expect(result, isFalse);
    });

    test('getFollowersCount updates after follow and unfollow', () async {
      await followService.followUser('userA', 'userB');
      await followService.followUser('userC', 'userB');

      final afterFollow = await followService.getFollowersCount('userB').first;

      await followService.unfollowUser('userA', 'userB');

      final afterUnfollow = await followService
          .getFollowersCount('userB')
          .first;

      expect(afterFollow, 2);
      expect(afterUnfollow, 1);
    });

    test('getFollowingCount updates after follow and unfollow', () async {
      await followService.followUser('userA', 'userB');
      await followService.followUser('userA', 'userC');

      final afterFollow = await followService.getFollowingCount('userA').first;

      await followService.unfollowUser('userA', 'userB');

      final afterUnfollow = await followService
          .getFollowingCount('userA')
          .first;

      expect(afterFollow, 2);
      expect(afterUnfollow, 1);
    });

    test('count streams return zero for empty user id', () async {
      final followers = await followService.getFollowersCount('').first;
      final following = await followService.getFollowingCount('').first;

      expect(followers, 0);
      expect(following, 0);
    });
  });
}
