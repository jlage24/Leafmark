import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leafmark/features/books/data/services/block_service.dart';

void main() {
  late FakeFirebaseFirestore fakeDb;
  late BlockService blockService;

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    blockService = BlockService(firestore: fakeDb);
  });

  Future<void> createFollowRelationships() async {
    await fakeDb
        .collection('users')
        .doc('userA')
        .collection('following')
        .doc('userB')
        .set({'uid': 'userB'});

    await fakeDb
        .collection('users')
        .doc('userB')
        .collection('followers')
        .doc('userA')
        .set({'uid': 'userA'});

    await fakeDb
        .collection('users')
        .doc('userB')
        .collection('following')
        .doc('userA')
        .set({'uid': 'userA'});

    await fakeDb
        .collection('users')
        .doc('userA')
        .collection('followers')
        .doc('userB')
        .set({'uid': 'userB'});
  }

  group('BlockService Unit Tests', () {
    test('blockUser saves blocked user to Firestore', () async {
      await blockService.blockUser('userA', 'userB');

      final snap = await fakeDb
          .collection('users')
          .doc('userA')
          .collection('blocked_users')
          .doc('userB')
          .get();

      expect(snap.exists, isTrue);
      expect(snap['blockedUid'], 'userB');
      expect(snap.data()!.containsKey('blockedAt'), isTrue);
    });

    test('blockUser removes follow relationships between users', () async {
      await createFollowRelationships();

      await blockService.blockUser('userA', 'userB');

      final currentUserFollowingSnap = await fakeDb
          .collection('users')
          .doc('userA')
          .collection('following')
          .doc('userB')
          .get();

      final targetUserFollowersSnap = await fakeDb
          .collection('users')
          .doc('userB')
          .collection('followers')
          .doc('userA')
          .get();

      final targetUserFollowingSnap = await fakeDb
          .collection('users')
          .doc('userB')
          .collection('following')
          .doc('userA')
          .get();

      final currentUserFollowersSnap = await fakeDb
          .collection('users')
          .doc('userA')
          .collection('followers')
          .doc('userB')
          .get();

      expect(currentUserFollowingSnap.exists, isFalse);
      expect(targetUserFollowersSnap.exists, isFalse);
      expect(targetUserFollowingSnap.exists, isFalse);
      expect(currentUserFollowersSnap.exists, isFalse);
    });

    test('blockUser throws argument error for self block', () async {
      expect(
        () => blockService.blockUser('userA', 'userA'),
        throwsArgumentError,
      );
    });

    test('blockUser throws argument error for empty user id', () async {
      expect(() => blockService.blockUser('', 'userB'), throwsArgumentError);

      expect(() => blockService.blockUser('userA', ''), throwsArgumentError);
    });

    test('isBlocked returns true when user is blocked', () async {
      await blockService.blockUser('userA', 'userB');

      final result = await blockService.isBlocked('userA', 'userB');

      expect(result, isTrue);
    });

    test('isBlocked returns false when user is not blocked', () async {
      final result = await blockService.isBlocked('userA', 'userB');

      expect(result, isFalse);
    });

    test('unblockUser removes blocked user from Firestore', () async {
      await blockService.blockUser('userA', 'userB');

      await blockService.unblockUser('userA', 'userB');

      final result = await blockService.isBlocked('userA', 'userB');

      expect(result, isFalse);
    });

    test('getBlockedUsersStream returns blocked user ids', () async {
      await blockService.blockUser('userA', 'userB');
      await blockService.blockUser('userA', 'userC');

      final blockedUsers = await blockService
          .getBlockedUsersStream('userA')
          .first;

      expect(blockedUsers.length, 2);
      expect(blockedUsers, containsAll(['userB', 'userC']));
    });

    test(
      'getBlockedUsersStream returns empty list for empty current user id',
      () async {
        final blockedUsers = await blockService.getBlockedUsersStream('').first;

        expect(blockedUsers, isEmpty);
      },
    );

    test(
      'hasBlockRelationship returns true when first user blocked second user',
      () async {
        await blockService.blockUser('userA', 'userB');

        final result = await blockService.hasBlockRelationship(
          'userA',
          'userB',
        );

        expect(result, isTrue);
      },
    );

    test(
      'hasBlockRelationship returns true when second user blocked first user',
      () async {
        await blockService.blockUser('userB', 'userA');

        final result = await blockService.hasBlockRelationship(
          'userA',
          'userB',
        );

        expect(result, isTrue);
      },
    );

    test(
      'hasBlockRelationship returns false when neither user blocked the other',
      () async {
        final result = await blockService.hasBlockRelationship(
          'userA',
          'userB',
        );

        expect(result, isFalse);
      },
    );
  });
}
