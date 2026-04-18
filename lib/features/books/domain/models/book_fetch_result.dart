import 'book.dart';

/// The data returned from the Google Books API for a given ISBN or search query.
/// This is a transfer object — it gets mapped to a full [Book] by the user
/// after confirming or editing the pre-filled form, or when displaying search results.
class BookFetchResult {
  final String isbn;
  final String title;
  final String authors;
  final String? coverUrl;
  final String? description;
  final String? publisher;
  final String? publishedDate;
  final int? pageCount;

  const BookFetchResult({
    required this.isbn,
    required this.title,
    required this.authors,
    this.coverUrl,
    this.description,
    this.publisher,
    this.publishedDate,
    this.pageCount,
  });

  factory BookFetchResult.fromGoogleBooksJson(
      Map<String, dynamic> json,
      String fallbackIsbn,
      ) {
    final rawAuthors = json['authors'];
    final authors = rawAuthors is List
        ? rawAuthors.join(', ')
        : 'Unknown author';

    // Extract the ISBN
    String extractedIsbn = fallbackIsbn;
    final identifiers = json['industryIdentifiers'] as List<dynamic>?;

    if (identifiers != null) {
      String? isbn13;
      String? isbn10;

      for (var id in identifiers) {
        if (id is Map<String, dynamic>) {
          final type = id['type'] as String?;
          final identifier = id['identifier'] as String?;
          if (type == 'ISBN_13') isbn13 = identifier;
          if (type == 'ISBN_10') isbn10 = identifier;
        }
      }
      // Use the first ISBN found
      extractedIsbn = isbn13 ?? isbn10 ?? fallbackIsbn;
    }

    // Get the cover
    final imageLinks = json['imageLinks'] as Map<String, dynamic>?;
    String? coverUrl = (imageLinks?['thumbnail'] ?? imageLinks?['smallThumbnail']) as String?;

    if (coverUrl != null) {
      coverUrl = coverUrl.replaceFirst('http://', 'https://');
    } else if (extractedIsbn.isNotEmpty) {
      // Uses the real ISBN to get the cover from OpenLibrary if Google fails
      coverUrl = 'https://covers.openlibrary.org/b/isbn/$extractedIsbn-L.jpg';
    }

    return BookFetchResult(
      isbn: extractedIsbn,
      title: (json['title'] as String?) ?? 'Unknown title',
      authors: authors,
      coverUrl: coverUrl,
      description: json['description'] as String?,
      publisher: json['publisher'] as String?,
      publishedDate: json['publishedDate'] as String?,
      pageCount: json['pageCount'] as int?,
    );
  }

  /// Creates an empty result
  /// used when the API returns no results.
  factory BookFetchResult.empty(String isbn) => BookFetchResult(
    isbn: isbn,
    title: '',
    authors: '',
  );

  BookFetchResult copyWith({
    String? isbn,
    String? title,
    String? authors,
    String? coverUrl,
    String? description,
    String? publisher,
    String? publishedDate,
    int? pageCount,
  }) {
    return BookFetchResult(
      isbn: isbn ?? this.isbn,
      title: title ?? this.title,
      authors: authors ?? this.authors,
      coverUrl: coverUrl ?? this.coverUrl,
      description: description ?? this.description,
      publisher: publisher ?? this.publisher,
      publishedDate: publishedDate ?? this.publishedDate,
      pageCount: pageCount ?? this.pageCount,
    );
  }

  /// Converts the fetch result into a canonical Book model for UI display
  Book toBook() {
    return Book(
      id: isbn.isNotEmpty ? isbn : title.hashCode.toString(),
      title: title,
      authors: authors,
      isbn: isbn,
      coverUrl: coverUrl ?? 'https://via.placeholder.com/150',
      condition: BookCondition.good,
      addedAt: DateTime.now(), // This is fine for addedAt, just not for ID!
      ownerName: 'Google Books',
    );
  }

  @override
  String toString() =>
      'BookFetchResult(isbn: $isbn, title: $title, authors: $authors)';
}