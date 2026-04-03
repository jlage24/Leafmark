/// The data returned from the Google Books API for a given ISBN.
/// This is a transfer object — it gets mapped to a full [Book] by the user
/// after confirming or editing the pre-filled form.
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
      String isbn,
      ) {
    final rawAuthors = json['authors'];
    final authors = rawAuthors is List
        ? (rawAuthors as List<dynamic>).join(', ')
        : 'Unknown author';

    final imageLinks = json['imageLinks'] as Map<String, dynamic>?;
    String? coverUrl = (imageLinks?['thumbnail'] ?? imageLinks?['smallThumbnail']) as String?;
    if (coverUrl != null) {
      coverUrl = coverUrl.replaceFirst('http://', 'https://');
    } else {
      coverUrl = 'https://covers.openlibrary.org/b/isbn/$isbn-L.jpg';
    }

    return BookFetchResult(
      isbn: isbn,
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

  @override
  String toString() =>
      'BookFetchResult(isbn: $isbn, title: $title, authors: $authors)';
}