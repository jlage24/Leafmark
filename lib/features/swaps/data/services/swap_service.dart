import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import '../../domain/models/swap_request.dart';
import '../../../books/data/services/block_service.dart';


class DuplicateSwapException implements Exception {}

class SwapService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'swap_requests';

  Future<String> createSwapRequest(SwapRequest request) async {
    final hasBlock = await BlockService().hasBlockRelationship(request.requesterId, request.ownerId);
    if (hasBlock) {
      throw Exception('Cannot create request. Access restricted due to block.');
    }

    return await _db.runTransaction<String>((transaction) async {
      final query = await _db.collection(_collection)
          .where('bookWantedId', isEqualTo: request.bookWantedId)
          .where('requesterId', isEqualTo: request.requesterId)
          .where('status', isEqualTo: SwapStatus.pending.name)
          .get();

      if (query.docs.isNotEmpty) {
        throw DuplicateSwapException();
      }

      final docRef = _db.collection(_collection).doc();
      transaction.set(docRef, request.toMap());
      return docRef.id;
    });
  }

  Future<void> acceptSwapAndLockBooks(SwapRequest swap) async {
    final batch = _db.batch();

    final swapRef = _db.collection(_collection).doc(swap.id);
    batch.update(swapRef, {'status': SwapStatus.accepted.name});

    final offeredBookRef = _db.collection('users/${swap.requesterId}/shelf').doc(swap.bookOfferedId);
    final wantedBookRef = _db.collection('users/${swap.ownerId}/shelf').doc(swap.bookWantedId);

    batch.update(offeredBookRef, {'lockedBySwapId': swap.id});
    batch.update(wantedBookRef, {'lockedBySwapId': swap.id});

    final otherRequests = await _db.collection(_collection)
        .where('status', isEqualTo: SwapStatus.pending.name)
        .get();

    for (var doc in otherRequests.docs) {
      if (doc.id == swap.id) continue;

      final data = doc.data();
      final conflictsWithWanted = data['bookWantedId'] == swap.bookWantedId || data['bookOfferedId'] == swap.bookWantedId;
      final conflictsWithOffered = data['bookWantedId'] == swap.bookOfferedId || data['bookOfferedId'] == swap.bookOfferedId;

      if (conflictsWithWanted || conflictsWithOffered) {
        batch.update(doc.reference, {'status': SwapStatus.rejected.name});
      }
    }

    await batch.commit();
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

  Stream<List<SwapRequest>> exchangeHistory(String uid) {
    final asRequester = _db
        .collection(_collection)
        .where('requesterId', isEqualTo: uid)
        .where('status', isEqualTo: SwapStatus.accepted.name)
        .snapshots()
        .map((s) => s.docs
        .map((d) => SwapRequest.fromMap(d.data(), d.id))
        .toList());

    final asOwner = _db
        .collection(_collection)
        .where('ownerId', isEqualTo: uid)
        .where('status', isEqualTo: SwapStatus.accepted.name)
        .snapshots()
        .map((s) => s.docs
        .map((d) => SwapRequest.fromMap(d.data(), d.id))
        .toList());

    return Rx.combineLatest2(asRequester, asOwner, (a, b) {
      final merged = [...a, ...b];
      merged.sort((x, y) => y.createdAt.compareTo(x.createdAt));
      return merged;
    });
  }
}