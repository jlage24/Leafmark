import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/chat_metadata.dart';

class ChatService {
  final FirebaseFirestore _db;

  ChatService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _chats => _db.collection('chats');

  Future<void> createChat({
    required String swapId,
    required List<String> participantIds,
  }) async {
    final metadata = ChatMetadata(
      swapId: swapId,
      participantIds: participantIds,
      status: ChatStatus.active,
    );
    await _chats.doc(swapId).set(metadata.toMap());
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

  Stream<List<ChatMessage>> getMessages(String swapId) {
    return _chats
        .doc(swapId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
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
        .map((doc) => ChatMetadata.fromMap(doc.data() as Map<String, dynamic>))
        .toList());
  }

  Future<void> updateChatStatus(String swapId, ChatStatus status) async {
    await _chats.doc(swapId).update({'status': status.name});
  }

  String _lastMessagePreview(MessageType type) {
    switch (type) {
      case MessageType.proposal: return '📚 Swap proposal';
      case MessageType.counterOffer: return '🔄 Counter offer';
      case MessageType.text: return '';
    }
  }

  Future<String?> fetchDisplayName(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return doc.data()?['displayName'] as String?;
    } catch (_) {
      return null;
    }
  }
}