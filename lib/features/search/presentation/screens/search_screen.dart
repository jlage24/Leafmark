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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to our SearchProvider
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
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    searchProvider.clearSearch();
                    setState(() {}); // Refresh to hide clear button
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (value) => searchProvider.performSearch(value),
              onChanged: (_) => setState(() {}), // Refresh for clear button
            ),
          ),
          const SizedBox(width: 8),

          // Search Submit Button
          ElevatedButton(
            onPressed: () {
              FocusScope.of(context).unfocus(); // Dismiss keyboard
              searchProvider.performSearch(_searchController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary, // Using strict theme rules
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Icon(Icons.arrow_forward),
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
    // Automatically search again if text exists and filter changes
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

  // Helper method to keep the build method clean
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
              Icons.search_off,
              size: 64,
              // Strictly following the new alpha rule: withValues(alpha: x)
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No books found. Try a different search.',
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Results List using your BookCard from Sprint 0
    return ListView.builder(
      itemCount: provider.results.length,
      itemBuilder: (context, index) {
        final fetchResult = provider.results[index];

        // Convert BookFetchResult to your canonical Book model.
        // Assuming your BookFetchResult has a toBook() method!
        final book = fetchResult.toBook();

        return BookCard(
          book: book,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookDetailScreen(
                  book: book,
                  isOwner: false, // You are searching global API, so you don't own it
                ),
              ),
            );
          },
        );
      },
    );
  }
}