import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:leafmark/features/books/domain/models/book.dart';
import 'package:leafmark/features/books/presentation/providers/book_shelf_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
  });

  Book makeBook(String id) => Book(
    id: id,
    isbn: '978000000000$id',
    title: 'Book $id',
    authors: 'Author $id',
    condition: BookCondition.good,
    addedAt: DateTime.parse('2025-01-01T00:00:00.000'),
  );

  BookShelfProvider makeProvider() =>
      BookShelfProvider(firestore: fakeFirestore);

  group('BookShelfProvider - Firestore integration', () {
    testWidgets('books added are persisted and reloadable', (tester) async {
      final provider1 = makeProvider();
      await provider1.loadBooks('test-uid', null);
      await provider1.addBook(makeBook('A'));
      await provider1.addBook(makeBook('B'));

      final provider2 = BookShelfProvider(firestore: fakeFirestore);
      await provider2.loadBooks('test-uid', null);

      expect(provider2.books.length, 2);
      expect(provider2.books.map((b) => b.id), containsAll(['A', 'B']));
    });

    testWidgets('add then remove persists correctly across reload', (tester) async {
      final provider1 = makeProvider();
      await provider1.loadBooks('test-uid', null);
      await provider1.addBook(makeBook('A'));
      await provider1.addBook(makeBook('B'));
      await provider1.removeBook('A');

      final provider2 = BookShelfProvider(firestore: fakeFirestore);
      await provider2.loadBooks('test-uid', null);

      expect(provider2.books.length, 1);
      expect(provider2.books.first.id, 'B');
    });

    testWidgets('all BookCondition values persist and reload correctly', (tester) async {
      final provider1 = makeProvider();
      await provider1.loadBooks('test-uid', null);

      for (final condition in BookCondition.values) {
        await provider1.addBook(Book(
          id: condition.name,
          isbn: '9780000000001',
          title: 'Book ${condition.name}',
          authors: 'Author',
          condition: condition,
          addedAt: DateTime.parse('2025-01-01T00:00:00.000'),
        ));
      }

      final provider2 = BookShelfProvider(firestore: fakeFirestore);
      await provider2.loadBooks('test-uid', null);

      for (final condition in BookCondition.values) {
        final match = provider2.books.firstWhere((b) => b.id == condition.name);
        expect(match.condition, condition);
      }
    });

    testWidgets('empty shelf persists as empty after reload', (tester) async {
      final provider1 = makeProvider();
      await provider1.loadBooks('test-uid', null);
      await provider1.addBook(makeBook('A'));
      await provider1.removeBook('A');

      final provider2 = BookShelfProvider(firestore: fakeFirestore);
      await provider2.loadBooks('test-uid', null);

      expect(provider2.books, isEmpty);
    });

    testWidgets('optional fields persist as null when not set', (tester) async {
      final provider1 = makeProvider();
      await provider1.loadBooks('test-uid', null);
      await provider1.addBook(makeBook('A'));

      final provider2 = BookShelfProvider(firestore: fakeFirestore);
      await provider2.loadBooks('test-uid', null);

      final book = provider2.books.first;
      expect(book.coverUrl, isNull);
      expect(book.notes, isNull);
      expect(book.ownerName, isNull);
    });

    testWidgets('optional fields persist correctly when set', (tester) async {
      final provider1 = makeProvider();
      await provider1.loadBooks('test-uid', null);
      await provider1.addBook(
        makeBook('A').copyWith(
          coverUrl: 'https://example.com/cover.jpg',
          notes: 'A great book',
          ownerName: 'Alice',
        ),
      );

      final provider2 = BookShelfProvider(firestore: fakeFirestore);
      await provider2.loadBooks('test-uid', null);

      final book = provider2.books.first;
      expect(book.coverUrl, 'https://example.com/cover.jpg');
      expect(book.notes, 'A great book');
      expect(book.ownerName, 'Alice');
    });

    testWidgets('clearBooks empties the shelf in memory', (tester) async {
      final provider = makeProvider();
      await provider.loadBooks('test-uid', null);
      await provider.addBook(makeBook('A'));
      await provider.addBook(makeBook('B'));
      await provider.clearBooks();

      expect(provider.books, isEmpty);
    });
  });
}