import 'package:uuid/uuid.dart';

class Book {
  final String id;
  final String isbn;
  final String title;
  final String author;
  final String? coverUrl;
  final String? description;
  final String? publisher;
  final String? publishedDate;
  final String? pageCount;
  final List<String> categories;
  final BookShelfStatus shelfStatus;
  final DateTime addedAt;

  Book({
    String? id,
    required this.isbn,
    required this.title,
    required this.author,
    this.coverUrl,
    this.description,
    this.publisher,
    this.publishedDate,
    this.pageCount,
    List<String>? categories,
    this.shelfStatus = BookShelfStatus.shelf,
    DateTime? addedAt,
  })  : id = id ?? const Uuid().v4(),
        categories = categories ?? [],
        addedAt = addedAt ?? DateTime.now();

  Book copyWith({
    String? title,
    String? author,
    String? coverUrl,
    String? description,
    String? publisher,
    String? publishedDate,
    String? pageCount,
    List<String>? categories,
    BookShelfStatus? shelfStatus,
  }) {
    return Book(
      id: id,
      isbn: isbn,
      title: title ?? this.title,
      author: author ?? this.author,
      coverUrl: coverUrl ?? this.coverUrl,
      description: description ?? this.description,
      publisher: publisher ?? this.publisher,
      publishedDate: publishedDate ?? this.publishedDate,
      pageCount: pageCount ?? this.pageCount,
      categories: categories ?? this.categories,
      shelfStatus: shelfStatus ?? this.shelfStatus,
      addedAt: addedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'isbn': isbn,
    'title': title,
    'author': author,
    'coverUrl': coverUrl,
    'description': description,
    'publisher': publisher,
    'publishedDate': publishedDate,
    'pageCount': pageCount,
    'categories': categories,
    'shelfStatus': shelfStatus.name,
    'addedAt': addedAt.toIso8601String(),
  };

  factory Book.fromJson(Map<String, dynamic> json) => Book(
    id: json['id'] as String,
    isbn: json['isbn'] as String,
    title: json['title'] as String,
    author: json['author'] as String,
    coverUrl: json['coverUrl'] as String?,
    description: json['description'] as String?,
    publisher: json['publisher'] as String?,
    publishedDate: json['publishedDate'] as String?,
    pageCount: json['pageCount'] as String?,
    categories: List<String>.from(json['categories'] ?? []),
    shelfStatus: BookShelfStatus.values.byName(
      json['shelfStatus'] as String? ?? 'shelf',
    ),
    addedAt: DateTime.parse(json['addedAt'] as String),
  );
}

enum BookShelfStatus {
  shelf,
  wishlist,
  swapping,
  inProgress,
}

extension BookShelfStatusLabel on BookShelfStatus {
  String get label {
    switch (this) {
      case BookShelfStatus.shelf:
        return 'My Shelf';
      case BookShelfStatus.wishlist:
        return 'Wishlist';
      case BookShelfStatus.swapping:
        return 'Available for Swap';
      case BookShelfStatus.inProgress:
        return 'In Progress';
    }
  }
}