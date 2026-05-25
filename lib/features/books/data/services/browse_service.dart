import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import '../../domain/models/book.dart';
import '../../../books/data/services/block_service.dart';

class BrowseService {
  final FirebaseFirestore _firestore;

  BrowseService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<Book>> browseBooks(String currentUid) {
    final booksStream = _firestore
        .collectionGroup('shelf')
        .where('ownerId', isNotEqualTo: currentUid.isEmpty ? 'invalid' : currentUid)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Book.fromJson(doc.data()))
        .toList());

    if (currentUid.isEmpty) return booksStream;
    final blocksStream = BlockService().getBlockedUsersStream(currentUid);
    return Rx.combineLatest2(booksStream, blocksStream, (List<Book> books, List<String> blockedUids) {

      // Filtra os livros cujos donos estejam na lista de bloqueados
      return books.where((book) => !blockedUids.contains(book.ownerId)).toList();
    });
  }

  Stream<List<Book>> browseAvailableBooks(String currentUid) {
    return FirebaseFirestore.instance
        .collectionGroup('shelf')
        .where('ownerId', isNotEqualTo: currentUid)
        .where('lockedBySwapId', isNull: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => Book.fromJson({...doc.data(), 'id': doc.id}))
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