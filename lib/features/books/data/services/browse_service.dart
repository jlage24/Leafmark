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
}