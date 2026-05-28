import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leafmark/features/books/data/services/block_service.dart';
import 'package:leafmark/features/books/data/services/browse_service.dart';

void main() {
  late FakeFirebaseFirestore fakeDb;
  late BlockService blockService;
  late BrowseService browseService;

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    blockService = BlockService(firestore: fakeDb);
    browseService = BrowseService(
      firestore: fakeDb,
      blockService: blockService,
    );
  });

  Map<String, dynamic> makeBookData({
    required String id,
    required String ownerId,
    required String title,
    String? lockedBySwapId,
    String? category,
    String? location,
  }) {
    return {
      'id': id,
      'isbn': '9780000000000',
      'title': title,
      'authors': 'Test Author',
      'coverUrl': null,
      'condition': 'good',
      'notes': null,
      'addedAt': DateTime(2026, 1, 1).toIso8601String(),
      'ownerName': 'Test Owner',
      'ownerId': ownerId,
      'lockedBySwapId': lockedBySwapId,
      'conditionPhotoUrls': <String>[],
      'category': category,
      'location': location,
    };
  }

  Future<void> addBook({
    required String ownerId,
    required String bookId,
    required String title,
    String? lockedBySwapId,
    String? category,
    String? location,
  }) async {
    await fakeDb
        .collection('users')
        .doc(ownerId)
        .collection('shelf')
        .doc(bookId)
        .set(
          makeBookData(
            id: bookId,
            ownerId: ownerId,
            title: title,
            lockedBySwapId: lockedBySwapId,
            category: category,
            location: location,
          ),
        );
  }

  group('BrowseService Unit Tests', () {
    test('browseBooks returns books owned by other users', () async {
      await addBook(ownerId: 'userA', bookId: 'book1', title: 'Own Book');

      await addBook(ownerId: 'userB', bookId: 'book2', title: 'Available Book');

      final books = await browseService.browseBooks('userA').first;

      expect(books.length, 1);
      expect(books.first.id, 'book2');
      expect(books.first.ownerId, 'userB');
      expect(books.first.title, 'Available Book');
    });

    test(
      'browseBooks returns all books when current user id is empty',
      () async {
        await addBook(ownerId: 'userA', bookId: 'book1', title: 'First Book');

        await addBook(ownerId: 'userB', bookId: 'book2', title: 'Second Book');

        final books = await browseService.browseBooks('').first;

        expect(books.length, 2);
        expect(books.map((book) => book.id), containsAll(['book1', 'book2']));
      },
    );

    test('browseBooks hides books from blocked users', () async {
      await addBook(
        ownerId: 'userB',
        bookId: 'book1',
        title: 'Blocked User Book',
      );

      await addBook(
        ownerId: 'userC',
        bookId: 'book2',
        title: 'Visible User Book',
      );

      await blockService.blockUser('userA', 'userB');

      final books = await browseService.browseBooks('userA').first;

      expect(books.length, 1);
      expect(books.first.id, 'book2');
      expect(books.first.ownerId, 'userC');
    });

    test(
      'browseAvailableBooks returns only unlocked books from other users',
      () async {
        await addBook(ownerId: 'userA', bookId: 'book1', title: 'Own Book');

        await addBook(
          ownerId: 'userB',
          bookId: 'book2',
          title: 'Unlocked Book',
        );

        await addBook(
          ownerId: 'userC',
          bookId: 'book3',
          title: 'Locked Book',
          lockedBySwapId: 'swap1',
        );

        final books = await browseService.browseAvailableBooks('userA').first;

        expect(books.length, 1);
        expect(books.first.id, 'book2');
        expect(books.first.isLocked, isFalse);
      },
    );

    test(
      'browseAvailableBooks hides unlocked books from blocked users',
      () async {
        await addBook(
          ownerId: 'userB',
          bookId: 'book1',
          title: 'Blocked User Book',
        );

        await addBook(
          ownerId: 'userC',
          bookId: 'book2',
          title: 'Visible User Book',
        );

        await blockService.blockUser('userA', 'userB');

        final books = await browseService.browseAvailableBooks('userA').first;

        expect(books.length, 1);
        expect(books.first.id, 'book2');
        expect(books.first.ownerId, 'userC');
      },
    );

    test('browseAvailableBooks preserves category and location data', () async {
      await addBook(
        ownerId: 'userB',
        bookId: 'book1',
        title: 'Fantasy Book',
        category: 'Fantasy',
        location: 'Porto',
      );

      final books = await browseService.browseAvailableBooks('userA').first;

      expect(books.length, 1);
      expect(books.first.category, 'Fantasy');
      expect(books.first.location, 'Porto');
    });

    test('fetchBook returns book owned by selected user', () async {
      await addBook(
        ownerId: 'userB',
        bookId: 'book1',
        title: 'Selected Book',
        category: 'Sci-Fi',
        location: 'Porto',
      );

      final book = await browseService.fetchBook('userB', 'book1');

      expect(book, isNotNull);
      expect(book!.id, 'book1');
      expect(book.title, 'Selected Book');
      expect(book.ownerId, 'userB');
      expect(book.category, 'Sci-Fi');
      expect(book.location, 'Porto');
    });

    test('fetchBook returns null when book does not exist', () async {
      final book = await browseService.fetchBook('userB', 'missingBook');

      expect(book, isNull);
    });

    test('fetchDisplayName returns stored display name', () async {
      await fakeDb.collection('users').doc('userB').set({
        'displayName': 'Beatriz',
      });

      final displayName = await browseService.fetchDisplayName('userB');

      expect(displayName, 'Beatriz');
    });

    test('fetchDisplayName returns null when user does not exist', () async {
      final displayName = await browseService.fetchDisplayName('missingUser');

      expect(displayName, isNull);
    });
  });
}
