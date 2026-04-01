import 'package:flutter/material.dart';
import '../data/dummy_data.dart';
import '../widgets/book_card.dart';

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
              // TODO: Navigate to the Book Detail Screen (we will build this next!)
              debugPrint('Tapped on ${book.title}');
            },
          );
        },
      ),
    );
  }
}