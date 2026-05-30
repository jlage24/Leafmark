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

  bool get _hasActiveFilters =>
      _selectedCategory != null || _locationQuery.isNotEmpty;

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

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _BrowseHeader(
              hasActiveFilters: _hasActiveFilters,
              onClearFilters: _clearFilters,
            ),
            _LocationSearchField(
              controller: _locationController,
              onChanged: (value) {
                setState(() {
                  _locationQuery = value.trim().toLowerCase();
                });
              },
            ),
            _CategoryFilterList(
              selectedCategory: _selectedCategory,
              onCategorySelected: (category) {
                setState(() {
                  _selectedCategory = _selectedCategory == category
                      ? null
                      : category;
                });
              },
            ),
            const SizedBox(height: 4),
            Expanded(
              child: StreamBuilder<List<Book>>(
                stream: browseService.browseAvailableBooks(uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _BrowseLoadingState();
                  }

                  if (snapshot.hasError) {
                    return const _BrowseMessageState(
                      icon: Icons.error_outline_rounded,
                      title: 'Could not load books',
                      message: 'Something went wrong. Please try again later.',
                    );
                  }

                  var books = snapshot.data ?? [];

                  if (_hasActiveFilters) {
                    books = books.where((book) {
                      var matchesCategory = true;
                      var matchesLocation = true;

                      if (_selectedCategory != null) {
                        final bookCategory =
                        book.category?.trim().toLowerCase();
                        final selectedCategory =
                        _selectedCategory?.trim().toLowerCase();

                        matchesCategory = bookCategory == selectedCategory;
                      }

                      if (_locationQuery.isNotEmpty) {
                        final bookLocation =
                        (book.location ?? '').toLowerCase();

                        matchesLocation = bookLocation.contains(_locationQuery);
                      }

                      return matchesCategory && matchesLocation;
                    }).toList();
                  }

                  if (books.isEmpty) {
                    return _BrowseMessageState(
                      icon: Icons.search_off_rounded,
                      title: _hasActiveFilters
                          ? 'No books match your filters'
                          : 'No books available yet',
                      message: _hasActiveFilters
                          ? 'Try removing some filters to discover more books.'
                          : 'When other readers add books, they will appear here.',
                      action: _hasActiveFilters
                          ? TextButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.clear_rounded),
                        label: const Text('Clear filters'),
                      )
                          : null,
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: books.length,
                    itemBuilder: (context, index) {
                      final book = books[index];

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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrowseHeader extends StatelessWidget {
  final bool hasActiveFilters;
  final VoidCallback onClearFilters;

  const _BrowseHeader({
    required this.hasActiveFilters,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Browse',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Find your next book swap.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                  ),
                ),
              ],
            ),
          ),
          if (hasActiveFilters)
            TextButton(
              onPressed: onClearFilters,
              child: const Text('Clear'),
            ),
        ],
      ),
    );
  }
}

class _LocationSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _LocationSearchField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Filter by city or campus',
          prefixIcon: const Icon(Icons.place_outlined),
          filled: true,
          fillColor: theme.colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.18),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.18),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryFilterList extends StatelessWidget {
  final String? selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const _CategoryFilterList({
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: bookCategories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = bookCategories[index];
          final isSelected = selectedCategory == category;

          return FilterChip(
            label: Text(category),
            selected: isSelected,
            showCheckmark: false,
            avatar: isSelected ? const Icon(Icons.check_rounded) : null,
            onSelected: (_) => onCategorySelected(category),
          );
        },
      ),
    );
  }
}

class _BrowseLoadingState extends StatelessWidget {
  const _BrowseLoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return const _LoadingBookCard();
      },
    );
  }
}

class _LoadingBookCard extends StatelessWidget {
  const _LoadingBookCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.onSurface.withValues(alpha: 0.08);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 104,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LoadingLine(widthFactor: 0.82),
                const SizedBox(height: 10),
                _LoadingLine(widthFactor: 0.56),
                const SizedBox(height: 18),
                _LoadingLine(widthFactor: 0.34),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingLine extends StatelessWidget {
  final double widthFactor;

  const _LoadingLine({required this.widthFactor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: 12,
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

class _BrowseMessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const _BrowseMessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 38,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}