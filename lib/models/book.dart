class Book {
  final String id;
  final String title;
  final String author;
  final String isbn;
  final String coverUrl;
  final String condition;
  final String ownerName;

  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.isbn,
    required this.coverUrl,
    required this.condition,
    required this.ownerName,
  });

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? isbn,
    String? coverUrl,
    String? condition,
    String? ownerName,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      isbn: isbn ?? this.isbn,
      coverUrl: coverUrl ?? this.coverUrl,
      condition: condition ?? this.condition,
      ownerName: ownerName ?? this.ownerName,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Book && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}