import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    // Load books after the first frame so context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookShelfProvider>().loadBooks();
    });
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
          );
        },
      ),
    );
  }
}