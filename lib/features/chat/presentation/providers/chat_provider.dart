import 'package:flutter/foundation.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/services/chat_service.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/chat_metadata.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _service;
  final AuthProvider _auth;

  ChatProvider({ChatService? service, required AuthProvider auth})
      : _service = service ?? ChatService(),
        _auth = auth;

  String get _uid => _auth.user?.uid ?? '';

  Stream<List<ChatMessage>> getMessages(String swapId) =>
      _service.getMessages(swapId);

  Stream<List<ChatMetadata>> getChats() =>
      _service.getChats(_uid);

  Future<void> createChat({
    required String swapId,
    required List<String> participantIds,
  }) =>
      _service.createChat(swapId: swapId, participantIds: participantIds);

  Future<void> sendText({
    required String swapId,
    required String text,
  }) async {
    final message = ChatMessage(
      id: '',
      senderId: _uid,
      type: MessageType.text,
      text: text,
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

  Future<String?> fetchDisplayName(String uid) =>
      _service.fetchDisplayName(uid);
}