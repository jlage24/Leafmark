import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leafmark/features/books/domain/models/book.dart';
import 'package:leafmark/features/books/presentation/providers/book_shelf_provider.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
  });

  Book makeBook(String id, {BookCondition condition = BookCondition.good}) => Book(
    id: id,
    isbn: '978000000000$id',
    title: 'Book $id',
    authors: 'Author $id',
    condition: condition,
    addedAt: DateTime.parse('2025-01-01T00:00:00.000'),
  );

  BookShelfProvider makeProvider() =>
      BookShelfProvider(firestore: fakeFirestore);

  group('BookShelfProvider - initial state', () {
    test('shelf is empty before loadBooks', () {
      final provider = makeProvider();
      expect(provider.books, isEmpty);
    });

    test('loadBooks with no persisted data results in empty shelf', () async {
      final provider = makeProvider();
      await provider.loadBooks('test-uid');
      expect(provider.books, isEmpty);
    });
  });

  group('BookShelfProvider - addBook', () {
    test('adds a book and shelf grows', () async {
      final provider = makeProvider();
      await provider.loadBooks('test-uid');
      await provider.addBook(makeBook('1'));
      expect(provider.books.length, 1);
    });

    test('added book is retrievable by id', () async {
      final provider = makeProvider();
      await provider.loadBooks('test-uid');
      await provider.addBook(makeBook('1'));
      expect(provider.books.first.id, '1');
    });

    test('multiple books can be added', () async {
      final provider = makeProvider();
      await provider.loadBooks('test-uid');
      await provider.addBook(makeBook('1'));
      await provider.addBook(makeBook('2'));
      await provider.addBook(makeBook('3'));
      expect(provider.books.length, 3);
    });

    test('books list is unmodifiable', () async {
      final provider = makeProvider();
      await provider.loadBooks('test-uid');
      await provider.addBook(makeBook('1'));
      expect(
            () => (provider.books as dynamic).add(makeBook('2')),
        throwsUnsupportedError,
      );
    });
  });

  group('BookShelfProvider - removeBook', () {
    test('removes book by id', () async {
      final provider = makeProvider();
      await provider.loadBooks('test-uid');
      await provider.addBook(makeBook('1'));
      await provider.removeBook('1');
      expect(provider.books, isEmpty);
    });

    test('removing non-existent id does not throw', () async {
      final provider = makeProvider();
      await provider.loadBooks('test-uid');
      await provider.addBook(makeBook('1'));
      await expectLater(provider.removeBook('ghost-id'), completes);
      expect(provider.books.length, 1);
    });

    test('only the targeted book is removed', () async {
      final provider = makeProvider();
      await provider.loadBooks('test-uid');
      await provider.addBook(makeBook('1'));
      await provider.addBook(makeBook('2'));
      await provider.removeBook('1');
      expect(provider.books.length, 1);
      expect(provider.books.first.id, '2');
    });
  });

  group('BookShelfProvider - persistence', () {
    test('books survive a provider reload', () async {
      final provider1 = makeProvider();
      await provider1.loadBooks('test-uid');
      await provider1.addBook(makeBook('1'));
      await provider1.addBook(makeBook('2'));

      final provider2 = BookShelfProvider(firestore: fakeFirestore);
      await provider2.loadBooks('test-uid');
      expect(provider2.books.length, 2);
      expect(provider2.books.map((b) => b.id), containsAll(['1', '2']));
    });

    test('removed books are not reloaded', () async {
      final provider1 = makeProvider();
      await provider1.loadBooks('test-uid');
      await provider1.addBook(makeBook('1'));
      await provider1.addBook(makeBook('2'));
      await provider1.removeBook('1');

      final provider2 = BookShelfProvider(firestore: fakeFirestore);
      await provider2.loadBooks('test-uid');
      expect(provider2.books.length, 1);
      expect(provider2.books.first.id, '2');
    });
  });

  group('BookShelfProvider - clearBooks', () {
    test('clears all books in memory', () async {
      final provider = makeProvider();
      await provider.loadBooks('test-uid');
      await provider.addBook(makeBook('1'));
      await provider.addBook(makeBook('2'));
      await provider.clearBooks();
      expect(provider.books, isEmpty);
    });
  });
}