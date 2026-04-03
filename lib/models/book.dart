class Book {
  final String id;
  final String isbn;
  final String title;
  final String authors;
  final String? coverUrl;
  final BookCondition condition;
  final String? notes;
  final DateTime addedAt;

  const Book({
    required this.id,
    required this.isbn,
    required this.title,
    required this.authors,
    this.coverUrl,
    required this.condition,
    this.notes,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'isbn': isbn,
    'title': title,
    'authors': authors,
    'coverUrl': coverUrl,
    'condition': condition.name,
    'notes': notes,
    'addedAt': addedAt.toIso8601String(),
  };

  factory Book.fromJson(Map<String, dynamic> json) => Book(
    id: json['id'] as String,
    isbn: json['isbn'] as String,
    title: json['title'] as String,
    authors: json['authors'] as String,
    coverUrl: json['coverUrl'] as String?,
    condition: BookCondition.values.byName(
      (json['condition'] as String?) ?? BookCondition.good.name,
    ),
    notes: json['notes'] as String?,
    addedAt: DateTime.parse(json['addedAt'] as String),
  );

  Book copyWith({
    String? id,
    String? isbn,
    String? title,
    String? authors,
    String? coverUrl,
    BookCondition? condition,
    String? notes,
    DateTime? addedAt,
  }) =>
      Book(
        id: id ?? this.id,
        isbn: isbn ?? this.isbn,
        title: title ?? this.title,
        authors: authors ?? this.authors,
        coverUrl: coverUrl ?? this.coverUrl,
        condition: condition ?? this.condition,
        notes: notes ?? this.notes,
        addedAt: addedAt ?? this.addedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Book && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Book(id: $id, title: $title, isbn: $isbn)';
}

enum BookCondition {
  mint('Mint'),
  good('Good'),
  fair('Fair'),
  poor('Poor');

  final String label;
  const BookCondition(this.label);
}