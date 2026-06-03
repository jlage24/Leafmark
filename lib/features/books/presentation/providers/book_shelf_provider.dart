import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/book.dart';

class BookShelfProvider extends ChangeNotifier {
  final FirebaseFirestore _db;
  String? _uid;
  String? _ownerName;

  List<Book> _books = [];
  List<Book> get books => List.unmodifiable(_books);

  List<Book> get availableBooks => _books.where((b) => !b.isLocked).toList();

  String get _collectionPath => 'users/$_uid/shelf';

  BookShelfProvider({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  Future<void> loadBooks(String uid, String? ownerName) async {
    _uid = uid;
    _ownerName = ownerName;
    final snapshot = await _db.collection(_collectionPath).get();
    _books = snapshot.docs
        .map((doc) => Book.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
    notifyListeners();
  }

  Future<void> addBook(Book book) async {
    final bookWithOwner = book.copyWith(ownerId: _uid, ownerName: _ownerName);
    if (_uid == null) {
      _books.add(bookWithOwner);
      notifyListeners();
      return;
    }
    await _db
        .collection(_collectionPath)
        .doc(bookWithOwner.id)
        .set(bookWithOwner.toJson());
    _books.add(bookWithOwner);
    notifyListeners();
  }

  Future<void> updateBook(Book updatedBook) async {
    if (_uid == null) return;
    if (updatedBook.isLocked) {
      throw Exception('Reserved books cannot be edited.');
    }

    final bookWithOwner = updatedBook.copyWith(
      ownerId: _uid,
      ownerName: _ownerName,
    );

    await _db
        .collection(_collectionPath)
        .doc(bookWithOwner.id)
        .set(bookWithOwner.toJson(), SetOptions(merge: true));

    final index = _books.indexWhere((book) => book.id == updatedBook.id);

    if (index != -1) {
      _books[index] = bookWithOwner;
      notifyListeners();
    }
  }

  Future<void> removeBook(String id) async {
    try {
      final book = _books.firstWhere((b) => b.id == id);
      if (book.isLocked) {
        throw Exception('Cannot remove a reserved book. Please cancel the swap first.');
      }
    } catch (e) {
      if (e is StateError) {
        // Book not found locally, proceed anyway
      } else {
        rethrow;
      }
    }

    if (_uid != null) {
      final batch = _db.batch();
      final bookRef = _db.collection(_collectionPath).doc(id);
      batch.delete(bookRef);

      final q1 = await _db.collection('swap_requests')
          .where('status', isEqualTo: 'pending')
          .where('bookOfferedId', isEqualTo: id)
          .get();
          
      final q2 = await _db.collection('swap_requests')
          .where('status', isEqualTo: 'pending')
          .where('bookWantedId', isEqualTo: id)
          .get();
          
      final processed = <String>{};
      for (final doc in [...q1.docs, ...q2.docs]) {
        if (!processed.add(doc.id)) continue;
        batch.update(doc.reference, {'status': 'cancelled'});
        batch.update(_db.collection('chats').doc(doc.id), {
          'status': 'cancelled',
          'lastMessage': 'Swap automatically cancelled because a book was removed.',
          'lastMessageAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
    }

    _books.removeWhere((b) => b.id == id);
    notifyListeners();
  }

  Future<void> clearBooks() async {
    _uid = null;
    _ownerName = null;
    _books = [];
    notifyListeners();
  }

  Future<void> lockBook({
    required String bookOwnerId,
    required String bookId,
    required String swapId,
  }) async {
    await _db.collection('users/$bookOwnerId/shelf').doc(bookId).update({
      'lockedBySwapId': swapId,
    });

    _updateLocalLock(bookId, swapId);
  }

  Future<void> unlockBook({
    required String bookOwnerId,
    required String bookId,
  }) async {
    await _db.collection('users/$bookOwnerId/shelf').doc(bookId).update({
      'lockedBySwapId': null,
    });
    _updateLocalLock(bookId, null);
  }

  void _updateLocalLock(String bookId, String? swapId) {
    final idx = _books.indexWhere((b) => b.id == bookId);
    if (idx == -1) return;
    _books[idx] = _books[idx].copyWith(lockedBySwapId: swapId);
    notifyListeners();
  }
}
