import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/book_shelf_provider.dart';
import '../widgets/book_card.dart';
import '../../domain/models/book.dart';
import 'book_detail_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

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
      if (uid == null) return;
      context.read<BookShelfProvider>().loadBooks(uid);
    });
  }

  void _showDeleteSheet(BuildContext context, Book book) {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: book.coverUrl != null
                          ? Image.network(
                        book.coverUrl!,
                        width: 44,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, _) =>
                        const Icon(Icons.book, size: 44),
                      )
                          : const Icon(Icons.book, size: 44),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            book.authors,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Remove from shelf',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  context.read<BookShelfProvider>().removeBook(book.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"${book.title}" removed from your shelf'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(sheetCtx),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final books = context.watch<BookShelfProvider>().books;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Shelf'),
      ),
      body: books.isEmpty
          ? const Center(
        child: Text(
          'Your shelf is empty. Scan a book to add it!',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.builder(
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
                      BookDetailScreen(book: book, isOwner: true),
                ),
              );
            },
            onLongPress: () => _showDeleteSheet(context, book),
          );
        },
      ),
    );
  }
}