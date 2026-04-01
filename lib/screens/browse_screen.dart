import 'package:flutter/material.dart';
import '../data/dummy_data.dart';
import '../widgets/book_card.dart';
import 'book_detail_screen.dart';

class BrowseScreen extends StatelessWidget {
  const BrowseScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Books'),
      ),
      // ListView.builder loops through your dummy data to create cards
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
                  builder: (context) => BookDetailScreen(book: book),
                ),
              );
              debugPrint('Tapped on ${book.title}');
            },
          );
        },
      ),
    );
  }
}