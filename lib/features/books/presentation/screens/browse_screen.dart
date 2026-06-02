import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

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
  late final Stream<List<Book>> _availableBooksStream;

  bool get _hasActiveFilters =>
      _selectedCategory != null || _locationQuery.isNotEmpty;

  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthProvider>().user?.uid ?? '';
    final browseService = BrowseService();
    _availableBooksStream = browseService
        .browseAvailableBooks(uid)
        .shareValue();
  }

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

  void _openBook(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookDetailScreen(book: book, isOwner: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _DiscoverHeader(
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
                stream: _availableBooksStream,
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

                  final allBooks = snapshot.data ?? [];
                  var books = allBooks;

                  if (_hasActiveFilters) {
                    books = books.where((book) {
                      var matchesCategory = true;
                      var matchesLocation = true;

                      if (_selectedCategory != null) {
                        matchesCategory =
                            book.category?.trim().toLowerCase() ==
                            _selectedCategory!.trim().toLowerCase();
                      }

                      if (_locationQuery.isNotEmpty) {
                        matchesLocation = (book.location ?? '')
                            .toLowerCase()
                            .contains(_locationQuery);
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

                  return _DiscoverFeed(
                    books: books,
                    totalBooks: allBooks.length,
                    hasActiveFilters: _hasActiveFilters,
                    onBookTap: _openBook,
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

class _DiscoverHeader extends StatelessWidget {
  final bool hasActiveFilters;
  final VoidCallback onClearFilters;

  const _DiscoverHeader({
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
                  'Discover',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Books waiting for a new home.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                  ),
                ),
              ],
            ),
          ),
          if (hasActiveFilters)
            TextButton(onPressed: onClearFilters, child: const Text('Clear')),
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

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'Fiction':
        return Icons.auto_stories_rounded;
      case 'Non-Fiction':
        return Icons.lightbulb_outline_rounded;
      case 'Academic':
        return Icons.school_outlined;
      case 'Comics & Manga':
        return Icons.bubble_chart_outlined;
      case 'Children & Young Adult':
        return Icons.child_care_rounded;
      default:
        return Icons.category_outlined;
    }
  }

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
            avatar: Icon(
              isSelected ? Icons.check_rounded : _iconForCategory(category),
              size: 18,
            ),
            onSelected: (_) => onCategorySelected(category),
          );
        },
      ),
    );
  }
}

class _DiscoverFeed extends StatelessWidget {
  final List<Book> books;
  final int totalBooks;
  final bool hasActiveFilters;
  final ValueChanged<Book> onBookTap;

  const _DiscoverFeed({
    required this.books,
    required this.totalBooks,
    required this.hasActiveFilters,
    required this.onBookTap,
  });

  @override
  Widget build(BuildContext context) {
    final featuredBook = books.first;
    final remainingBooks = books.skip(1).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        _DiscoverHeroCard(
          totalBooks: totalBooks,
          visibleBooks: books.length,
          hasActiveFilters: hasActiveFilters,
        ),
        _FeaturedBookCard(
          book: featuredBook,
          onTap: () => onBookTap(featuredBook),
        ),
        if (remainingBooks.isNotEmpty) ...[
          const _SectionTitle(title: 'All books'),
          ...remainingBooks.map(
            (book) => BookCard(book: book, onTap: () => onBookTap(book)),
          ),
        ],
      ],
    );
  }
}

class _DiscoverHeroCard extends StatelessWidget {
  final int totalBooks;
  final int visibleBooks;
  final bool hasActiveFilters;

  const _DiscoverHeroCard({
    required this.totalBooks,
    required this.visibleBooks,
    required this.hasActiveFilters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.78),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.menu_book_rounded,
              color: theme.colorScheme.onPrimary,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasActiveFilters
                      ? '$visibleBooks matching books'
                      : '$totalBooks books available',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasActiveFilters
                      ? 'Fresh picks based on your filters.'
                      : 'Explore books shared by readers around you.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedBookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const _FeaturedBookCard({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayUrl = book.conditionPhotoUrls.isNotEmpty
        ? book.conditionPhotoUrls.first
        : book.coverUrl;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 86,
                  height: 126,
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  child: displayUrl != null && displayUrl.isNotEmpty
                      ? Image.network(
                          displayUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.book_rounded, size: 36),
                        )
                      : const Icon(Icons.book_rounded, size: 36),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Featured today',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      book.authors,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.58,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (book.category != null && book.category!.isNotEmpty)
                          _MiniBadge(
                            icon: Icons.auto_stories_rounded,
                            text: book.category!,
                          ),
                        if (book.location != null && book.location!.isNotEmpty)
                          _MiniBadge(
                            icon: Icons.place_outlined,
                            text: book.location!,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'View book →',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MiniBadge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 6),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
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
              children: const [
                _LoadingLine(widthFactor: 0.82),
                SizedBox(height: 10),
                _LoadingLine(widthFactor: 0.56),
                SizedBox(height: 18),
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
      child: SingleChildScrollView(
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
              child: Icon(icon, size: 38, color: theme.colorScheme.primary),
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
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
