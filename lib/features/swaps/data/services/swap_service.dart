import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

import '../../../books/data/services/block_service.dart';
import '../../../books/domain/models/book.dart';
import '../../../notifications/data/services/notification_service.dart';
import '../../../notifications/domain/models/app_notification.dart';
import '../../domain/models/swap_request.dart';

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

    return await _db.runTransaction<String>((transaction) async {
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
    }).then((swapRequestId) async {
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
    });
  }

  Future<void> acceptSwapById(String id) async {
    final snap = await _db.collection(_collection).doc(id).get();

    if (!snap.exists) {
      throw Exception('Swap request not found.');
    }

    final swap = SwapRequest.fromMap(snap.data()!, snap.id);
    await acceptSwapAndLockBooks(swap);
  }

  Future<void> acceptSwapAndLockBooks(SwapRequest swap) async {
    if (swap.status != SwapStatus.pending) {
      return;
    }

    final batch = _db.batch();

    final swapRef = _db.collection(_collection).doc(swap.id);
    batch.update(swapRef, {'status': SwapStatus.accepted.name});

    final chatRef = _db.collection('chats').doc(swap.id);
    batch.update(chatRef, {
      'status': 'accepted',
      'lastMessage': '✅ Swap accepted — books reserved',
      'lastMessageAt': FieldValue.serverTimestamp(),
    });

    final offeredBookRef =
    _db.collection('users/${swap.requesterId}/shelf').doc(swap.bookOfferedId);
    final wantedBookRef =
    _db.collection('users/${swap.ownerId}/shelf').doc(swap.bookWantedId);

    batch.update(offeredBookRef, {'lockedBySwapId': swap.id});
    batch.update(wantedBookRef, {'lockedBySwapId': swap.id});

    final otherRequests = await _db
        .collection(_collection)
        .where('status', isEqualTo: SwapStatus.pending.name)
        .where('ownerId', isEqualTo: swap.ownerId)
        .get();

    for (final doc in otherRequests.docs) {
      if (doc.id == swap.id) continue;

      final data = doc.data();

      final conflictsWithWanted =
          data['bookWantedId'] == swap.bookWantedId ||
              data['bookOfferedId'] == swap.bookWantedId;

      if (conflictsWithWanted) {
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
        body: '$senderName accepted your swap request. Meet up to complete the exchange.',
        swapRequestId: swap.id,
        swapId: swap.id,
        chatId: swap.id,
        isRead: false,
        createdAt: DateTime.now(),
      ),
      notificationId: 'swap_accepted_${swap.id}',
    );
  }

  Future<void> rejectSwapById(String id) async {
    final ref = _db.collection(_collection).doc(id);
    final snap = await ref.get();

    if (!snap.exists) {
      throw Exception('Swap request not found.');
    }

    final swap = SwapRequest.fromMap(snap.data()!, snap.id);

    if (swap.status == SwapStatus.completed) {
      throw Exception('Completed exchanges cannot be rejected.');
    }

    final batch = _db.batch();

    batch.update(ref, {'status': SwapStatus.rejected.name});
    batch.update(_db.collection('chats').doc(id), {
      'status': 'cancelled',
      'lastMessage': '❌ Swap rejected',
      'lastMessageAt': FieldValue.serverTimestamp(),
    });

    await _unlockBooksIfNeeded(batch, swap);
    await batch.commit();

    if (swap.status == SwapStatus.pending) {
      await _notifySwapRejected(swap);
    }
  }

  Future<void> updateStatus(String id, SwapStatus status) async {
    if (status == SwapStatus.rejected) {
      await rejectSwapById(id);
      return;
    }

    await _db.collection(_collection).doc(id).update({'status': status.name});
  }

  Future<void> cancelRequest(String id) async {
    final ref = _db.collection(_collection).doc(id);
    final snap = await ref.get();

    if (!snap.exists) {
      await ref.delete();
      return;
    }

    final swap = SwapRequest.fromMap(snap.data()!, snap.id);

    if (swap.status == SwapStatus.pending) {
      await ref.delete();
      return;
    }

    final batch = _db.batch();
    batch.update(ref, {'status': SwapStatus.cancelled.name});
    batch.update(_db.collection('chats').doc(id), {
      'status': 'cancelled',
      'lastMessage': 'Swap cancelled',
      'lastMessageAt': FieldValue.serverTimestamp(),
    });

    await _unlockBooksIfNeeded(batch, swap);
    await batch.commit();
  }

  Future<void> deleteRequest(String id) => cancelRequest(id);

  Future<void> completePhysicalExchange(String swapId) async {
    final requesterInfo = await fetchUserInfoByFallback(swapId, role: 'requester');
    final ownerInfo = await fetchUserInfoByFallback(swapId, role: 'owner');

    await _db.runTransaction((transaction) async {
      final swapRef = _db.collection(_collection).doc(swapId);
      final swapSnap = await transaction.get(swapRef);

      if (!swapSnap.exists) {
        throw Exception('Swap request not found.');
      }

      final swap = SwapRequest.fromMap(swapSnap.data()!, swapSnap.id);

      if (swap.status == SwapStatus.completed) {
        return;
      }

      if (swap.status != SwapStatus.accepted) {
        throw Exception('Only accepted swaps can be completed.');
      }

      final offeredBookRef =
      _db.collection('users/${swap.requesterId}/shelf').doc(swap.bookOfferedId);
      final wantedBookRef =
      _db.collection('users/${swap.ownerId}/shelf').doc(swap.bookWantedId);

      final offeredSnap = await transaction.get(offeredBookRef);
      final wantedSnap = await transaction.get(wantedBookRef);

      if (!offeredSnap.exists || !wantedSnap.exists) {
        throw Exception('One of the reserved books no longer exists.');
      }

      final offeredBook = Book.fromJson({
        ...offeredSnap.data()!,
        'id': offeredSnap.id,
      });

      final wantedBook = Book.fromJson({
        ...wantedSnap.data()!,
        'id': wantedSnap.id,
      });

      if (offeredBook.lockedBySwapId != swap.id ||
          wantedBook.lockedBySwapId != swap.id) {
        throw Exception('Books are not reserved for this swap.');
      }

      final requesterDisplayName = requesterInfo['displayName'] ?? 'LeafMark user';
      final ownerDisplayName = ownerInfo['displayName'] ?? 'LeafMark user';

      final wantedBookForRequester = wantedBook.copyWith(
        ownerId: swap.requesterId,
        ownerName: requesterDisplayName,
        lockedBySwapId: null,
        lastExchangeId: swap.id,
      );

      final offeredBookForOwner = offeredBook.copyWith(
        ownerId: swap.ownerId,
        ownerName: ownerDisplayName,
        lockedBySwapId: null,
        lastExchangeId: swap.id,
      );

      final newWantedRef =
      _db.collection('users/${swap.requesterId}/shelf').doc(swap.bookWantedId);
      final newOfferedRef =
      _db.collection('users/${swap.ownerId}/shelf').doc(swap.bookOfferedId);

      transaction.set(newWantedRef, wantedBookForRequester.toJson());
      transaction.set(newOfferedRef, offeredBookForOwner.toJson());

      transaction.delete(wantedBookRef);
      transaction.delete(offeredBookRef);

      transaction.update(swapRef, {
        'status': SwapStatus.completed.name,
        'completedAt': FieldValue.serverTimestamp(),
      });

      transaction.update(_db.collection('chats').doc(swap.id), {
        'status': 'completed',
        'lastMessage': '🎉 Exchange completed',
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> _unlockBooksIfNeeded(WriteBatch batch, SwapRequest swap) async {
    if (swap.status != SwapStatus.accepted) return;

    final offeredBookRef =
    _db.collection('users/${swap.requesterId}/shelf').doc(swap.bookOfferedId);
    final wantedBookRef =
    _db.collection('users/${swap.ownerId}/shelf').doc(swap.bookWantedId);

    final offeredSnap = await offeredBookRef.get();
    final wantedSnap = await wantedBookRef.get();

    if (offeredSnap.data()?['lockedBySwapId'] == swap.id) {
      batch.update(offeredBookRef, {'lockedBySwapId': null});
    }

    if (wantedSnap.data()?['lockedBySwapId'] == swap.id) {
      batch.update(wantedBookRef, {'lockedBySwapId': null});
    }
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

  Future<Map<String, String?>> fetchUserInfoByFallback(
      String swapId, {
        required String role,
      }) async {
    final snap = await _db.collection(_collection).doc(swapId).get();

    if (!snap.exists) {
      return {
        'displayName': null,
        'photoUrl': null,
      };
    }

    final swap = SwapRequest.fromMap(snap.data()!, snap.id);
    final uid = role == 'requester' ? swap.requesterId : swap.ownerId;

    return fetchUserInfo(uid);
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
        .where('status', isEqualTo: SwapStatus.completed.name)
        .snapshots()
        .map((s) => s.docs
        .map((d) => SwapRequest.fromMap(d.data(), d.id))
        .toList());

    final asOwner = _db
        .collection(_collection)
        .where('ownerId', isEqualTo: uid)
        .where('status', isEqualTo: SwapStatus.completed.name)
        .snapshots()
        .map((s) => s.docs
        .map((d) => SwapRequest.fromMap(d.data(), d.id))
        .toList());

    return Rx.combineLatest2(asRequester, asOwner, (a, b) {
      final merged = [...a, ...b];
      merged.sort((x, y) {
        final xDate = x.completedAt ?? x.createdAt;
        final yDate = y.completedAt ?? y.createdAt;
        return yDate.compareTo(xDate);
      });
      return merged;
    });
  }
}