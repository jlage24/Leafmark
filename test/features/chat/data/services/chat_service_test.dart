import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leafmark/features/books/data/services/block_service.dart';
import 'package:leafmark/features/chat/data/services/chat_service.dart';
import 'package:leafmark/features/chat/domain/models/chat_message.dart';
import 'package:leafmark/features/chat/domain/models/chat_metadata.dart';
import 'package:mocktail/mocktail.dart';

class MockBlockService extends Mock implements BlockService {}

void main() {
  late FakeFirebaseFirestore fakeDb;
  late MockBlockService mockBlockService;
  late ChatService chatService;

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    mockBlockService = MockBlockService();
    chatService = ChatService(
      firestore: fakeDb,
      blockService: mockBlockService,
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

    test(
      'createChat throws exception when block relationship exists',
      () async {
        when(
          () => mockBlockService.hasBlockRelationship('userA', 'userB'),
        ).thenAnswer((_) async => true);

        expect(
          () => chatService.createChat(
            swapId: 'swap1',
            participantIds: ['userA', 'userB'],
          ),
          throwsException,
        );
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
      expect(snap.docs.first['bookOfferedId'], 'book1');
      expect(snap.docs.first['bookOfferedOwnerId'], 'userA');
      expect(snap.docs.first['bookWantedId'], 'book2');

      final chatSnap = await fakeDb.collection('chats').doc('swap1').get();
      expect(chatSnap['lastMessage'], '📚 Swap proposal');
    });

    test('acceptSwap updates chat status to completed', () async {
      await createDummyChat();

      await chatService.acceptSwap(swapId: 'swap1');

      final snap = await fakeDb.collection('chats').doc('swap1').get();

      expect(snap['status'], ChatStatus.completed.name);
    });
  });
}
