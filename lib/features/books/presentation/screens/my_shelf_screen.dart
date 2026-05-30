import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'isbn_scanner_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/book.dart';
import '../providers/book_shelf_provider.dart';
import '../widgets/book_card.dart';
import 'book_detail_screen.dart';

class MyShelfScreen extends StatefulWidget {
  const MyShelfScreen({super.key});

  @override
  State<MyShelfScreen> createState() => _MyShelfScreenState();
}

class _MyShelfScreenState extends State<MyShelfScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().user?.uid;
      final displayName = context.read<AuthProvider>().user?.displayName;

      if (uid == null) return;

      context.read<BookShelfProvider>().loadBooks(uid, displayName);
    });
  }

  void _showDeleteSheet(BuildContext context, Book book) {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) {
        return _DeleteBookSheet(
          book: book,
          onCancel: () => Navigator.pop(sheetCtx),
          onRemove: () {
            Navigator.pop(sheetCtx);

            context.read<BookShelfProvider>().removeBook(book.id);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('"${book.title}" removed from your shelf'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final books = context.watch<BookShelfProvider>().books;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        tooltip: 'Scan book',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const IsbnScannerScreen(),
            ),
          );
        },
        child: const Icon(Icons.qr_code_scanner_rounded),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _ShelfHeader(bookCount: books.length),
            Expanded(
              child: books.isEmpty
                  ? const _EmptyShelfState()
                  : ListView.builder(
                padding: const EdgeInsets.only(bottom: 96),
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
                            isOwner: true,
                          ),
                        ),
                      );
                    },
                    onLongPress: () => _showDeleteSheet(context, book),
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

class _ShelfHeader extends StatelessWidget {
  final int bookCount;

  const _ShelfHeader({required this.bookCount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final countLabel = bookCount == 1 ? '1 book' : '$bookCount books';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.library_books_rounded,
              color: theme.colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Shelf',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  countLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
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

class _EmptyShelfState extends StatelessWidget {
  const _EmptyShelfState();

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
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_stories_rounded,
                size: 42,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Your shelf is empty',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scan or search for a book to start building your exchange shelf.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteBookSheet extends StatelessWidget {
  final Book book;
  final VoidCallback onCancel;
  final VoidCallback onRemove;

  const _DeleteBookSheet({
    required this.book,
    required this.onCancel,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayUrl = book.conditionPhotoUrls.isNotEmpty
        ? book.conditionPhotoUrls.first
        : book.coverUrl;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _SheetBookCover(imageUrl: displayUrl),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book.authors,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.62,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Remove from shelf'),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onCancel,
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetBookCover extends StatelessWidget {
  final String? imageUrl;

  const _SheetBookCover({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 58,
        height: 82,
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        child: imageUrl == null || imageUrl!.isEmpty
            ? Icon(
          Icons.menu_book_rounded,
          color: theme.colorScheme.primary,
        )
            : CachedNetworkImage(
          imageUrl: imageUrl!,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) => Icon(
            Icons.menu_book_rounded,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}