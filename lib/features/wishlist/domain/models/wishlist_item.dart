import 'package:cloud_firestore/cloud_firestore.dart';

class WishlistItem {
  final String id;
  final String title;
  final List<String> authors;
  final String? isbn;
  final DateTime addedAt;

  WishlistItem({
    required this.id,
    required this.title,
    required this.authors,
    this.isbn,
    required this.addedAt,
  });

  factory WishlistItem.fromMap(Map<String, dynamic> map, String id) =>
      WishlistItem(
        id: id,
        title: map['title'] ?? '',
        authors: List<String>.from(map['authors'] ?? []),
        isbn: map['isbn'] as String?,
        addedAt: (map['addedAt'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toMap() => {
    'title': title,
    'authors': authors,
    if (isbn != null) 'isbn': isbn,
    'addedAt': Timestamp.fromDate(addedAt),
  };
}
