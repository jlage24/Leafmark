import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/search_provider.dart';
import '../../../../features/books/data/services/google_books_service.dart';
import '../../../books/presentation/widgets/book_card.dart';
import '../../../books/presentation/screens/book_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<bool> _hasText = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _searchController.dispose();
    _hasText.dispose();
    super.dispose();
  }

  void _clearSearch(SearchProvider provider) {
    _searchController.clear();
    _hasText.value = false;
    provider.clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    final searchProvider = Provider.of<SearchProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Column(
        children: [
          // 1. Search Bar & Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for books...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: ValueListenableBuilder<bool>(
                        valueListenable: _hasText,
                        builder: (context, hasText, child) => hasText
                            ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _clearSearch(searchProvider),
                        )
                            : const SizedBox.shrink(),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSubmitted: (value) => searchProvider.performSearch(value),
                    onChanged: (value) => _hasText.value = value.isNotEmpty,
                  ),
                ),
                const SizedBox(width: 8),

                // Fixed width to prevent infinite width constraint from theme
                SizedBox(
                  width: 56,
                  height: 56,
                  child: FilledButton(
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      searchProvider.performSearch(_searchController.text);
                    },
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Icon(Icons.arrow_forward),
                  ),
                ),
              ],
            ),
          ),

          // 2. Filter Toggle (Title / Author / ISBN)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<SearchType>(
                segments: const [
                  ButtonSegment(value: SearchType.title, label: Text('Title')),
                  ButtonSegment(value: SearchType.author, label: Text('Author')),
                  ButtonSegment(value: SearchType.isbn, label: Text('ISBN')),
                ],
                selected: {searchProvider.searchType},
                onSelectionChanged: (Set<SearchType> newSelection) {
                  searchProvider.setSearchType(newSelection.first);
                  if (_searchController.text.isNotEmpty) {
                    searchProvider.performSearch(_searchController.text);
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 3. Results Area
          Expanded(
            child: _buildResults(searchProvider, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(SearchProvider provider, ThemeData theme) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            provider.errorMessage!,
            style: TextStyle(color: theme.colorScheme.error, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (provider.results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _searchController.text.isEmpty ? Icons.search : Icons.search_off,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'Type something to start searching.'
                  : 'No books found. Try a different search.',
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: provider.results.length,
      itemBuilder: (context, index) {
        final fetchResult = provider.results[index];
        final book = fetchResult.toBook();

        return BookCard(
          book: book,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookDetailScreen(
                  book: book,
                  isOwner: false,
                ),
              ),
            );
          },
        );
      },
    );
  }
}