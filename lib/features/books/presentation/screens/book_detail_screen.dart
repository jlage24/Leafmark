import 'package:flutter/material.dart';
import '../../domain/models/book.dart';

class BookDetailScreen extends StatelessWidget {
  final Book book;
  final bool isOwner;

  const BookDetailScreen({
    super.key,
    required this.book,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(book.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (book.coverUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  book.coverUrl!,
                  height: 250,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.book, size: 100, color: Colors.grey),
                ),
              ),
            const SizedBox(height: 24),
            Text(
              book.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'by ${book.authors}',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('Condition: ${book.condition.label}'),
                  if (book.ownerName != null) Text('Owner: ${book.ownerName}'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            !isOwner
                ? SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Swap request sent to ${book.ownerName ?? 'owner'}!',
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  Theme.of(context).colorScheme.primary,
                  foregroundColor:
                  Theme.of(context).colorScheme.onPrimary,
                ),
                child: const Text(
                  'Request Swap',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            )
                : const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'This is your book on your shelf.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}