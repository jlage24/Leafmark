import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';

/// Local shelf persistence using shared_preferences.
/// No backend is needed for the Sprint 0 prototype.
class ShelfRepository {
  static const String _kShelfKey = 'leafmark_shelf_books';

  /// Returns all books on the user's shelf, sorted by most recently added.
  Future<List<Book>> getBooks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kShelfKey) ?? [];

    return raw
        .map((e) {
      try {
        return Book.fromJson(jsonDecode(e) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    })
        .whereType<Book>()
        .toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
  }

  /// Persists [book] to the shelf. Replaces any existing book with the same id.
  Future<void> addBook(Book book) async {
    final books = await getBooks();
    final index = books.indexWhere((b) => b.id == book.id);
    if (index >= 0) {
      books[index] = book;
    } else {
      books.insert(0, book);
    }
    await _persist(books);
  }

  /// Removes the book with [bookId] from the shelf.
  Future<void> removeBook(String bookId) async {
    final books = await getBooks();
    books.removeWhere((b) => b.id == bookId);
    await _persist(books);
  }

  Future<void> _persist(List<Book> books) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _kShelfKey,
      books.map((b) => jsonEncode(b.toJson())).toList(),
    );
  }

  /// Clears all books — useful for tests and the dev menu.
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kShelfKey);
  }
}