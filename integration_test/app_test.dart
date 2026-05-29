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

  Book makeBook(
    String id, {
    BookCondition condition = BookCondition.good,
    String? coverUrl,
    String? notes,
    String? ownerName,
    List<String> conditionPhotoUrls = const [],
    String? category,
    String? location,
  }) => Book(
    id: id,
    isbn: '978000000000$id',
    title: 'Book $id',
    authors: 'Author $id',
    coverUrl: coverUrl,
    condition: condition,
    notes: notes,
    addedAt: DateTime.parse('2025-01-01T00:00:00.000'),
    ownerName: ownerName,
    conditionPhotoUrls: conditionPhotoUrls,
    category: category,
    location: location,
  );

  BookShelfProvider makeProvider() =>
      BookShelfProvider(firestore: fakeFirestore);

  Future<BookShelfProvider> loadProvider(String uid) async {
    final provider = makeProvider();
    await provider.loadBooks(uid, null);
    return provider;
  }

  group('BookShelfProvider Firestore Integration Tests', () {
    testWidgets('books added are persisted and reloadable', (tester) async {
      final provider = await loadProvider('test-uid');

      await provider.addBook(makeBook('A'));
      await provider.addBook(makeBook('B'));

      final reloadedProvider = await loadProvider('test-uid');

      expect(reloadedProvider.books.length, 2);
      expect(
        reloadedProvider.books.map((book) => book.id),
        containsAll(['A', 'B']),
      );
    });

    testWidgets('add then remove persists correctly across reload', (
      tester,
    ) async {
      final provider = await loadProvider('test-uid');

      await provider.addBook(makeBook('A'));
      await provider.addBook(makeBook('B'));
      await provider.removeBook('A');

      final reloadedProvider = await loadProvider('test-uid');

      expect(reloadedProvider.books.length, 1);
      expect(reloadedProvider.books.first.id, 'B');
    });

    testWidgets('all book condition values persist and reload correctly', (
      tester,
    ) async {
      final provider = await loadProvider('test-uid');

      for (final condition in BookCondition.values) {
        await provider.addBook(makeBook(condition.name, condition: condition));
      }

      final reloadedProvider = await loadProvider('test-uid');

      for (final condition in BookCondition.values) {
        final match = reloadedProvider.books.firstWhere(
          (book) => book.id == condition.name,
        );

        expect(match.condition, condition);
      }
    });

    testWidgets('empty shelf persists as empty after reload', (tester) async {
      final provider = await loadProvider('test-uid');

      await provider.addBook(makeBook('A'));
      await provider.removeBook('A');

      final reloadedProvider = await loadProvider('test-uid');

      expect(reloadedProvider.books, isEmpty);
    });

    testWidgets('optional fields persist as null when not set', (tester) async {
      final provider = await loadProvider('test-uid');

      await provider.addBook(makeBook('A'));

      final reloadedProvider = await loadProvider('test-uid');
      final book = reloadedProvider.books.first;

      expect(book.coverUrl, isNull);
      expect(book.notes, isNull);
      expect(book.ownerName, isNull);
      expect(book.category, isNull);
      expect(book.location, isNull);
      expect(book.conditionPhotoUrls, isEmpty);
    });

    testWidgets('optional fields persist correctly when set', (tester) async {
      final provider = await loadProvider('test-uid');

      await provider.addBook(
        makeBook(
          'A',
          coverUrl: 'https://example.com/cover.jpg',
          notes: 'A great book',
          ownerName: 'Alice',
          category: 'Sci-Fi',
          location: 'Porto',
        ),
      );

      final reloadedProvider = await loadProvider('test-uid');
      final book = reloadedProvider.books.first;

      expect(book.coverUrl, 'https://example.com/cover.jpg');
      expect(book.notes, 'A great book');
      expect(book.ownerName, 'Alice');
      expect(book.category, 'Sci-Fi');
      expect(book.location, 'Porto');
    });

    testWidgets('real condition photo urls persist after shelf reload', (
      tester,
    ) async {
      final provider = await loadProvider('test-uid');

      await provider.addBook(
        makeBook(
          'A',
          coverUrl: 'https://books.google.com/cover.jpg',
          conditionPhotoUrls: [
            'https://res.cloudinary.com/leafmark/front.jpg',
            'https://res.cloudinary.com/leafmark/back.jpg',
          ],
        ),
      );

      final reloadedProvider = await loadProvider('test-uid');
      final book = reloadedProvider.books.first;

      expect(book.conditionPhotoUrls, [
        'https://res.cloudinary.com/leafmark/front.jpg',
        'https://res.cloudinary.com/leafmark/back.jpg',
      ]);
      expect(book.coverUrl, 'https://books.google.com/cover.jpg');
    });

    testWidgets('different user shelves remain isolated', (tester) async {
      final firstUserProvider = await loadProvider('userA');
      final secondUserProvider = await loadProvider('userB');

      await firstUserProvider.addBook(makeBook('A'));
      await secondUserProvider.addBook(makeBook('B'));

      final reloadedFirstUserProvider = await loadProvider('userA');
      final reloadedSecondUserProvider = await loadProvider('userB');

      expect(reloadedFirstUserProvider.books.length, 1);
      expect(reloadedFirstUserProvider.books.first.id, 'A');
      expect(reloadedSecondUserProvider.books.length, 1);
      expect(reloadedSecondUserProvider.books.first.id, 'B');
    });

    testWidgets('clearBooks empties the shelf in memory', (tester) async {
      final provider = await loadProvider('test-uid');

      await provider.addBook(makeBook('A'));
      await provider.addBook(makeBook('B'));
      await provider.clearBooks();

      expect(provider.books, isEmpty);
    });
  });
}
