import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/book.dart';

class BookShelfProvider extends ChangeNotifier {
  String? _uid;
  String _storageKey(String uid) => 'leafmark_shelf_$uid';

  List<Book> _books = [];
  List<Book> get books => List.unmodifiable(_books);

  Future<void> loadBooks(String uid) async {
    _uid = uid;
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getStringList(_storageKey(uid)) ?? [];
    _books = raw.map((e) => Book.fromJson(jsonDecode(e))).toList();
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
    if (_uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey(_uid!),
      _books.map((b) => jsonEncode(b.toJson())).toList(),
    );
  }

  Future<void> clearBooks() async {
    _uid = null;
    _books = [];
    notifyListeners();
  }
}