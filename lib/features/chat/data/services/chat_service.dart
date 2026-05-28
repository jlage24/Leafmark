import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/chat_metadata.dart';
import 'package:rxdart/rxdart.dart';
import '../../../books/data/services/block_service.dart';
import '../../../notifications/data/services/notification_service.dart';
import '../../../notifications/domain/models/app_notification.dart';


class BookAlreadyLockedException implements Exception {
  final String bookId;
  const BookAlreadyLockedException(this.bookId);
}

/// NOTE: Block enforcement is currently handled Client-Side. 
/// While we validate blocks before writing to Firestore, malicious users 
/// could bypass Dart services. Full Server-Side enforcement would require 
/// custom Cloud Functions or cross-collection Firestore rules. 
/// Accepted as prototype-level protection.

class ChatService {
  final FirebaseFirestore _db;
  final BlockService _blockService;
  final NotificationService _notificationService;

  // Dependency Injection for Firestore and BlockService
  ChatService({
    FirebaseFirestore? firestore,
    BlockService? blockService,
    NotificationService? notificationService,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _blockService = blockService ?? BlockService(),
        _notificationService = notificationService ?? NotificationService();

  CollectionReference get _chats => _db.collection('chats');

  Future<void> createChat({
    required String swapId,
    required List<String> participantIds,
  }) async {
    // Validate block relationship before creating the chat room
    if (participantIds.length == 2) {
      final hasBlock = await _blockService.hasBlockRelationship(participantIds[0], participantIds[1]);
      if (hasBlock) {
        throw Exception('Cannot create chat. Access restricted due to a block relationship.');
      }
    }

    final docRef = _chats.doc(swapId);
    final snap = await docRef.get();
    if (snap.exists) return;

    final metadata = ChatMetadata(
      swapId: swapId,
      participantIds: participantIds,
      status: ChatStatus.active,
      lastMessage: '📚 Swap proposal',
      lastMessageAt: DateTime.now(),
    );
    await docRef.set(metadata.toMap());
  }

  Future<void> sendMessage({
    required String swapId,
    required ChatMessage message,
  }) async {
    final chatDoc = await _chats.doc(swapId).get();

    if (!chatDoc.exists) {
      throw Exception('Cannot send message. Chat does not exist.');
    }

    final chatData = chatDoc.data() as Map<String, dynamic>;
    final participants = List<String>.from(chatData['participantIds'] ?? []);

    String? recipientId;

    if (participants.length == 2) {
      final hasBlock = await _blockService.hasBlockRelationship(
        participants[0],
        participants[1],
      );

      if (hasBlock) {
        throw Exception(
          'Cannot send message. Access restricted due to a block relationship.',
        );
      }

      recipientId = participants.firstWhere(
            (uid) => uid != message.senderId,
        orElse: () => '',
      );

      if (recipientId.isEmpty) {
        recipientId = null;
      }
    }

    final batch = _db.batch();

    final chatRef = _chats.doc(swapId);
    final messageRef = chatRef.collection('messages').doc();

    batch.set(messageRef, message.toMap());

    batch.update(chatRef, {
      'lastMessage': message.text ?? _lastMessagePreview(message.type),
      'lastMessageAt': Timestamp.fromDate(message.createdAt),
    });

    if (recipientId != null) {
      final notificationId = 'chat_${swapId}_${messageRef.id}';
      final notificationRef =
      _notificationService.notificationDocument(notificationId);

      batch.set(
        notificationRef,
        AppNotification(
          id: '',
          recipientId: recipientId,
          senderId: message.senderId,
          type: _notificationTypeForMessage(message.type),
          title: _notificationTitleForMessage(message.type),
          body: _notificationBodyForMessage(message),
          chatId: swapId,
          swapId: swapId,
          isRead: false,
          createdAt: message.createdAt,
        ).toMap(),
      );
    }

    await batch.commit();
  }

  Future<void> sendProposal({
    required String swapId,
    required String senderId,
    required String bookOfferedId,
    required String bookOfferedOwnerId,
    required String bookWantedId,
  }) async {
    final message = ChatMessage(
      id: '',
      senderId: senderId,
      type: MessageType.proposal,
      bookOfferedId: bookOfferedId,
      bookOfferedOwnerId: bookOfferedOwnerId,
      bookWantedId: bookWantedId,
      createdAt: DateTime.now(),
    );
    await sendMessage(swapId: swapId, message: message);
  }

  Future<void> sendCounterOffer({
    required String swapId,
    required String senderId,
    required String bookOfferedId,
    required String bookOfferedOwnerId,
    required String bookWantedId,
  }) async {
    final message = ChatMessage(
      id: '',
      senderId: senderId,
      type: MessageType.counterOffer,
      bookOfferedId: bookOfferedId,
      bookOfferedOwnerId: bookOfferedOwnerId,
      bookWantedId: bookWantedId,
      createdAt: DateTime.now(),
    );
    await sendMessage(swapId: swapId, message: message);
  }

  Future<void> acceptSwap({required String swapId}) async {
    await _chats.doc(swapId).update({'status': ChatStatus.completed.name});
  }

  Future<void> confirmPhysicalExchange({
    required String swapId,
    required String bookOfferedId,
    required String bookOfferedOwnerId,
    required String bookWantedId,
    required String bookWantedOwnerId,
  }) async {
    final batch = _db.batch();

    batch.delete(
      _db.collection('users/$bookOfferedOwnerId/shelf').doc(bookOfferedId),
    );
    batch.delete(
      _db.collection('users/$bookWantedOwnerId/shelf').doc(bookWantedId),
    );

    batch.update(_chats.doc(swapId), {'status': 'exchanged'});

    await batch.commit();
  }

  Future<void> cancelSwap({
    required String swapId,
    required String bookOfferedId,
    required String bookOfferedOwnerId,
    required String bookWantedId,
    required String bookWantedOwnerId,
  }) async {
    final batch = _db.batch();

    batch.update(_chats.doc(swapId), {'status': ChatStatus.cancelled.name});

    final offeredSnap = await _db
        .collection('users/$bookOfferedOwnerId/shelf')
        .doc(bookOfferedId)
        .get();
    if (offeredSnap.data()?['lockedBySwapId'] == swapId) {
      batch.update(
        _db.collection('users/$bookOfferedOwnerId/shelf').doc(bookOfferedId),
        {'lockedBySwapId': null},
      );
    }

    final wantedSnap = await _db
        .collection('users/$bookWantedOwnerId/shelf')
        .doc(bookWantedId)
        .get();
    if (wantedSnap.data()?['lockedBySwapId'] == swapId) {
      batch.update(
        _db.collection('users/$bookWantedOwnerId/shelf').doc(bookWantedId),
        {'lockedBySwapId': null},
      );
    }

    await batch.commit();
  }

  Future<void> updateChatStatus(String swapId, ChatStatus status) async {
    await _chats.doc(swapId).update({'status': status.name});
  }

  Stream<List<ChatMessage>> getMessages(String swapId) {
    return _chats
        .doc(swapId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
        .toList());
  }

Stream<List<ChatMetadata>> getChats(String uid) {
    final chatsStream = _chats
        .where('participantIds', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) =>
        ChatMetadata.fromMap(doc.data() as Map<String, dynamic>))
        .toList());
        
    final blocksStream = _blockService.getBlockedUsersStream(uid).onErrorReturn(<String>[]);

    return Rx.combineLatest2(chatsStream, blocksStream, (List<ChatMetadata> chats, List<String> blockedUids) {
      return chats.where((chat) {
        final otherUid = chat.participantIds.firstWhere((id) => id != uid, orElse: () => '');
        return !blockedUids.contains(otherUid);
      }).toList();
    });
  }

  Future<Map<String, String?>> fetchUserInfo(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return {'displayName': null, 'photoUrl': null};
      final data = doc.data()!;
      return {
        'displayName': data['displayName'] as String?,
        'photoUrl': data['profilePictureUrl'] as String?,
      };
    } catch (_) {
      return {'displayName': null, 'photoUrl': null};
    }
  }

  Future<String?> fetchDisplayName(String uid) async {
    final info = await fetchUserInfo(uid);
    return info['displayName'];
  }

  String _lastMessagePreview(MessageType type) {
    switch (type) {
      case MessageType.proposal:
        return '📚 Swap proposal';
      case MessageType.counterOffer:
        return '🔄 Counter offer';
      case MessageType.text:
        return '';
    }
  }

  Future<void> setTyping(String swapId, String uid, bool isTyping) async {
    final ref = _chats.doc(swapId);
    if (isTyping) {
      await ref.update({
        'typingUids': FieldValue.arrayUnion([uid]),
      });
    } else {
      await ref.update({
        'typingUids': FieldValue.arrayRemove([uid]),
      });
    }
  }

  Stream<List<String>> typingStream(String swapId) {
    return _chats.doc(swapId).snapshots().map((snap) {
      if (!snap.exists) return [];
      final data = snap.data() as Map<String, dynamic>;
      final raw = data['typingUids'];
      if (raw == null) return <String>[];
      return List<String>.from(raw as List);
    });
  }

  Future<void> markRead(String swapId, String uid) async {
    await _chats.doc(swapId).update({
      'lastReadAt.$uid': FieldValue.serverTimestamp(),
    });
  }

  Stream<ChatMetadata?> chatStream(String swapId) {
    return _chats.doc(swapId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return ChatMetadata.fromMap(snap.data() as Map<String, dynamic>);
    });
  }

  Stream<Map<String, DateTime>> lastReadStream(String swapId) {
    return _chats.doc(swapId).snapshots().map((snap) {
      if (!snap.exists) return {};
      final data = snap.data() as Map<String, dynamic>;
      final raw = data['lastReadAt'] as Map<String, dynamic>?;
      if (raw == null) return {};
      return raw.map((k, v) => MapEntry(k, (v as Timestamp).toDate()));
    });
  }

  AppNotificationType _notificationTypeForMessage(MessageType type) {
    switch (type) {
      case MessageType.proposal:
        return AppNotificationType.proposal;
      case MessageType.counterOffer:
        return AppNotificationType.counterOffer;
      case MessageType.text:
        return AppNotificationType.chatMessage;
    }
  }

  String _notificationTitleForMessage(MessageType type) {
    switch (type) {
      case MessageType.proposal:
        return 'New swap proposal';
      case MessageType.counterOffer:
        return 'New counter-offer';
      case MessageType.text:
        return 'New message';
    }
  }

  String _notificationBodyForMessage(ChatMessage message) {
    switch (message.type) {
      case MessageType.proposal:
        return 'Someone proposed a book swap with you.';
      case MessageType.counterOffer:
        return 'Someone sent you a counter-offer.';
      case MessageType.text:
        return message.text ?? 'You received a new message.';
    }
  }
}