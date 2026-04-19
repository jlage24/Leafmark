import 'package:flutter_test/flutter_test.dart';
import 'package:leafmark/features/search/presentation/providers/search_provider.dart';
import 'package:leafmark/features/books/data/services/google_books_service.dart';

void main() {
  group('SearchProvider', () {
    late SearchProvider provider;

    setUp(() {
      provider = SearchProvider();
    });

    test('estado inicial deve estar vazio e não deve estar a carregar', () {
      expect(provider.results, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.searchType, SearchType.title);
    });

    test('limpar pesquisa deve resetar resultados e mensagens de erro', () {
      provider.clearSearch();

      expect(provider.results, isEmpty);
      expect(provider.errorMessage, isNull);
    });

    test('alterar o tipo de pesquisa deve atualizar o searchType e notificar listeners', () {
      var notified = false;
      provider.addListener(() => notified = true);

      provider.setSearchType(SearchType.author);

      expect(provider.searchType, SearchType.author);
      expect(notified, isTrue);
    });
  });
}