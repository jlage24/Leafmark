import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leafmark/features/swaps/data/services/swap_service.dart';
import 'package:leafmark/features/swaps/domain/models/swap_request.dart';
import 'package:leafmark/features/notifications/data/services/notification_service.dart';
import 'package:leafmark/features/books/data/services/block_service.dart';

// Create fake dummy services
class FakeNotificationService extends NotificationService {
  FakeNotificationService(FirebaseFirestore firestore) : super(firestore: firestore);

  @override
  Future<void> createNotification(dynamic notification,
      {String? notificationId}) async {
    // Do nothing for the test
  }
}

class FakeBlockService extends BlockService {
  FakeBlockService(FirebaseFirestore firestore) : super(firestore: firestore);

  @override
  Future<bool> hasBlockRelationship(String uid1, String uid2) async {
    return false;
  }
}

void main() {
  group('Swap Cancellation Integration Test', () {
    late FakeFirebaseFirestore fakeFirestore;
    late SwapService swapService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      swapService = SwapService(
        firestore: fakeFirestore,
        blockService: FakeBlockService(fakeFirestore),
        notificationService: FakeNotificationService(fakeFirestore),
      );
    });

    test('Accepting a swap automatically cancels other swaps involving the same books',
        () async {
      // 1. Seed the Fake Firestore with data
      const userA = 'user_a_id';
      const userB = 'user_b_id';
      const userC = 'user_c_id';

      const bookA = 'book_a_id';
      const bookB = 'book_b_id';
      const bookC = 'book_c_id';

      // Setup User A's shelf
      await fakeFirestore
          .collection('users')
          .doc(userA)
          .collection('shelf')
          .doc(bookA)
          .set({'title': 'Book A', 'ownerId': userA});

      // Setup User B's shelf
      await fakeFirestore
          .collection('users')
          .doc(userB)
          .collection('shelf')
          .doc(bookB)
          .set({'title': 'Book B', 'ownerId': userB});

      // Setup User C's shelf
      await fakeFirestore
          .collection('users')
          .doc(userC)
          .collection('shelf')
          .doc(bookC)
          .set({'title': 'Book C', 'ownerId': userC});

      // Add user info
      await fakeFirestore
          .collection('users')
          .doc(userA)
          .set({'displayName': 'User A', 'profilePictureUrl': ''});
      await fakeFirestore
          .collection('users')
          .doc(userB)
          .set({'displayName': 'User B', 'profilePictureUrl': ''});

      // Swap 1: User A wants Book B (Owner: User B), offers Book A
      final swap1 = SwapRequest(
        id: 'swap_1',
        requesterId: userA,
        ownerId: userB,
        bookWantedId: bookB,
        bookOfferedId: bookA,
        status: SwapStatus.pending,
        createdAt: DateTime.now(),
      );

      // Swap 2: User A wants Book C (Owner: User C), offers Book A
      // This conflicts with Swap 1 because User A is offering Book A again!
      final swap2 = SwapRequest(
        id: 'swap_2',
        requesterId: userA,
        ownerId: userC,
        bookWantedId: bookC,
        bookOfferedId: bookA,
        status: SwapStatus.pending,
        createdAt: DateTime.now(),
      );

      await fakeFirestore
          .collection('swap_requests')
          .doc(swap1.id)
          .set(swap1.toMap());

      await fakeFirestore
          .collection('swap_requests')
          .doc(swap2.id)
          .set(swap2.toMap());

      await fakeFirestore
          .collection('chats')
          .doc(swap1.id)
          .set({'status': 'pending'});

      await fakeFirestore
          .collection('chats')
          .doc(swap2.id)
          .set({'status': 'pending'});

      // 2. Execute business logic: User B accepts Swap 1
      await swapService.acceptSwapAndLockBooks(
        swap1,
        acceptedByUid: userB,
      );

      // 3. Assertions
      final snap1 = await fakeFirestore.collection('swap_requests').doc(swap1.id).get();
      final snap2 = await fakeFirestore.collection('swap_requests').doc(swap2.id).get();

      // Swap 1 should be accepted
      expect(snap1.data()!['status'], equals(SwapStatus.accepted.name));

      // Swap 2 should be cancelled due to the conflict
      expect(snap2.data()!['status'], equals(SwapStatus.cancelled.name));

      // Chat 2 should be updated with a cancellation message
      final chat2Snap = await fakeFirestore.collection('chats').doc(swap2.id).get();
      expect(chat2Snap.data()!['status'], equals('cancelled'));
      expect(
        chat2Snap.data()!['lastMessage'],
        equals('Swap automatically cancelled because a book became unavailable.'),
      );

      // Books should be locked
      final bookASnap = await fakeFirestore
          .collection('users')
          .doc(userA)
          .collection('shelf')
          .doc(bookA)
          .get();
      
      expect(bookASnap.data()!['lockedBySwapId'], equals(swap1.id));
    });
  });
}
