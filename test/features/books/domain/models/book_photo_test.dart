import 'package:flutter_test/flutter_test.dart';
import 'package:leafmark/features/books/domain/models/book.dart';

void main() {
  Book makeBook({
    List<String> conditionPhotoUrls = const [],
    String? coverUrl = 'https://books.google.com/cover.jpg',
  }) {
    return Book(
      id: 'book1',
      isbn: '9780000000000',
      title: 'Dune',
      authors: 'Frank Herbert',
      coverUrl: coverUrl,
      condition: BookCondition.good,
      notes: 'Good condition',
      addedAt: DateTime(2026, 1, 1),
      ownerName: 'Alice',
      ownerId: 'userA',
      conditionPhotoUrls: conditionPhotoUrls,
      category: 'Sci-Fi',
      location: 'Porto',
    );
  }

  group('Book Photo Model Unit Tests', () {
    test('toJson stores real condition photo urls', () {
      final book = makeBook(
        conditionPhotoUrls: [
          'https://res.cloudinary.com/leafmark/book-front.jpg',
          'https://res.cloudinary.com/leafmark/book-back.jpg',
        ],
      );

      final json = book.toJson();

      expect(json['conditionPhotoUrls'], [
        'https://res.cloudinary.com/leafmark/book-front.jpg',
        'https://res.cloudinary.com/leafmark/book-back.jpg',
      ]);
      expect(json['coverUrl'], 'https://books.google.com/cover.jpg');
    });

    test('fromJson restores real condition photo urls', () {
      final book = Book.fromJson({
        'id': 'book1',
        'isbn': '9780000000000',
        'title': 'Dune',
        'authors': 'Frank Herbert',
        'coverUrl': 'https://books.google.com/cover.jpg',
        'condition': 'good',
        'notes': 'Good condition',
        'addedAt': DateTime(2026, 1, 1).toIso8601String(),
        'ownerName': 'Alice',
        'ownerId': 'userA',
        'lockedBySwapId': null,
        'conditionPhotoUrls': [
          'https://res.cloudinary.com/leafmark/book-front.jpg',
          'https://res.cloudinary.com/leafmark/book-back.jpg',
        ],
        'category': 'Sci-Fi',
        'location': 'Porto',
      });

      expect(book.conditionPhotoUrls.length, 2);
      expect(
        book.conditionPhotoUrls.first,
        'https://res.cloudinary.com/leafmark/book-front.jpg',
      );
      expect(
        book.conditionPhotoUrls.last,
        'https://res.cloudinary.com/leafmark/book-back.jpg',
      );
    });

    test('fromJson uses empty photo list for books without real photos', () {
      final book = Book.fromJson({
        'id': 'book1',
        'isbn': '9780000000000',
        'title': 'Dune',
        'authors': 'Frank Herbert',
        'coverUrl': 'https://books.google.com/cover.jpg',
        'condition': 'good',
        'notes': null,
        'addedAt': DateTime(2026, 1, 1).toIso8601String(),
        'ownerName': 'Alice',
        'ownerId': 'userA',
        'lockedBySwapId': null,
        'category': 'Sci-Fi',
        'location': 'Porto',
      });

      expect(book.conditionPhotoUrls, isEmpty);
      expect(book.coverUrl, 'https://books.google.com/cover.jpg');
    });

    test('book serialization preserves photo urls and metadata', () {
      final original = makeBook(
        conditionPhotoUrls: [
          'https://res.cloudinary.com/leafmark/condition-photo.jpg',
        ],
      );

      final restored = Book.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.condition, original.condition);
      expect(restored.conditionPhotoUrls, original.conditionPhotoUrls);
      expect(restored.coverUrl, original.coverUrl);
      expect(restored.category, original.category);
      expect(restored.location, original.location);
    });

    test(
      'copyWith replaces condition photo urls without changing book identity',
      () {
        final book = makeBook();

        final updated = book.copyWith(
          conditionPhotoUrls: [
            'https://res.cloudinary.com/leafmark/new-photo.jpg',
          ],
        );

        expect(updated.id, book.id);
        expect(updated.title, book.title);
        expect(updated.conditionPhotoUrls, [
          'https://res.cloudinary.com/leafmark/new-photo.jpg',
        ]);
        expect(updated.coverUrl, book.coverUrl);
      },
    );
  });
}
