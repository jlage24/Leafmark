import 'package:flutter/material.dart';
import '../../../../features/books/data/services/google_books_service.dart';
import '../../../../features/books/domain/models/book_fetch_result.dart';

class SearchProvider extends ChangeNotifier {
  final GoogleBooksService _booksService;

  SearchProvider({GoogleBooksService? booksService})
      : _booksService = booksService ?? GoogleBooksService();

  // State variables
  List<BookFetchResult> _results = [];
  bool _isLoading = false;
  String? _errorMessage;
  SearchType _searchType = SearchType.title; // Default to title search

  // Getters for the UI to read
  List<BookFetchResult> get results => _results;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  SearchType get searchType => _searchType;

  // Update the selected filter (Title / Author / ISBN)
  void setSearchType(SearchType type) {
    if (_searchType != type) {
      _searchType = type;
      notifyListeners();
    }
  }

  // Clear results (useful when the user clears the search bar)
  void clearSearch() {
    _results = [];
    _errorMessage = null;
    notifyListeners();
  }

  // Perform the actual search
  Future<void> performSearch(String query) async {
    if (query.trim().isEmpty) {
      clearSearch();
      return;
    }

    _isLoading = true;
    _errorMessage = null; // Clear previous errors
    notifyListeners();

    try {
      if (_searchType == SearchType.isbn) {
        // Use the existing ISBN method for single results
        final result = await _booksService.fetchByIsbn(query.trim());
        _results = result != null ? [result] : [];
      } else {
        // Use your newly created multi-result method
        _results = await _booksService.searchBooks(query.trim(), _searchType);
      }

      // REC 2 FIX: Removed the block that set an error message for empty results.
      // The UI will now handle _results.isEmpty natively without treating it as an error.

    } catch (e) {
      _errorMessage = 'Failed to fetch books. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}