import 'package:flutter/foundation.dart';
import '../../data/services/wishlist_service.dart';
import '../../domain/models/wishlist_item.dart';

class WishlistProvider extends ChangeNotifier {
  final WishlistService _service;

  WishlistProvider({WishlistService? service})
      : _service = service ?? WishlistService();

  Stream<List<WishlistItem>> getWishlist(String uid) =>
      _service.getWishlist(uid);

  Future<void> addItem(String uid, WishlistItem item) =>
      _service.addItem(uid, item);

  Future<void> removeItem(String uid, String itemId) =>
      _service.removeItem(uid, itemId);
}