class Book {
  final String id;
  final String isbn;
  final String title;
  final String authors;
  final String? coverUrl;
  final BookCondition condition;
  final String? notes;
  final DateTime addedAt;
  final String? ownerName;
  final String? ownerId;
  final String? lockedBySwapId;
  final List<String> conditionPhotoUrls;
  final String? category;
  final String? location;
  final String? lastExchangeId;

  const Book({
    required this.id,
    required this.isbn,
    required this.title,
    required this.authors,
    this.coverUrl,
    required this.condition,
    this.notes,
    required this.addedAt,
    this.ownerName,
    this.ownerId,
    this.lockedBySwapId,
    this.conditionPhotoUrls = const [],
    this.category,
    this.location,
    this.lastExchangeId,
  });

  bool get isLocked => lockedBySwapId != null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'isbn': isbn,
    'title': title,
    'authors': authors,
    'coverUrl': coverUrl,
    'condition': condition.name,
    'notes': notes,
    'addedAt': addedAt.toIso8601String(),
    'ownerName': ownerName,
    'ownerId': ownerId,
    'lockedBySwapId': lockedBySwapId,
    'conditionPhotoUrls': conditionPhotoUrls,
    'category': category,
    'location': location,
    'lastExchangeId': lastExchangeId,
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
    ownerName: json['ownerName'] as String?,
    ownerId: json['ownerId'] as String?,
    lockedBySwapId: json['lockedBySwapId'] as String?,
    conditionPhotoUrls: (json['conditionPhotoUrls'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList() ??
        const [],
    category: json['category'] as String?,
    location: json['location'] as String?,
    lastExchangeId: json['lastExchangeId'] as String?,
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
    String? ownerName,
    String? ownerId,
    Object? lockedBySwapId = _sentinel,
    List<String>? conditionPhotoUrls,
    String? category,
    String? location,
    String? lastExchangeId,
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
        ownerName: ownerName ?? this.ownerName,
        ownerId: ownerId ?? this.ownerId,
        lockedBySwapId: lockedBySwapId == _sentinel
            ? this.lockedBySwapId
            : lockedBySwapId as String?,
        conditionPhotoUrls: conditionPhotoUrls ?? this.conditionPhotoUrls,
        category: category ?? this.category,
        location: location ?? this.location,
        lastExchangeId: lastExchangeId ?? this.lastExchangeId,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Book && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Book(id: $id, title: $title, isbn: $isbn)';
}

const Object _sentinel = Object();

const List<String> bookCategories = [
  'Fiction',
  'Non-Fiction',
  'Sci-Fi',
  'Fantasy',
  'Romance',
  'Mystery',
  'Academic',
  'Thriller',
];

enum BookCondition {
  mint('Mint'),
  good('Good'),
  fair('Fair'),
  poor('Poor');

  final String label;
  const BookCondition(this.label);
}