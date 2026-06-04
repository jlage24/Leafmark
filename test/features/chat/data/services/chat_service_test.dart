import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leafmark/features/books/data/services/block_service.dart';
import 'package:leafmark/features/chat/data/services/chat_service.dart';
import 'package:leafmark/features/chat/domain/models/chat_message.dart';
import 'package:leafmark/features/chat/domain/models/chat_metadata.dart';
import 'package:leafmark/features/notifications/data/services/notification_service.dart';
import 'package:mocktail/mocktail.dart';

class MockBlockService extends Mock implements BlockService {}

void main() {
  late FakeFirebaseFirestore fakeDb;
  late MockBlockService mockBlockService;
  late NotificationService notificationService;
  late ChatService chatService;

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    mockBlockService = MockBlockService();
    notificationService = NotificationService(firestore: fakeDb);
    chatService = ChatService(
      firestore: fakeDb,
      blockService: mockBlockService,
      notificationService: notificationService,
    );
  });

  Future<void> createDummyChat() async {
    await fakeDb.collection('chats').doc('swap1').set({
      'swapId': 'swap1',
      'participantIds': ['userA', 'userB'],
      'status': ChatStatus.active.name,
      'lastMessage': '',
      'lastMessageAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
    });
  }

  Future<void> createLockedBooks() async {
    await fakeDb
        .collection('users')
        .doc('userA')
        .collection('shelf')
        .doc('book1')
        .set({'lockedBySwapId': 'swap1'});

    await fakeDb
        .collection('users')
        .doc('userB')
        .collection('shelf')
        .doc('book2')
        .set({'lockedBySwapId': 'swap1'});
  }

  Future<void> createUser(String uid, String displayName) async {
    await fakeDb.collection('users').doc(uid).set({
      'displayName': displayName,
      'profilePictureUrl': '$uid-photo',
    });
  }

  ChatMessage makeMessage() => ChatMessage(
    id: '',
    senderId: 'userA',
    text: 'Hello!',
    type: MessageType.text,
    createdAt: DateTime(2026, 1, 2),
  );

  group('ChatService Unit Tests', () {
    test('createChat saves metadata to Firestore', () async {
      when(
        () => mockBlockService.hasBlockRelationship('userA', 'userB'),
      ).thenAnswer((_) async => false);

      await chatService.createChat(
        swapId: 'swap1',
        participantIds: ['userA', 'userB'],
      );

      final snap = await fakeDb.collection('chats').doc('swap1').get();

      expect(snap.exists, isTrue);
      expect(snap['swapId'], 'swap1');
      expect(snap['participantIds'], ['userA', 'userB']);
      expect(snap['status'], ChatStatus.active.name);
      expect(snap['lastMessage'], '📚 Swap proposal');
      expect(snap['lastMessageAt'], isA<Timestamp>());
    });

    test('createChat uses swap id as deterministic chat id', () async {
      when(
        () => mockBlockService.hasBlockRelationship('userA', 'userB'),
      ).thenAnswer((_) async => false);

      await chatService.createChat(
        swapId: 'swap1',
        participantIds: ['userA', 'userB'],
      );

      await chatService.createChat(
        swapId: 'swap1',
        participantIds: ['userA', 'userB'],
      );

      final snap = await fakeDb.collection('chats').get();

      expect(snap.docs.length, 1);
      expect(snap.docs.first.id, 'swap1');
    });

    test(
      'createChat throws exception when block relationship exists',
      () async {
        when(
          () => mockBlockService.hasBlockRelationship('userA', 'userB'),
        ).thenAnswer((_) async => true);

        await expectLater(
          chatService.createChat(
            swapId: 'swap1',
            participantIds: ['userA', 'userB'],
          ),
          throwsException,
        );

        final snap = await fakeDb.collection('chats').get();

        expect(snap.docs, isEmpty);
      },
    );

    test('sendMessage saves message to Firestore', () async {
      when(
        () => mockBlockService.hasBlockRelationship('userA', 'userB'),
      ).thenAnswer((_) async => false);

      await createDummyChat();

      await chatService.sendMessage(swapId: 'swap1', message: makeMessage());

      final snap = await fakeDb
          .collection('chats')
          .doc('swap1')
          .collection('messages')
          .get();

      expect(snap.docs.length, 1);
      expect(snap.docs.first['text'], 'Hello!');
      expect(snap.docs.first['senderId'], 'userA');
      expect(snap.docs.first['type'], MessageType.text.name);
    });

    test('sendMessage updates chat last message', () async {
      when(
        () => mockBlockService.hasBlockRelationship('userA', 'userB'),
      ).thenAnswer((_) async => false);

      await createDummyChat();

      await chatService.sendMessage(swapId: 'swap1', message: makeMessage());

      final snap = await fakeDb.collection('chats').doc('swap1').get();

      expect(snap['lastMessage'], 'Hello!');
      expect(
        (snap['lastMessageAt'] as Timestamp).toDate(),
        DateTime(2026, 1, 2),
      );
    });

    test('sendMessage creates notification for recipient', () async {
      when(
        () => mockBlockService.hasBlockRelationship('userA', 'userB'),
      ).thenAnswer((_) async => false);

      await createDummyChat();
      await createUser('userA', 'Alice');

      await chatService.sendMessage(swapId: 'swap1', message: makeMessage());

      final snap = await fakeDb.collection('notifications').get();

      expect(snap.docs.length, 1);
      expect(snap.docs.first['recipientId'], 'userB');
      expect(snap.docs.first['senderId'], 'userA');
      expect(snap.docs.first['senderDisplayName'], 'Alice');
      expect(snap.docs.first['senderPhotoUrl'], 'userA-photo');
      expect(snap.docs.first['title'], 'New message');
      expect(snap.docs.first['body'], 'Alice: Hello!');
      expect(snap.docs.first['chatId'], 'swap1');
      expect(snap.docs.first['swapId'], 'swap1');
      expect(snap.docs.first['isRead'], isFalse);
    });

    test('sendMessage throws exception when chat does not exist', () async {
      await expectLater(
        chatService.sendMessage(swapId: 'missingChat', message: makeMessage()),
        throwsException,
      );

      final messagesSnap = await fakeDb
          .collection('chats')
          .doc('missingChat')
          .collection('messages')
          .get();

      final notificationsSnap = await fakeDb.collection('notifications').get();

      expect(messagesSnap.docs, isEmpty);
      expect(notificationsSnap.docs, isEmpty);
    });

    test(
      'sendMessage throws exception when block relationship exists without writing data',
      () async {
        when(
          () => mockBlockService.hasBlockRelationship('userA', 'userB'),
        ).thenAnswer((_) async => true);

        await createDummyChat();

        await expectLater(
          chatService.sendMessage(swapId: 'swap1', message: makeMessage()),
          throwsException,
        );

        final messagesSnap = await fakeDb
            .collection('chats')
            .doc('swap1')
            .collection('messages')
            .get();

        final chatSnap = await fakeDb.collection('chats').doc('swap1').get();
        final notificationsSnap = await fakeDb
            .collection('notifications')
            .get();

        expect(messagesSnap.docs, isEmpty);
        expect(chatSnap['lastMessage'], '');
        expect(notificationsSnap.docs, isEmpty);
      },
    );

    test('sendProposal stores proposal message', () async {
      when(
        () => mockBlockService.hasBlockRelationship('userA', 'userB'),
      ).thenAnswer((_) async => false);

      await createDummyChat();

      await chatService.sendProposal(
        swapId: 'swap1',
        senderId: 'userA',
        bookOfferedId: 'book1',
        bookOfferedOwnerId: 'userA',
        bookWantedId: 'book2',
      );

      final snap = await fakeDb
          .collection('chats')
          .doc('swap1')
          .collection('messages')
          .get();

      expect(snap.docs.length, 1);
      expect(snap.docs.first['type'], MessageType.proposal.name);
      expect(snap.docs.first['senderId'], 'userA');
      expect(snap.docs.first['bookOfferedId'], 'book1');
      expect(snap.docs.first['bookOfferedOwnerId'], 'userA');
      expect(snap.docs.first['bookWantedId'], 'book2');

      final chatSnap = await fakeDb.collection('chats').doc('swap1').get();

      expect(chatSnap['lastMessage'], '📚 Swap proposal');
      expect(chatSnap['lastMessageAt'], isA<Timestamp>());
    });

    test('sendProposal creates notification for recipient', () async {
      when(
        () => mockBlockService.hasBlockRelationship('userA', 'userB'),
      ).thenAnswer((_) async => false);

      await createDummyChat();
      await createUser('userA', 'Alice');

      await chatService.sendProposal(
        swapId: 'swap1',
        senderId: 'userA',
        bookOfferedId: 'book1',
        bookOfferedOwnerId: 'userA',
        bookWantedId: 'book2',
      );

      final snap = await fakeDb.collection('notifications').get();

      expect(snap.docs.length, 1);
      expect(snap.docs.first['recipientId'], 'userB');
      expect(snap.docs.first['senderId'], 'userA');
      expect(snap.docs.first['senderDisplayName'], 'Alice');
      expect(snap.docs.first['title'], 'New swap proposal');
      expect(snap.docs.first['body'], 'Alice sent you a swap proposal.');
      expect(snap.docs.first['chatId'], 'swap1');
      expect(snap.docs.first['swapId'], 'swap1');
      expect(snap.docs.first['isRead'], isFalse);
    });

    test('sendCounterOffer stores counter offer message', () async {
      when(
        () => mockBlockService.hasBlockRelationship('userA', 'userB'),
      ).thenAnswer((_) async => false);

      await createDummyChat();

      await chatService.sendCounterOffer(
        swapId: 'swap1',
        senderId: 'userB',
        bookOfferedId: 'book2',
        bookOfferedOwnerId: 'userB',
        bookWantedId: 'book1',
      );

      final snap = await fakeDb
          .collection('chats')
          .doc('swap1')
          .collection('messages')
          .get();

      expect(snap.docs.length, 1);
      expect(snap.docs.first['type'], MessageType.counterOffer.name);
      expect(snap.docs.first['senderId'], 'userB');
      expect(snap.docs.first['bookOfferedId'], 'book2');
      expect(snap.docs.first['bookOfferedOwnerId'], 'userB');
      expect(snap.docs.first['bookWantedId'], 'book1');

      final chatSnap = await fakeDb.collection('chats').doc('swap1').get();

      expect(chatSnap['lastMessage'], '🔄 Counter offer');
      expect(chatSnap['lastMessageAt'], isA<Timestamp>());
    });

    test('sendCounterOffer creates notification for recipient', () async {
      when(
        () => mockBlockService.hasBlockRelationship('userA', 'userB'),
      ).thenAnswer((_) async => false);

      await createDummyChat();
      await createUser('userB', 'Bob');

      await chatService.sendCounterOffer(
        swapId: 'swap1',
        senderId: 'userB',
        bookOfferedId: 'book2',
        bookOfferedOwnerId: 'userB',
        bookWantedId: 'book1',
      );

      final snap = await fakeDb.collection('notifications').get();

      expect(snap.docs.length, 1);
      expect(snap.docs.first['recipientId'], 'userA');
      expect(snap.docs.first['senderId'], 'userB');
      expect(snap.docs.first['senderDisplayName'], 'Bob');
      expect(snap.docs.first['title'], 'New counter-offer');
      expect(snap.docs.first['body'], 'Bob sent you a counter-offer.');
      expect(snap.docs.first['chatId'], 'swap1');
      expect(snap.docs.first['swapId'], 'swap1');
      expect(snap.docs.first['isRead'], isFalse);
    });

    test('acceptSwap updates chat status to completed', () async {
      await createDummyChat();

      await chatService.acceptSwap(swapId: 'swap1');

      final snap = await fakeDb.collection('chats').doc('swap1').get();

      expect(snap['status'], ChatStatus.completed.name);
    });

    test('cancelSwap updates status and unlocks both books', () async {
      await createDummyChat();
      await createLockedBooks();

      await chatService.cancelSwap(
        swapId: 'swap1',
        bookOfferedId: 'book1',
        bookOfferedOwnerId: 'userA',
        bookWantedId: 'book2',
        bookWantedOwnerId: 'userB',
      );

      final chatSnap = await fakeDb.collection('chats').doc('swap1').get();

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

      expect(chatSnap['status'], ChatStatus.cancelled.name);
      expect(offeredBookSnap['lockedBySwapId'], isNull);
      expect(wantedBookSnap['lockedBySwapId'], isNull);
    });

    test('deleteChat adds user to hiddenBy array', () async {
      await createDummyChat();

      await chatService.deleteChat('swap1', 'userA');

      final snap = await fakeDb.collection('chats').doc('swap1').get();
      expect(snap.exists, isTrue);
      expect(snap['hiddenBy'], contains('userA'));
      expect(snap['hiddenBy'], isNot(contains('userB')));
    });

    test('deleteChat completely deletes chat when all participants hide it', () async {
      await createDummyChat();
      
      // Add a dummy message to test subcollection deletion
      await fakeDb.collection('chats').doc('swap1').collection('messages').doc('msg1').set({'text': 'hi'});

      await chatService.deleteChat('swap1', 'userA');
      await chatService.deleteChat('swap1', 'userB');

      final snap = await fakeDb.collection('chats').doc('swap1').get();
      final msgSnap = await fakeDb.collection('chats').doc('swap1').collection('messages').get();

      expect(snap.exists, isFalse);
      expect(msgSnap.docs, isEmpty);
    });

    test('getChats filters out chats hidden by the user', () async {
      when(() => mockBlockService.getBlockedUsersStream(any()))
          .thenAnswer((_) => Stream.value([]));

      await createDummyChat();
      
      // Hidden by userA
      await chatService.deleteChat('swap1', 'userA');
      
      final stream = chatService.getChats('userA');
      final stream2 = chatService.getChats('userB');

      final list1 = await stream.first;
      final list2 = await stream2.first;

      expect(list1, isEmpty);
      expect(list2.length, 1);
      expect(list2.first.swapId, 'swap1');
    });

    test('sendMessage clears hiddenBy array', () async {
      when(
        () => mockBlockService.hasBlockRelationship('userA', 'userB'),
      ).thenAnswer((_) async => false);

      await createDummyChat();
      await chatService.deleteChat('swap1', 'userA');

      var snap = await fakeDb.collection('chats').doc('swap1').get();
      expect(snap['hiddenBy'], contains('userA'));

      await chatService.sendMessage(swapId: 'swap1', message: makeMessage());

      snap = await fakeDb.collection('chats').doc('swap1').get();
      expect(snap['hiddenBy'], isEmpty);
    });
  });
}
