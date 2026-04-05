import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/book.dart';

class BookShelfProvider extends ChangeNotifier {
  static const _storageKey = 'leafmark_shelf';

  List<Book> _books = [];
  List<Book> get books => List.unmodifiable(_books);

  Future<void> loadBooks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];
    _books = raw
        .map((e) => Book.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
    notifyListeners();
  }

  Future<void> addBook(Book book) async {
    _books.add(book);
    notifyListeners();
    await _persist();
  }

  Future<void> removeBook(String id) async {
    _books.removeWhere((b) => b.id == id);
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = _books.map((b) => jsonEncode(b.toJson())).toList();
    await prefs.setStringList(_storageKey, raw);
  }
}