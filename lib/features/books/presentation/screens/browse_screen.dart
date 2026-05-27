import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/services/browse_service.dart';
import '../../domain/models/book.dart';
import '../widgets/book_card.dart';
import 'book_detail_screen.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  String? _selectedCategory;
  final TextEditingController _locationController = TextEditingController();
  String _locationQuery = '';

  final List<String> _categories = [
    'Fiction', 'Non-Fiction', 'Sci-Fi', 'Fantasy',
    'Romance', 'Mystery', 'Academic', 'Thriller',
  ];

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _locationController.clear();
      _locationQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().user?.uid ?? '';
    final browseService = BrowseService();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Books'),
        actions: [
          if (_selectedCategory != null || _locationQuery.isNotEmpty)
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Clear'),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: 'Filter by city or campus...',
                prefixIcon: const Icon(Icons.location_on_outlined),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _locationQuery = value.trim().toLowerCase();
                });
              },
            ),
          ),

          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? category : null;
                      });
                    },
                  ),
                );
              },
            ),
          ),

          const Divider(),

          Expanded(
            child: StreamBuilder<List<Book>>(
              stream: browseService.browseBooks(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading books.'));
                }

                var books = snapshot.data ?? [];

                if (_selectedCategory != null || _locationQuery.isNotEmpty) {
                  books = books.where((book) {
                    if (book.isLocked) return false;

                    if (_selectedCategory != null && book.category != _selectedCategory) {
                      return false;
                    }

                    if (_locationQuery.isNotEmpty) {
                      final bookLoc = (book.location ?? '').toLowerCase();
                      if (!bookLoc.contains(_locationQuery)) return false;
                    }

                    return true;
                  }).toList();
                }

                if (books.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.4)),
                        const SizedBox(height: 16),
                        Text(
                          'No books match your filters.',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try removing some filters to see more results.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final book = books[index];
                    return BookCard(
                      book: book,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                BookDetailScreen(book: book, isOwner: false),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}