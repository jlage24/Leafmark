import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/books/data/services/google_books_service.dart';
import '../../features/search/presentation/providers/search_provider.dart';

class BookSearchModal extends StatefulWidget {
  final bool isAuthor;
  final void Function(String title, String authors, String? coverUrl) onSelect;

  const BookSearchModal({
    super.key,
    required this.isAuthor,
    required this.onSelect,
  });

  @override
  State<BookSearchModal> createState() => _BookSearchModalState();
}

class _BookSearchModalState extends State<BookSearchModal> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final provider = context.read<SearchProvider>();
      provider.clearSearch();
      provider.setSearchType(
        widget.isAuthor ? SearchType.author : SearchType.title,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSearch(SearchProvider provider) {
    final query = _controller.text.trim();

    if (query.isEmpty) return;

    provider.setSearchType(
      widget.isAuthor ? SearchType.author : SearchType.title,
    );
    provider.performSearch(query);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: bottomInset > 0 ? 0.9 : 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: widget.isAuthor
                        ? 'Search by author name...'
                        : 'Search by book title...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded),
                      onPressed: () => _handleSearch(provider),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onSubmitted: (_) => _handleSearch(provider),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _SearchResults(
                    provider: provider,
                    controller: scrollController,
                    isAuthor: widget.isAuthor,
                    queryIsEmpty: _controller.text.trim().isEmpty,
                    onSelect: widget.onSelect,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  final SearchProvider provider;
  final ScrollController controller;
  final bool isAuthor;
  final bool queryIsEmpty;
  final void Function(String title, String authors, String? coverUrl) onSelect;

  const _SearchResults({
    required this.provider,
    required this.controller,
    required this.isAuthor,
    required this.queryIsEmpty,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Text(
          provider.errorMessage!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (provider.bookResults.isEmpty) {
      return ListView(
        controller: controller,
        children: [
          const SizedBox(height: 80),
          Center(
            child: Text(
              queryIsEmpty ? 'Type to search' : 'No results found',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: controller,
      itemCount: provider.bookResults.length,
      itemBuilder: (context, index) {
        final book = provider.bookResults[index];

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 2,
            vertical: 4,
          ),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: book.coverUrl != null
                ? Image.network(
                    book.coverUrl!,
                    width: 42,
                    height: 62,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.book, size: 42),
                  )
                : const Icon(Icons.book, size: 42),
          ),
          title: Text(
            isAuthor ? book.authors : book.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            isAuthor ? 'Known for: ${book.title}' : book.authors,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () {
            onSelect(book.title, book.authors, book.coverUrl);
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}
