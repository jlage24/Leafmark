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
  final String? category;

  const BookFetchResult({
    required this.isbn,
    required this.title,
    required this.authors,
    this.coverUrl,
    this.description,
    this.publisher,
    this.publishedDate,
    this.pageCount,
    this.category,
  });

  factory BookFetchResult.fromGoogleBooksJson(
    Map<String, dynamic> json,
    String fallbackIsbn,
  ) {
    final rawAuthors = json['authors'];
    final authors = rawAuthors is List
        ? rawAuthors.join(', ')
        : 'Unknown author';

    String extractedIsbn = fallbackIsbn;
    final identifiers = json['industryIdentifiers'] as List<dynamic>?;

    if (identifiers != null) {
      String? isbn13;
      String? isbn10;

      for (final id in identifiers) {
        if (id is Map<String, dynamic>) {
          final type = id['type'] as String?;
          final identifier = id['identifier'] as String?;

          if (type == 'ISBN_13') isbn13 = identifier;
          if (type == 'ISBN_10') isbn10 = identifier;
        }
      }

      extractedIsbn = isbn13 ?? isbn10 ?? fallbackIsbn;
    }

    final imageLinks = json['imageLinks'] as Map<String, dynamic>?;
    String? coverUrl =
        (imageLinks?['thumbnail'] ?? imageLinks?['smallThumbnail']) as String?;

    if (coverUrl != null) {
      coverUrl = coverUrl.replaceFirst('http://', 'https://');
    } else if (extractedIsbn.isNotEmpty) {
      coverUrl = 'https://covers.openlibrary.org/b/isbn/$extractedIsbn-L.jpg';
    }

    final rawCategories = json['categories'];
    final category = _normalizeGoogleBooksCategory(rawCategories);

    final rawTitle = (json['title'] as String?) ?? 'Unknown title';

    return BookFetchResult(
      isbn: extractedIsbn,
      title: _toTitleCase(rawTitle),
      authors: authors,
      coverUrl: coverUrl,
      description: json['description'] as String?,
      publisher: json['publisher'] as String?,
      publishedDate: json['publishedDate'] as String?,
      pageCount: json['pageCount'] as int?,
      category: category,
    );
  }

  factory BookFetchResult.empty(String isbn) =>
      BookFetchResult(isbn: isbn, title: '', authors: '');

  BookFetchResult copyWith({
    String? isbn,
    String? title,
    String? authors,
    String? coverUrl,
    String? description,
    String? publisher,
    String? publishedDate,
    int? pageCount,
    String? category,
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
      category: category ?? this.category,
    );
  }

  Book toBook() {
    return Book(
      id: isbn.isNotEmpty ? isbn : title.hashCode.toString(),
      title: title,
      authors: authors,
      isbn: isbn,
      coverUrl: coverUrl ?? 'https://via.placeholder.com/150',
      condition: BookCondition.good,
      addedAt: DateTime.now(),
      ownerName: 'Google Books',
      category: category,
    );
  }

  static String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    
    final exceptions = {
      'a', 'an', 'and', 'as', 'at', 'but', 'by', 'for', 'if', 'in', 'of', 'on', 'or', 'the', 'to', 'with'
    };
    
    final words = text.split(' ');
    
    for (var i = 0; i < words.length; i++) {
      final word = words[i];
      if (word.isEmpty) continue;
      
      final lowerWord = word.toLowerCase();
      if (i > 0 && i < words.length - 1 && exceptions.contains(lowerWord)) {
        words[i] = lowerWord;
      } else {
        words[i] = word[0].toUpperCase() + (word.length > 1 ? word.substring(1).toLowerCase() : '');
      }
    }
    
    return words.join(' ');
  }

  static String? _normalizeGoogleBooksCategory(dynamic rawCategories) {
    if (rawCategories is! List || rawCategories.isEmpty) return null;

    final joined = rawCategories
        .whereType<String>()
        .join(' ')
        .toLowerCase()
        .replaceAll('&', 'and');

    if (joined.trim().isEmpty) return null;

    if (_containsAny(joined, ['juvenile', 'young adult', 'children', 'teen'])) {
      return 'Children & Young Adult';
    }

    if (_containsAny(joined, ['comic', 'comics', 'graphic novel', 'manga'])) {
      return 'Comics & Manga';
    }

    if (_containsAny(joined, [
      'education',
      'study',
      'textbook',
      'academic',
      'mathematics',
      'computer',
      'programming',
      'engineering',
      'medicine',
      'law',
    ])) {
      return 'Academic';
    }

    if (_containsAny(joined, [
      'biography',
      'autobiography',
      'history',
      'science',
      'technology',
      'business',
      'economics',
      'psychology',
      'philosophy',
      'self-help',
      'religion',
      'political',
      'travel',
      'health',
      'cooking',
      'true crime',
      'social science',
    ])) {
      return 'Non-Fiction';
    }

    if (_containsAny(joined, [
      'fiction',
      'fantasy',
      'science fiction',
      'romance',
      'mystery',
      'thriller',
      'horror',
      'adventure',
      'literature',
      'classics',
      'poetry',
      'drama',
    ])) {
      return 'Fiction';
    }

    return 'Other';
  }

  static bool _containsAny(String source, List<String> needles) {
    return needles.any(source.contains);
  }

  @override
  String toString() =>
      'BookFetchResult(isbn: $isbn, title: $title, authors: $authors, category: $category)';
}
