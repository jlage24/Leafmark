import 'package:flutter/material.dart';
import '../../../auth/domain/models/app_user.dart';
import '../../../books/data/services/google_books_service.dart';
import '../../../books/domain/models/book_fetch_result.dart';
import '../../data/services/user_search_service.dart';

enum SearchTarget { books, users }

class SearchProvider extends ChangeNotifier {
  final GoogleBooksService _booksService;
  final UserSearchRepository _userSearchService;

  SearchProvider({
    GoogleBooksService? booksService,
    UserSearchRepository? userSearchService,
  }) : _booksService = booksService ?? GoogleBooksService(),
       _userSearchService = userSearchService ?? UserSearchService();

  List<BookFetchResult> _bookResults = [];
  List<AppUser> _userResults = [];

  bool _isLoading = false;
  String? _errorMessage;

  SearchTarget _target = SearchTarget.books;
  SearchType _searchType = SearchType.title;

  List<BookFetchResult> get results => _bookResults;
  List<BookFetchResult> get bookResults => _bookResults;
  List<AppUser> get userResults => _userResults;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  SearchTarget get target => _target;
  SearchType get searchType => _searchType;

  void setTarget(SearchTarget target) {
    if (_target == target) return;

    _target = target;
    _errorMessage = null;
    notifyListeners();
  }

  void setSearchType(SearchType type) {
    if (_searchType != type) {
      _searchType = type;
      notifyListeners();
    }
  }

  void clearSearch() {
    _bookResults = [];
    _userResults = [];
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> performSearch(String query, {String? currentUid}) async {
    if (query.trim().isEmpty) {
      clearSearch();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_target == SearchTarget.users) {
        _userResults = await _userSearchService.searchUsers(
          query,
          excludeUid: currentUid,
        );
      } else {
        if (_searchType == SearchType.isbn) {
          final result = await _booksService.fetchByIsbn(query.trim());
          _bookResults = result != null ? [result] : [];
        } else {
          _bookResults = await _booksService.searchBooks(
            query.trim(),
            _searchType,
          );
        }
      }
    } catch (e) {
      if (e is BookFetchException) {
        final msg = e.message.toLowerCase();

        if (msg.contains('503') || msg.contains('service unavailable')) {
          _errorMessage =
              'The book service is temporarily unavailable. Please try again in a moment.';
        } else if (msg.contains('network') || msg.contains('timeout')) {
          _errorMessage = 'No internet connection. Please check your network.';
        } else {
          _errorMessage = 'API Error: ${e.message}';
        }
      } else {
        _errorMessage = 'An unexpected error occurred: $e';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
