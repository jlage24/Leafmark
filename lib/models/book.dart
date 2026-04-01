class Book {
  final String id;
  final String title;
  final String author;
  final String isbn;
  final String coverUrl;
  final String condition;
  final String ownerName; // To display who owns the book on the Browse screen

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.isbn,
    required this.coverUrl,
    required this.condition,
    required this.ownerName,
  });
}