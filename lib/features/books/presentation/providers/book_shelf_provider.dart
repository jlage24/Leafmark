import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/book.dart';

class BookShelfProvider extends ChangeNotifier {
  final FirebaseFirestore _db;
  String? _uid;

  List<Book> _books = [];
  List<Book> get books => List.unmodifiable(_books);

  String get _collectionPath => 'users/$_uid/shelf';

  BookShelfProvider({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  Future<void> loadBooks(String uid) async {
    _uid = uid;
    final snapshot = await _db.collection(_collectionPath).get();
    _books = snapshot.docs
        .map((doc) => Book.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
    notifyListeners();
  }

  Future<void> addBook(Book book) async {
    if (_uid == null) {
      _books.add(book);
      notifyListeners();
      return;
    }
    await _db.collection(_collectionPath).doc(book.id).set(book.toJson());
    _books.add(book);
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
    _books = [];
    notifyListeners();
  }
}