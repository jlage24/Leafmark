import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/book.dart';

class BrowseService {
  final FirebaseFirestore _firestore;

  BrowseService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<Book>> browseBooks(String currentUid) {
    return _firestore
        .collectionGroup('shelf')
        .where('ownerId', isNotEqualTo: currentUid)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Book.fromJson(doc.data()))
        .toList());
  }

  Future<Book?> fetchBook(String ownerId, String bookId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(ownerId)
          .collection('shelf')
          .doc(bookId)
          .get();
      if (!doc.exists) return null;
      return Book.fromJson({...doc.data()!, 'id': doc.id});
    } catch (_) {
      return null;
    }
  }

  Future<String?> fetchDisplayName(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return doc.data()?['displayName'] as String?;
    } catch (_) {
      return null;
    }
  }
}