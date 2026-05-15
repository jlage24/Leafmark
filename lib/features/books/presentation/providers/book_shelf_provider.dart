import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/book.dart';

class BookShelfProvider extends ChangeNotifier {
  final FirebaseFirestore _db;
  String? _uid;
  String? _ownerName;

  List<Book> _books = [];
  List<Book> get books => List.unmodifiable(_books);

  List<Book> get availableBooks =>
      _books.where((b) => !b.isLocked).toList();

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
    final bookWithOwner = book.copyWith(
      ownerId: _uid,
      ownerName: _ownerName,
    );
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

  Future<void> removeBook(String id) async {
    if (_uid != null) {
      await _db.collection(_collectionPath).doc(id).delete();
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
    await _db
        .collection('users/$bookOwnerId/shelf')
        .doc(bookId)
        .update({'lockedBySwapId': swapId});

    _updateLocalLock(bookId, swapId);
  }

  Future<void> unlockBook({
    required String bookOwnerId,
    required String bookId,
  }) async {
    await _db
        .collection('users/$bookOwnerId/shelf')
        .doc(bookId)
        .update({'lockedBySwapId': null});
    _updateLocalLock(bookId, null);
  }

  void _updateLocalLock(String bookId, String? swapId) {
    final idx = _books.indexWhere((b) => b.id == bookId);
    if (idx == -1) return;
    _books[idx] = _books[idx].copyWith(lockedBySwapId: swapId);
    notifyListeners();
  }
}