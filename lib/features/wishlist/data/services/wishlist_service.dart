import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/wishlist_item.dart';

class WishlistService {
  final FirebaseFirestore _db;

  WishlistService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  CollectionReference _wishlist(String uid) =>
      _db.collection('users').doc(uid).collection('wishlist');

  Future<void> addItem(String uid, WishlistItem item) async {
    await _wishlist(uid).add(item.toMap());
  }

  Future<void> removeItem(String uid, String itemId) async {
    await _wishlist(uid).doc(itemId).delete();
  }

  Stream<List<WishlistItem>> getWishlist(String uid) {
    return _wishlist(uid)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map(
          (s) => s.docs
              .map(
                (d) => WishlistItem.fromMap(
                  d.data() as Map<String, dynamic>,
                  d.id,
                ),
              )
              .toList(),
        );
  }
}
