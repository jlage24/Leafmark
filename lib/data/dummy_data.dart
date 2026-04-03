import '../features/books/domain/models/book.dart';

final List<Book> browseDummyBooks = [
  Book(
    id: 'b1',
    title: 'The Pragmatic Programmer',
    authors: 'David Thomas, Andrew Hunt',
    isbn: '9780135957059',
    coverUrl:
    'https://m.media-amazon.com/images/I/51W1s%2BZX+sL._SY445_SX342_.jpg',
    condition: BookCondition.good,
    addedAt: DateTime(2024, 1, 1),
    ownerName: 'Mafalda',
  ),
  Book(
    id: 'b2',
    title: 'Clean Code',
    authors: 'Robert C. Martin',
    isbn: '9780132350884',
    coverUrl:
    'https://m.media-amazon.com/images/I/41xShlnTZTL._SX376_BO1,204,203,200_.jpg',
    condition: BookCondition.mint,
    addedAt: DateTime(2024, 1, 2),
    ownerName: 'João',
  ),
  Book(
    id: 'b3',
    title: 'Design Patterns',
    authors: 'Erich Gamma, Richard Helm',
    isbn: '9780201633610',
    coverUrl:
    'https://m.media-amazon.com/images/I/51szD9HC9pL._SX395_BO1,204,203,200_.jpg',
    condition: BookCondition.fair,
    addedAt: DateTime(2024, 1, 3),
    ownerName: 'David',
  ),
];