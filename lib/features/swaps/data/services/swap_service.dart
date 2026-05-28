import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import '../../domain/models/swap_request.dart';
import '../../../books/data/services/block_service.dart';
import '../../../notifications/data/services/notification_service.dart';
import '../../../notifications/domain/models/app_notification.dart';

class DuplicateSwapException implements Exception {}

class SwapService {
  final FirebaseFirestore _db;
  final BlockService _blockService;
  final String _collection = 'swap_requests';
  final NotificationService _notificationService;

  SwapService({
    FirebaseFirestore? firestore,
    BlockService? blockService,
    NotificationService? notificationService,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _blockService = blockService ?? BlockService(),
        _notificationService = notificationService ?? NotificationService();

  Future<String> createSwapRequest(SwapRequest request) async {
    final hasBlock = await _blockService.hasBlockRelationship(
      request.requesterId,
      request.ownerId,
    );

    if (hasBlock) {
      throw Exception('Cannot create request. Access restricted due to block.');
    }

    final swapRequestId = await _db.runTransaction<String>((transaction) async {
      final query = await _db
          .collection(_collection)
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

    final senderInfo = await fetchUserInfo(request.requesterId);
    final senderName = senderInfo['displayName'] ?? 'Someone';

    await _notificationService.createNotification(
      AppNotification(
        id: '',
        recipientId: request.ownerId,
        senderId: request.requesterId,
        senderDisplayName: senderName,
        senderPhotoUrl: senderInfo['photoUrl'],
        type: AppNotificationType.swapRequest,
        title: 'New swap request',
        body: '$senderName wants to swap for one of your books.',
        swapRequestId: swapRequestId,
        swapId: swapRequestId,
        isRead: false,
        createdAt: DateTime.now(),
      ),
      notificationId: 'swap_request_$swapRequestId',
    );

    return swapRequestId;
  }

  Future<void> acceptSwapAndLockBooks(SwapRequest swap) async {
    final batch = _db.batch();

    final swapRef = _db.collection(_collection).doc(swap.id);
    batch.update(swapRef, {'status': SwapStatus.accepted.name});

    final offeredBookRef =
    _db.collection('users/${swap.requesterId}/shelf').doc(swap.bookOfferedId);
    final wantedBookRef =
    _db.collection('users/${swap.ownerId}/shelf').doc(swap.bookWantedId);

    batch.update(offeredBookRef, {'lockedBySwapId': swap.id});
    batch.update(wantedBookRef, {'lockedBySwapId': swap.id});

    final otherRequests = await _db
        .collection(_collection)
        .where('status', isEqualTo: SwapStatus.pending.name)
        .get();

    for (final doc in otherRequests.docs) {
      if (doc.id == swap.id) continue;

      final data = doc.data();

      final conflictsWithWanted =
          data['bookWantedId'] == swap.bookWantedId ||
              data['bookOfferedId'] == swap.bookWantedId;

      final conflictsWithOffered =
          data['bookWantedId'] == swap.bookOfferedId ||
              data['bookOfferedId'] == swap.bookOfferedId;

      if (conflictsWithWanted || conflictsWithOffered) {
        batch.update(doc.reference, {'status': SwapStatus.rejected.name});
      }
    }

    await batch.commit();

    final senderInfo = await fetchUserInfo(swap.ownerId);
    final senderName = senderInfo['displayName'] ?? 'Someone';

    await _notificationService.createNotification(
      AppNotification(
        id: '',
        recipientId: swap.requesterId,
        senderId: swap.ownerId,
        senderDisplayName: senderName,
        senderPhotoUrl: senderInfo['photoUrl'],
        type: AppNotificationType.swapAccepted,
        title: 'Swap accepted',
        body: '$senderName accepted your swap request.',
        swapRequestId: swap.id,
        swapId: swap.id,
        isRead: false,
        createdAt: DateTime.now(),
      ),
      notificationId: 'swap_accepted_${swap.id}',
    );
  }

  Future<void> updateStatus(String id, SwapStatus status) async {
    final ref = _db.collection(_collection).doc(id);
    final snap = await ref.get();

    if (!snap.exists) {
      throw Exception('Swap request not found.');
    }

    final swap = SwapRequest.fromMap(snap.data()!, snap.id);
    final wasPending = swap.status == SwapStatus.pending;

    await ref.update({'status': status.name});

    if (status == SwapStatus.rejected && wasPending) {
      await _notifySwapRejected(swap);
    }
  }

  Future<void> deleteRequest(String id) async {
    await _db.collection(_collection).doc(id).delete();
  }

  Future<void> _notifySwapRejected(SwapRequest swap) async {
    final senderInfo = await fetchUserInfo(swap.ownerId);
    final senderName = senderInfo['displayName'] ?? 'Someone';

    await _notificationService.createNotification(
      AppNotification(
        id: '',
        recipientId: swap.requesterId,
        senderId: swap.ownerId,
        senderDisplayName: senderName,
        senderPhotoUrl: senderInfo['photoUrl'],
        type: AppNotificationType.swapRejected,
        title: 'Swap rejected',
        body: '$senderName rejected your swap request.',
        swapRequestId: swap.id,
        swapId: swap.id,
        isRead: false,
        createdAt: DateTime.now(),
      ),
      notificationId: 'swap_rejected_${swap.id}',
    );
  }

  Future<Map<String, String?>> fetchUserInfo(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();

      if (!doc.exists) {
        return {
          'displayName': null,
          'photoUrl': null,
        };
      }

      final data = doc.data()!;

      return {
        'displayName': data['displayName'] as String?,
        'photoUrl': data['profilePictureUrl'] as String?,
      };
    } catch (_) {
      return {
        'displayName': null,
        'photoUrl': null,
      };
    }
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