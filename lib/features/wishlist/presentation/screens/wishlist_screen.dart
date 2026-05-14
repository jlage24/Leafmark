import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/wishlist_item.dart';
import '../providers/wishlist_provider.dart';
import '../../../../core/widgets/book_search_modal.dart';
import '../../../../features/search/presentation/providers/search_provider.dart';

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
      appBar: AppBar(
        title: Text(readOnly ? 'Wishlist' : 'My Wishlist'),
      ),
      floatingActionButton: readOnly
          ? null
          : FloatingActionButton(
        onPressed: () => _showAddSheet(context),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<WishlistItem>>(
        stream: context.read<WishlistProvider>().getWishlist(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bookmark_outline,
                        size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      readOnly
                          ? 'This user has no books on their wishlist yet.'
                          : 'Your wishlist is empty.\nAdd books you\'re looking for!',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.bookmark_outline, size: 18),
                  ),
                  title: Text(
                    item.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: item.authors.isNotEmpty
                      ? Text(
                    item.authors.join(', '),
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                      : null,
                  trailing: readOnly
                      ? null
                      : IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 20, color: Colors.redAccent),
                    onPressed: () => context
                        .read<WishlistProvider>()
                        .removeItem(uid, item.id),
                  ),
                ),
              );
            },
          );
        },
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

            // Verify duplicate
            final current = await wishlistProvider.getWishlist(providerUid).first;

            final alreadyExists = current.any(
                  (item) => item.title.toLowerCase() == title.toLowerCase(),
            );

            if (alreadyExists) {
              messenger.showSnackBar(
                SnackBar(content: Text('"$title" is already on your wishlist.')),
              );
              return;
            }

            await wishlistProvider.addItem(
              providerUid,
              WishlistItem(
                id: '',
                title: title,
                authors: authors.isNotEmpty
                    ? authors.split(',').map((e) => e.trim()).toList()
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