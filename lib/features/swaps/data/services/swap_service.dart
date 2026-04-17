import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/swap_request.dart';

class SwapService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'swap_requests';

  Future<void> createSwapRequest(SwapRequest request) async {
    // Verificar se já existe um pedido pendente para o mesmo livro pelo mesmo user
    final existing = await _db
        .collection(_collection)
        .where('requesterId', isEqualTo: request.requesterId)
        .where('bookWantedId', isEqualTo: request.bookWantedId)
        .where('status', isEqualTo: SwapStatus.pending.name)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('Já enviaste um pedido para este livro.');
    }

    await _db.collection(_collection).add(request.toMap());
  }

  Future<void> updateStatus(String id, SwapStatus status) async {
    await _db.collection(_collection).doc(id).update({'status': status.name});
  }

  Future<void> deleteRequest(String id) async {
    await _db.collection(_collection).doc(id).delete();
  }

  Stream<List<SwapRequest>> incomingRequests(String uid) {
    return _db
        .collection(_collection)
        .where('ownerId', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => SwapRequest.fromMap(doc.data(), doc.id))
        .toList());
  }

  Stream<List<SwapRequest>> outgoingRequests(String uid) {
    return _db
        .collection(_collection)
        .where('requesterId', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => SwapRequest.fromMap(doc.data(), doc.id))
        .toList());
  }
}