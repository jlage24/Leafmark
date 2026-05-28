import 'package:flutter_test/flutter_test.dart';
import 'package:leafmark/features/auth/domain/models/app_user.dart';
import 'package:leafmark/features/search/data/services/user_search_service.dart';
import 'package:leafmark/features/search/presentation/providers/search_provider.dart';
import 'package:leafmark/features/books/data/services/google_books_service.dart';

class FakeUserSearchService implements UserSearchRepository {
  @override
  Future<List<AppUser>> searchUsers(
      String query, {
        String? excludeUid,
        int limit = 20,
      }) async {
    return [];
  }
}

void main() {
  group('SearchProvider', () {
    late SearchProvider provider;

    setUp(() {
      provider = SearchProvider(
        userSearchService: FakeUserSearchService(),
      );
    });

    test('Initial state should be empty and should not be loading', () {
      expect(provider.results, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.searchType, SearchType.title);
    });

    test('Clearing the search should reset results and error messages', () {
      provider.clearSearch();

      expect(provider.results, isEmpty);
      expect(provider.errorMessage, isNull);
    });

    test('Changing the search type should update the searchType and notify listeners', () {
      var notified = false;
      provider.addListener(() => notified = true);

      provider.setSearchType(SearchType.author);

      expect(provider.searchType, SearchType.author);
      expect(notified, isTrue);
    });
  });
}