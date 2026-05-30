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
      final p = context.read<SearchProvider>();
      p.clearSearch();
      p.setSearchType(widget.isAuthor ? SearchType.author : SearchType.title);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSearch(SearchProvider provider) {
    final query = _controller.text.trim();
    if (query.isNotEmpty) {
      provider.setSearchType(
          widget.isAuthor ? SearchType.author : SearchType.title);
      provider.performSearch(query);
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();

    return Padding(
      padding:
      EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: widget.isAuthor
                    ? 'Search by author name...'
                    : 'Search by book title...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => _handleSearch(provider),
                ),
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onSubmitted: (_) => _handleSearch(provider),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.errorMessage != null
                  ? Center(
                  child: Text(provider.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center))
                  : provider.bookResults.isEmpty
                  ? Center(
                child: Text(
                  _controller.text.isEmpty
                      ? 'Type to search'
                      : 'No results found',
                  style: const TextStyle(color: Colors.grey),
                ),
              )
                  : ListView.builder(
                itemCount: provider.bookResults.length,
                itemBuilder: (ctx, i) {
                  final b = provider.bookResults[i];
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: b.coverUrl != null
                          ? Image.network(
                        b.coverUrl!,
                        width: 40,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) =>
                        const Icon(Icons.book,
                            size: 40),
                      )
                          : const Icon(Icons.book, size: 40),
                    ),
                    title: Text(
                      widget.isAuthor ? b.authors : b.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(widget.isAuthor
                        ? 'Known for: ${b.title}'
                        : b.authors),
                    onTap: () {
                      widget.onSelect(
                          b.title, b.authors, b.coverUrl);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}