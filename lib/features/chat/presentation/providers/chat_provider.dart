import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/services/chat_service.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/chat_metadata.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _service;
  final AuthProvider _auth;

  final Map<String, Timer> _typingTimers = {};

  ChatProvider({ChatService? service, required AuthProvider auth})
      : _service = service ?? ChatService(),
        _auth = auth;

  String get _uid => _auth.user?.uid ?? '';

  // ── Messages ──────────────────────────────────────────────────────────────

  Stream<List<ChatMessage>> getMessages(String swapId) =>
      _service.getMessages(swapId);

  Stream<List<ChatMetadata>> getChats() => _service.getChats(_uid);

  Stream<ChatMetadata?> chatStream(String swapId) =>
      _service.chatStream(swapId);

  Future<void> createChat({
    required String swapId,
    required List<String> participantIds,
  }) =>
      _service.createChat(swapId: swapId, participantIds: participantIds);

  Future<void> sendText({
    required String swapId,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;
    await stopTyping(swapId);
    final message = ChatMessage(
      id: '',
      senderId: _uid,
      type: MessageType.text,
      text: text.trim(),
      createdAt: DateTime.now(),
    );
    await _service.sendMessage(swapId: swapId, message: message);
  }

  Future<void> sendProposal({
    required String swapId,
    required String bookOfferedId,
    required String bookOfferedOwnerId,
    required String bookWantedId,
  }) =>
      _service.sendProposal(
        swapId: swapId,
        senderId: _uid,
        bookOfferedId: bookOfferedId,
        bookOfferedOwnerId: bookOfferedOwnerId,
        bookWantedId: bookWantedId,
      );

  Future<void> sendCounterOffer({
    required String swapId,
    required String bookOfferedId,
    required String bookOfferedOwnerId,
    required String bookWantedId,
  }) =>
      _service.sendCounterOffer(
        swapId: swapId,
        senderId: _uid,
        bookOfferedId: bookOfferedId,
        bookOfferedOwnerId: bookOfferedOwnerId,
        bookWantedId: bookWantedId,
      );

  Future<void> updateChatStatus(String swapId, ChatStatus status) =>
      _service.updateChatStatus(swapId, status);

  Future<Map<String, String?>> fetchUserInfo(String uid) =>
      _service.fetchUserInfo(uid);

  Future<String?> fetchDisplayName(String uid) =>
      _service.fetchDisplayName(uid);

  // ── Typing indicator ──────────────────────────────────────────────────────

  Future<void> onTyping(String swapId) async {
    _typingTimers[swapId]?.cancel();
    await _service.setTyping(swapId, _uid, true);
    _typingTimers[swapId] = Timer(const Duration(seconds: 3), () {
      _service.setTyping(swapId, _uid, false);
      _typingTimers.remove(swapId);
    });
  }

  Future<void> stopTyping(String swapId) async {
    _typingTimers[swapId]?.cancel();
    _typingTimers.remove(swapId);
    await _service.setTyping(swapId, _uid, false);
  }

  Stream<List<String>> typingStream(String swapId) {
    return _service.typingStream(swapId).map(
          (uids) => uids.where((uid) => uid != _uid).toList(),
    );
  }

  // ── Read receipts ─────────────────────────────────────────────────────────

  Future<void> markRead(String swapId) => _service.markRead(swapId, _uid);

  Stream<Map<String, DateTime>> lastReadStream(String swapId) =>
      _service.lastReadStream(swapId);

  @override
  void dispose() {
    for (final timer in _typingTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }
}