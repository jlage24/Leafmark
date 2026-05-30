import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/book_search_modal.dart';
import '../../../../features/search/presentation/providers/search_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/wishlist_item.dart';
import '../providers/wishlist_provider.dart';

class WishlistScreen extends StatelessWidget {
  final String uid;
  final bool readOnly;

  const WishlistScreen({
    super.key,
    required this.uid,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: readOnly
          ? null
          : FloatingActionButton(
        tooltip: 'Add book',
        onPressed: () => _showAddSheet(context),
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _WishlistHeader(readOnly: readOnly),
            Expanded(
              child: StreamBuilder<List<WishlistItem>>(
                stream: context.read<WishlistProvider>().getWishlist(uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _WishlistLoadingState();
                  }

                  if (snapshot.hasError) {
                    return const _WishlistMessageState(
                      icon: Icons.error_outline_rounded,
                      title: 'Could not load wishlist',
                      message: 'Something went wrong. Please try again later.',
                    );
                  }

                  final items = snapshot.data ?? [];

                  if (items.isEmpty) {
                    return _WishlistMessageState(
                      icon: Icons.bookmark_outline_rounded,
                      title: readOnly ? 'Empty wishlist' : 'Your wishlist is empty',
                      message: readOnly
                          ? 'This user has no books on their wishlist yet.'
                          : 'Add books you are looking for and make future swaps easier.',
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 96),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];

                      return _WishlistCard(
                        item: item,
                        readOnly: readOnly,
                        onRemove: () {
                          context
                              .read<WishlistProvider>()
                              .removeItem(uid, item.id);
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

  void _showAddSheet(BuildContext context) {
    final searchProvider = context.read<SearchProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => ChangeNotifierProvider.value(
        value: searchProvider,
        child: BookSearchModal(
          isAuthor: false,
          onSelect: (title, authors, coverUrl) async {
            final providerUid = context.read<AuthProvider>().user?.uid ?? '';
            final wishlistProvider = context.read<WishlistProvider>();
            final messenger = ScaffoldMessenger.of(context);

            final current = await wishlistProvider.getWishlist(providerUid).first;

            final alreadyExists = current.any(
                  (item) => item.title.toLowerCase() == title.toLowerCase(),
            );

            if (alreadyExists) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text('"$title" is already on your wishlist.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }

            await wishlistProvider.addItem(
              providerUid,
              WishlistItem(
                id: '',
                title: title,
                authors: authors.isNotEmpty
                    ? authors.split(',').map((author) => author.trim()).toList()
                    : [],
                addedAt: DateTime.now(),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WishlistHeader extends StatelessWidget {
  final bool readOnly;

  const _WishlistHeader({required this.readOnly});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              Icons.bookmark_rounded,
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
                  readOnly ? 'Wishlist' : 'My Wishlist',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  readOnly
                      ? 'Books this reader is looking for.'
                      : 'Books you would like to find.',
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

class _WishlistCard extends StatelessWidget {
  final WishlistItem item;
  final bool readOnly;
  final VoidCallback onRemove;

  const _WishlistCard({
    required this.item,
    required this.readOnly,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authors =
    item.authors.isNotEmpty ? item.authors.join(', ') : 'Unknown author';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.bookmark_outline_rounded,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    authors,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                    ),
                  ),
                ],
              ),
            ),
            if (!readOnly) ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Remove from wishlist',
                onPressed: onRemove,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WishlistLoadingState extends StatelessWidget {
  const _WishlistLoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: 5,
      itemBuilder: (context, index) => const _LoadingWishlistCard(),
    );
  }
}

class _LoadingWishlistCard extends StatelessWidget {
  const _LoadingWishlistCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.onSurface.withValues(alpha: 0.08);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _LoadingLine(widthFactor: 0.72),
                SizedBox(height: 10),
                _LoadingLine(widthFactor: 0.46),
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

class _WishlistMessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _WishlistMessageState({
    required this.icon,
    required this.title,
    required this.message,
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
          ],
        ),
      ),
    );
  }
}