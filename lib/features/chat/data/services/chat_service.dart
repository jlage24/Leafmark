import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/chat_metadata.dart';

class BookAlreadyLockedException implements Exception {
  final String bookId;
  const BookAlreadyLockedException(this.bookId);
}

class ChatService {
  final FirebaseFirestore _db;

  ChatService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _chats => _db.collection('chats');

  Future<void> createChat({
    required String swapId,
    required List<String> participantIds,
  }) async {
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
    final batch = _db.batch();

    final messageRef = _chats.doc(swapId).collection('messages').doc();
    batch.set(messageRef, message.toMap());

    final chatRef = _chats.doc(swapId);
    batch.update(chatRef, {
      'lastMessage': message.text ?? _lastMessagePreview(message.type),
      'lastMessageAt': Timestamp.fromDate(message.createdAt),
    });

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
        {'lockedBySwapId': FieldValue.delete()},
      );
    }

    final wantedSnap = await _db
        .collection('users/$bookWantedOwnerId/shelf')
        .doc(bookWantedId)
        .get();
    if (wantedSnap.data()?['lockedBySwapId'] == swapId) {
      batch.update(
        _db.collection('users/$bookWantedOwnerId/shelf').doc(bookWantedId),
        {'lockedBySwapId': FieldValue.delete()},
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
    return _chats
        .where('participantIds', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) =>
        ChatMetadata.fromMap(doc.data() as Map<String, dynamic>))
        .toList());
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
}