import 'package:flutter/material.dart';
import '../../domain/models/book.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isCatalogView;

  const BookCard({
    super.key,
    required this.book,
    required this.onTap,
    this.onLongPress,
    this.isCatalogView = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayUrl = book.conditionPhotoUrls.isNotEmpty
        ? book.conditionPhotoUrls.first
        : book.coverUrl;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        onTap: onTap,
        onLongPress: onLongPress,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: displayUrl != null
              ? CachedNetworkImage(
            imageUrl: displayUrl,
            width: 50,
            height: 75,
            fit: BoxFit.cover,
            placeholder: (context, url) => const SizedBox(
              width: 50,
              height: 75,
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (context, url, error) =>
            const Icon(Icons.book, size: 50),
          )
              : const Icon(Icons.book, size: 50),
        ),
        title: Text(
          book.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(book.authors, maxLines: 1, overflow: TextOverflow.ellipsis),
              if (!isCatalogView) ...[
                const SizedBox(height: 4),
                Text(
                  'Condition: ${book.condition.label}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        isThreeLine: !isCatalogView,
      ),
    );
  }
}