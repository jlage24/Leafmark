import '../models/book.dart';

final List<Book> browseDummyBooks = [
  Book(
    id: 'b1',
    title: 'The Pragmatic Programmer',
    author: 'David Thomas, Andrew Hunt',
    isbn: '9780135957059',
    coverUrl: 'https://m.media-amazon.com/images/I/51W1s%2BZX+sL._SY445_SX342_.jpg',
    condition: 'Good',
    ownerName: 'Mafalda',
  ),
  Book(
    id: 'b2',
    title: 'Clean Code',
    author: 'Robert C. Martin',
    isbn: '9780132350884',
    coverUrl: 'https://m.media-amazon.com/images/I/41xShlnTZTL._SX376_BO1,204,203,200_.jpg',
    condition: 'Like New',
    ownerName: 'João',
  ),
  Book(
    id: 'b3',
    title: 'Design Patterns',
    author: 'Erich Gamma, Richard Helm',
    isbn: '9780201633610',
    coverUrl: 'https://m.media-amazon.com/images/I/51szD9HC9pL._SX395_BO1,204,203,200_.jpg',
    condition: 'Fair',
    ownerName: 'David',
  ),
];