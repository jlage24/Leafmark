import 'package:flutter/material.dart';
import '../models/book.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const BookCard({
    super.key,
    required this.book,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        onTap: onTap,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.network(
            book.coverUrl,
            width: 50,
            height: 75,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.book, size: 50),
          ),
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
              Text(book.author, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(
                'Condition: ${book.condition}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        isThreeLine: true,
      ),
    );
  }
}