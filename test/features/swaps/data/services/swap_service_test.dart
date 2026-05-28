import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leafmark/features/books/data/services/block_service.dart';
import 'package:leafmark/features/notifications/data/services/notification_service.dart';
import 'package:leafmark/features/swaps/data/services/swap_service.dart';
import 'package:leafmark/features/swaps/domain/models/swap_request.dart';
import 'package:mocktail/mocktail.dart';

class MockBlockService extends Mock implements BlockService {}

void main() {
  late FakeFirebaseFirestore fakeDb;
  late MockBlockService mockBlockService;
  late NotificationService notificationService;
  late SwapService swapService;

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    mockBlockService = MockBlockService();
    notificationService = NotificationService(firestore: fakeDb);
    swapService = SwapService(
      firestore: fakeDb,
      blockService: mockBlockService,
      notificationService: notificationService,
    );
  });

  SwapRequest makeSwap({
    String id = 'swap1',
    String requesterId = 'userA',
    String ownerId = 'userB',
    String bookOfferedId = 'book1',
    String bookWantedId = 'book2',
    SwapStatus status = SwapStatus.pending,
    DateTime? createdAt,
  }) => SwapRequest(
    id: id,
    requesterId: requesterId,
    ownerId: ownerId,
    bookOfferedId: bookOfferedId,
    bookWantedId: bookWantedId,
    status: status,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
  );

  Future<void> createDummyBooks() async {
    await fakeDb
        .collection('users')
        .doc('userA')
        .collection('shelf')
        .doc('book1')
        .set({'lockedBySwapId': null});

    await fakeDb
        .collection('users')
        .doc('userB')
        .collection('shelf')
        .doc('book2')
        .set({'lockedBySwapId': null});
  }

  group('SwapService Unit Tests', () {
    test(
      'createSwapRequest saves request and notification to Firestore',
      () async {
        when(
          () => mockBlockService.hasBlockRelationship('userA', 'userB'),
        ).thenAnswer((_) async => false);

        await fakeDb.collection('users').doc('userA').set({
          'displayName': 'Alice',
          'profilePictureUrl': 'alice-photo',
        });

        final swapId = await swapService.createSwapRequest(makeSwap());

        final swapSnap = await fakeDb
            .collection('swap_requests')
            .doc(swapId)
            .get();

        final notificationSnap = await fakeDb
            .collection('notifications')
            .doc('swap_request_$swapId')
            .get();

        expect(swapSnap.exists, isTrue);
        expect(swapSnap['requesterId'], 'userA');
        expect(swapSnap['ownerId'], 'userB');
        expect(swapSnap['bookOfferedId'], 'book1');
        expect(swapSnap['bookWantedId'], 'book2');
        expect(swapSnap['status'], SwapStatus.pending.name);

        expect(notificationSnap.exists, isTrue);
        expect(notificationSnap['recipientId'], 'userB');
        expect(notificationSnap['senderId'], 'userA');
        expect(notificationSnap['senderDisplayName'], 'Alice');
        expect(notificationSnap['swapRequestId'], swapId);
        expect(notificationSnap['swapId'], swapId);
        expect(notificationSnap['isRead'], isFalse);
      },
    );

    test(
      'createSwapRequest throws exception when block relationship exists',
      () async {
        when(
          () => mockBlockService.hasBlockRelationship('userA', 'userB'),
        ).thenAnswer((_) async => true);

        expect(
          () => swapService.createSwapRequest(makeSwap()),
          throwsException,
        );

        final snap = await fakeDb.collection('swap_requests').get();

        expect(snap.docs, isEmpty);
      },
    );

    test(
      'createSwapRequest throws exception for duplicate pending request',
      () async {
        when(
          () => mockBlockService.hasBlockRelationship('userA', 'userB'),
        ).thenAnswer((_) async => false);

        await fakeDb
            .collection('swap_requests')
            .doc('existingSwap')
            .set(makeSwap(id: 'existingSwap').toMap());

        expect(
          () => swapService.createSwapRequest(makeSwap(id: '')),
          throwsA(isA<DuplicateSwapException>()),
        );

        final snap = await fakeDb.collection('swap_requests').get();

        expect(snap.docs.length, 1);
      },
    );

    test(
      'acceptSwapAndLockBooks accepts request and locks both books',
      () async {
        final swap = makeSwap();

        await fakeDb.collection('swap_requests').doc(swap.id).set(swap.toMap());
        await createDummyBooks();

        await swapService.acceptSwapAndLockBooks(swap);

        final swapSnap = await fakeDb
            .collection('swap_requests')
            .doc('swap1')
            .get();

        final offeredBookSnap = await fakeDb
            .collection('users')
            .doc('userA')
            .collection('shelf')
            .doc('book1')
            .get();

        final wantedBookSnap = await fakeDb
            .collection('users')
            .doc('userB')
            .collection('shelf')
            .doc('book2')
            .get();

        final notificationSnap = await fakeDb
            .collection('notifications')
            .doc('swap_accepted_swap1')
            .get();

        expect(swapSnap['status'], SwapStatus.accepted.name);
        expect(offeredBookSnap['lockedBySwapId'], 'swap1');
        expect(wantedBookSnap['lockedBySwapId'], 'swap1');
        expect(notificationSnap.exists, isTrue);
        expect(notificationSnap['recipientId'], 'userA');
        expect(notificationSnap['senderId'], 'userB');
        expect(notificationSnap['swapId'], 'swap1');
      },
    );

    test(
      'acceptSwapAndLockBooks rejects conflicting pending requests',
      () async {
        final acceptedSwap = makeSwap();
        final conflictingSwap = makeSwap(
          id: 'swap2',
          requesterId: 'userC',
          bookOfferedId: 'book3',
          bookWantedId: 'book1',
        );

        await fakeDb
            .collection('swap_requests')
            .doc(acceptedSwap.id)
            .set(acceptedSwap.toMap());

        await fakeDb
            .collection('swap_requests')
            .doc(conflictingSwap.id)
            .set(conflictingSwap.toMap());

        await createDummyBooks();

        await swapService.acceptSwapAndLockBooks(acceptedSwap);

        final acceptedSnap = await fakeDb
            .collection('swap_requests')
            .doc('swap1')
            .get();

        final rejectedSnap = await fakeDb
            .collection('swap_requests')
            .doc('swap2')
            .get();

        expect(acceptedSnap['status'], SwapStatus.accepted.name);
        expect(rejectedSnap['status'], SwapStatus.rejected.name);
      },
    );

    test(
      'updateStatus rejects pending request and creates notification',
      () async {
        final swap = makeSwap();

        await fakeDb.collection('swap_requests').doc(swap.id).set(swap.toMap());

        await swapService.updateStatus('swap1', SwapStatus.rejected);

        final swapSnap = await fakeDb
            .collection('swap_requests')
            .doc('swap1')
            .get();

        final notificationSnap = await fakeDb
            .collection('notifications')
            .doc('swap_rejected_swap1')
            .get();

        expect(swapSnap['status'], SwapStatus.rejected.name);
        expect(notificationSnap.exists, isTrue);
        expect(notificationSnap['recipientId'], 'userA');
        expect(notificationSnap['senderId'], 'userB');
        expect(notificationSnap['swapRequestId'], 'swap1');
        expect(notificationSnap['swapId'], 'swap1');
      },
    );

    test('incomingRequests returns requests owned by user', () async {
      await fakeDb
          .collection('swap_requests')
          .doc('swap1')
          .set(makeSwap().toMap());

      await fakeDb
          .collection('swap_requests')
          .doc('swap2')
          .set(makeSwap(id: 'swap2', ownerId: 'userC').toMap());

      final requests = await swapService.incomingRequests('userB').first;

      expect(requests.length, 1);
      expect(requests.first.id, 'swap1');
      expect(requests.first.ownerId, 'userB');
    });

    test('outgoingRequests returns requests created by user', () async {
      await fakeDb
          .collection('swap_requests')
          .doc('swap1')
          .set(makeSwap().toMap());

      await fakeDb
          .collection('swap_requests')
          .doc('swap2')
          .set(makeSwap(id: 'swap2', requesterId: 'userC').toMap());

      final requests = await swapService.outgoingRequests('userA').first;

      expect(requests.length, 1);
      expect(requests.first.id, 'swap1');
      expect(requests.first.requesterId, 'userA');
    });
  });
}
