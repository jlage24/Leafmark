import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:leafmark/features/books/data/services/google_books_service.dart';
import 'package:leafmark/features/books/domain/models/book_fetch_result.dart';


void main() {
  group('BookFetchResult.fromGoogleBooksJson', () {
    test('parses all fields correctly from a standard response', () {
      final json = {
        'title': 'The Name of the Rose',
        'authors': ['Umberto Eco'],
        'publisher': 'Harcourt',
        'publishedDate': '1980',
        'description': 'A medieval mystery.',
        'pageCount': 502,
        'imageLinks': {
          'thumbnail':
          'http://books.google.com/books/content?id=abc&zoom=1&edge=curl',
        },
      };

      final result = BookFetchResult.fromGoogleBooksJson(json, '9780156633505');

      expect(result.isbn, '9780156633505');
      expect(result.title, 'The Name of the Rose');
      expect(result.authors, 'Umberto Eco');
      expect(result.publisher, 'Harcourt');
      expect(result.publishedDate, '1980');
      expect(result.pageCount, 502);
      expect(result.description, 'A medieval mystery.');
    });

    test('upgrades cover URL from http to https', () {
      final json = {
        'title': 'Test',
        'imageLinks': {
          'thumbnail': 'http://books.google.com/books/content?zoom=1',
        },
      };
      final result = BookFetchResult.fromGoogleBooksJson(json, '123');
      expect(result.coverUrl, startsWith('https://'));
    });

    test('requests zoom=2 in cover URL', () {
      final json = {
        'title': 'Test',
        'imageLinks': {
          'thumbnail': 'http://books.google.com/books/content?zoom=1',
        },
      };
      final result = BookFetchResult.fromGoogleBooksJson(json, '123');
      expect(result.coverUrl, contains('zoom=2'));
    });

    test('handles multiple authors joined by comma', () {
      final json = {
        'title': 'Good Omens',
        'authors': ['Terry Pratchett', 'Neil Gaiman'],
      };
      final result = BookFetchResult.fromGoogleBooksJson(json, '9780060853983');
      expect(result.authors, 'Terry Pratchett, Neil Gaiman');
    });

    test('falls back to "Unknown author" when authors key is absent', () {
      final json = {'title': 'Anonymous Work'};
      final result = BookFetchResult.fromGoogleBooksJson(json, '000');
      expect(result.authors, 'Unknown author');
    });

    test('falls back to "Unknown title" when title key is absent', () {
      final json = <String, dynamic>{};
      final result = BookFetchResult.fromGoogleBooksJson(json, '000');
      expect(result.title, 'Unknown title');
    });

    test('coverUrl is null when imageLinks is absent', () {
      final json = {'title': 'No Cover'};
      final result = BookFetchResult.fromGoogleBooksJson(json, '000');
      expect(result.coverUrl, isNull);
    });
  });

  group('BookFetchResult.empty', () {
    test('creates result with given isbn and empty strings', () {
      final result = BookFetchResult.empty('9781234567890');
      expect(result.isbn, '9781234567890');
      expect(result.title, isEmpty);
      expect(result.authors, isEmpty);
    });
  });


  group('GoogleBooksService.fetchByIsbn', () {
    test('returns BookFetchResult when API returns a match', () async {
      final fakeResponse = jsonEncode({
        'totalItems': 1,
        'items': [
          {
            'volumeInfo': {
              'title': 'Dune',
              'authors': ['Frank Herbert'],
              'pageCount': 412,
              'imageLinks': {
                'thumbnail':
                'https://books.google.com/books/content?id=xyz&zoom=1',
              },
            },
          }
        ],
      });

      final client = MockClient((_) async =>
          http.Response(fakeResponse, 200));

      final service = GoogleBooksService(client: client);
      final result = await service.fetchByIsbn('9780441013593');

      expect(result, isNotNull);
      expect(result!.title, 'Dune');
      expect(result.authors, 'Frank Herbert');
      expect(result.pageCount, 412);
    });

    test('returns null when totalItems is 0', () async {
      final fakeResponse = jsonEncode({'totalItems': 0});
      final client = MockClient((_) async =>
          http.Response(fakeResponse, 200));

      final service = GoogleBooksService(client: client);
      final result = await service.fetchByIsbn('0000000000000');

      expect(result, isNull);
    });

    test('throws BookFetchException on non-200 status', () async {
      final client = MockClient((_) async => http.Response('Error', 503));

      final service = GoogleBooksService(client: client);
      expect(
            () => service.fetchByIsbn('9780000000000'),
        throwsA(isA<BookFetchException>()),
      );
    });

    test('throws BookFetchException on malformed JSON', () async {
      final client =
      MockClient((_) async => http.Response('not json!!', 200));

      final service = GoogleBooksService(client: client);
      expect(
            () => service.fetchByIsbn('9780000000001'),
        throwsA(isA<BookFetchException>()),
      );
    });
  });
}