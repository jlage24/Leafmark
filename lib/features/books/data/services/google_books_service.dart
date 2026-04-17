import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/book_fetch_result.dart';

// 1. Define the enum for our new search filters
enum SearchType { title, author, isbn }

/// Fetches book metadata from the Google Books API.
class GoogleBooksService {
  static const String _baseUrl =
      'https://www.googleapis.com/books/v1/volumes';

  // Read in build-time, never hardcoded
  static const String _apiKey =
  String.fromEnvironment('GOOGLE_BOOKS_API_KEY', defaultValue: '');

  final http.Client _client;

  GoogleBooksService({http.Client? client})
      : _client = client ?? http.Client();

  // 2. Existing ISBN query stays exactly as is!
  Future<BookFetchResult?> fetchByIsbn(String isbn) async {
    final uri = Uri.parse(
      '$_baseUrl?q=isbn:$isbn${_apiKey.isNotEmpty ? '&key=$_apiKey' : ''}',
    );

    final http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 10));
    } catch (e) {
      throw BookFetchException('Network error: $e');
    }

    if (response.statusCode != 200) {
      throw BookFetchException(
          'Unexpected status code: ${response.statusCode}');
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw BookFetchException('Failed to parse response: $e');
    }

    final totalItems = json['totalItems'] as int? ?? 0;
    if (totalItems == 0) return null;

    final items = json['items'] as List<dynamic>?;
    if (items == null || items.isEmpty) return null;

    final volumeInfo =
    (items.first as Map<String, dynamic>)['volumeInfo']
    as Map<String, dynamic>?;
    if (volumeInfo == null) return null;

    return BookFetchResult.fromGoogleBooksJson(volumeInfo, isbn);
  }

  // 3. NEW: Multi-result search for the Browse screen
  Future<List<BookFetchResult>> searchBooks(String query, SearchType type) async {
    String queryParam = '';

    // Format the query parameter based on the Sprint 1 requirements
    switch (type) {
      case SearchType.title:
        queryParam = 'intitle:$query';
        break;
      case SearchType.author:
        queryParam = 'inauthor:$query';
        break;
      case SearchType.isbn:
        queryParam = 'isbn:$query';
        break;
    }

    final uri = Uri.parse(
      '$_baseUrl?q=$queryParam${_apiKey.isNotEmpty ? '&key=$_apiKey' : ''}',
    );

    final http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 10));
    } catch (e) {
      throw BookFetchException('Network error: $e');
    }

    if (response.statusCode != 200) {
      throw BookFetchException('Unexpected status code: ${response.statusCode}');
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw BookFetchException('Failed to parse response: $e');
    }

    final items = json['items'] as List<dynamic>?;
    if (items == null || items.isEmpty) return [];

    // Map all results into a list
    return items.map((item) {
      final volumeInfo = (item as Map<String, dynamic>)['volumeInfo'] as Map<String, dynamic>?;

      // Safety check in case a book result is malformed
      if (volumeInfo == null) return null;

      // If we searched by ISBN, pass it down. Otherwise, pass empty string
      // and let fromGoogleBooksJson attempt to extract it from industryIdentifiers.
      final fallbackIsbn = type == SearchType.isbn ? query : '';

      return BookFetchResult.fromGoogleBooksJson(volumeInfo, fallbackIsbn);
    }).where((result) => result != null).cast<BookFetchResult>().toList();
  }
}

class BookFetchException implements Exception {
  final String message;
  const BookFetchException(this.message);

  @override
  String toString() => 'BookFetchException: $message';
}