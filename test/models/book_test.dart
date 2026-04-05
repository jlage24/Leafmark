import 'package:flutter_test/flutter_test.dart';
import 'package:leafmark/features/books/domain/models/book.dart';

void main() {
  final fixedDate = DateTime.parse('2025-01-01T00:00:00.000');

  Book makeBook({
    String id = 'book-1',
    String isbn = '9780141036144',
    String title = 'Nineteen Eighty-Four',
    String authors = 'George Orwell',
    BookCondition condition = BookCondition.good,
  }) =>
      Book(
        id: id,
        isbn: isbn,
        title: title,
        authors: authors,
        condition: condition,
        addedAt: fixedDate,
      );

  group('Book.toJson / fromJson', () {
    test('round-trip preserves all fields', () {
      final book = makeBook().copyWith(
        coverUrl: 'https://example.com/cover.jpg',
        notes: 'Great read',
        ownerName: 'Alice',
      );

      final restored = Book.fromJson(book.toJson());

      expect(restored.id, book.id);
      expect(restored.isbn, book.isbn);
      expect(restored.title, book.title);
      expect(restored.authors, book.authors);
      expect(restored.coverUrl, book.coverUrl);
      expect(restored.condition, book.condition);
      expect(restored.notes, book.notes);
      expect(restored.addedAt, book.addedAt);
      expect(restored.ownerName, book.ownerName);
    });

    test('null optional fields survive round-trip', () {
      final book = makeBook();
      final restored = Book.fromJson(book.toJson());

      expect(restored.coverUrl, isNull);
      expect(restored.notes, isNull);
      expect(restored.ownerName, isNull);
    });

    test('missing condition in json defaults to good', () {
      final json = makeBook().toJson()..remove('condition');
      final restored = Book.fromJson(json);

      expect(restored.condition, BookCondition.good);
    });

    test('all BookCondition values survive round-trip', () {
      for (final condition in BookCondition.values) {
        final book = makeBook(condition: condition);
        final restored = Book.fromJson(book.toJson());
        expect(restored.condition, condition);
      }
    });
  });

  group('Book equality', () {
    test('two books with same id are equal', () {
      final a = makeBook(id: 'book-1');
      final b = makeBook(id: 'book-1', title: 'Different Title');

      expect(a, equals(b));
    });

    test('two books with different ids are not equal', () {
      final a = makeBook(id: 'book-1');
      final b = makeBook(id: 'book-2');

      expect(a, isNot(equals(b)));
    });

    test('hashCode is consistent with equality', () {
      final a = makeBook(id: 'book-1');
      final b = makeBook(id: 'book-1');

      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('Book.copyWith', () {
    test('copies with updated title only', () {
      final original = makeBook();
      final updated = original.copyWith(title: 'Animal Farm');

      expect(updated.title, 'Animal Farm');
      expect(updated.id, original.id);
      expect(updated.authors, original.authors);
    });

    test('unmodified fields remain identical', () {
      final original = makeBook();
      final copy = original.copyWith();

      expect(copy, equals(original));
    });
  });

  group('BookCondition', () {
    test('all values have non-empty labels', () {
      for (final c in BookCondition.values) {
        expect(c.label, isNotEmpty);
      }
    });
  });
}