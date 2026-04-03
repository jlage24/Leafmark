import 'package:flutter/material.dart';
import '../../../../data/dummy_data.dart';
import '../widgets/book_card.dart';
import 'book_detail_screen.dart';

class BrowseScreen extends StatelessWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Books'),
      ),
      body: ListView.builder(
        itemCount: browseDummyBooks.length,
        itemBuilder: (context, index) {
          final book = browseDummyBooks[index];
          return BookCard(
            book: book,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      BookDetailScreen(book: book, isOwner: false),
                ),
              );
            },
          );
        },
      ),
    );
  }
}