import 'package:flutter/foundation.dart';
import '../../domain/models/book.dart';
import '../../data/repositories/shelf_repository.dart';

/// Minimal ChangeNotifier that wraps [ShelfRepository] and notifies listeners
/// whenever the shelf is mutated.
///
///   - loadBooks() called on init
///   - isLoading / error states
///   - removeBook()
///
class BookShelfProvider extends ChangeNotifier {
  final ShelfRepository _repository;

  BookShelfProvider({ShelfRepository? repository})
      : _repository = repository ?? ShelfRepository();

  List<Book> _books = [];
  List<Book> get books => List.unmodifiable(_books);

  /// Loads books from local storage. Call once from main.dart or the shelf screen.
  Future<void> loadBooks() async {
    _books = await _repository.getBooks();
    notifyListeners();
  }

  /// Persists [book] and notifies listeners so any listening screen rebuilds.
  Future<void> addBook(Book book) async {
    await _repository.addBook(book);
    _books = await _repository.getBooks();
    notifyListeners();
  }

  /// Removes [bookId] and notifies listeners.
  Future<void> removeBook(String bookId) async {
    await _repository.removeBook(bookId);
    _books.removeWhere((b) => b.id == bookId);
    notifyListeners();
  }
}