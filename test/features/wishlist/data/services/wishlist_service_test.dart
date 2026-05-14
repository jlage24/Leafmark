import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leafmark/features/wishlist/data/services/wishlist_service.dart';
import 'package:leafmark/features/wishlist/domain/models/wishlist_item.dart';

void main() {
  late FakeFirebaseFirestore fakeDb;
  late WishlistService service;
  const uid = 'user_test_123';

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    service = WishlistService(db: fakeDb);
  });

  WishlistItem makeItem() => WishlistItem(
    id: '',
    title: 'Dune',
    authors: ['Frank Herbert'],
    isbn: '9780441013593',
    addedAt: DateTime(2024, 1, 1),
  );

  group('WishlistService', () {
    test('addItem persists document to Firestore', () async {
      await service.addItem(uid, makeItem());

      final snap = await fakeDb
          .collection('users')
          .doc(uid)
          .collection('wishlist')
          .get();

      expect(snap.docs.length, 1);
      expect(snap.docs.first['title'], 'Dune');
      expect(snap.docs.first['authors'], ['Frank Herbert']);
      expect(snap.docs.first['isbn'], '9780441013593');
    });

    test('addItem stores multiple items independently', () async {
      await service.addItem(uid, makeItem());
      await service.addItem(
        uid,
        WishlistItem(
          id: '',
          title: '1984',
          authors: ['George Orwell'],
          addedAt: DateTime(2024, 1, 2),
        ),
      );

      final snap = await fakeDb
          .collection('users')
          .doc(uid)
          .collection('wishlist')
          .get();

      expect(snap.docs.length, 2);
    });

    test('removeItem deletes correct document', () async {
      final ref = await fakeDb
          .collection('users')
          .doc(uid)
          .collection('wishlist')
          .add(makeItem().toMap());

      await service.removeItem(uid, ref.id);

      final snap = await fakeDb
          .collection('users')
          .doc(uid)
          .collection('wishlist')
          .get();

      expect(snap.docs, isEmpty);
    });

    test('removeItem does not affect other items', () async {
      final ref = await fakeDb
          .collection('users')
          .doc(uid)
          .collection('wishlist')
          .add(makeItem().toMap());

      await fakeDb
          .collection('users')
          .doc(uid)
          .collection('wishlist')
          .add(WishlistItem(
        id: '',
        title: '1984',
        authors: ['George Orwell'],
        addedAt: DateTime(2024, 1, 2),
      ).toMap());

      await service.removeItem(uid, ref.id);

      final snap = await fakeDb
          .collection('users')
          .doc(uid)
          .collection('wishlist')
          .get();

      expect(snap.docs.length, 1);
      expect(snap.docs.first['title'], '1984');
    });

    test('getWishlist returns stream with correct items', () async {
      await fakeDb
          .collection('users')
          .doc(uid)
          .collection('wishlist')
          .add(makeItem().toMap());

      final stream = service.getWishlist(uid);
      final items = await stream.first;

      expect(items.length, 1);
      expect(items.first.title, 'Dune');
      expect(items.first.authors, ['Frank Herbert']);
    });

    test('getWishlist returns empty list when no items', () async {
      final stream = service.getWishlist(uid);
      final items = await stream.first;
      expect(items, isEmpty);
    });
  });
}