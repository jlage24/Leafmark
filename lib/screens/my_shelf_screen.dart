import 'package:flutter/material.dart';
import '../models/book.dart';
import '../widgets/book_card.dart';

class MyShelfScreen extends StatefulWidget {
  const MyShelfScreen({Key? key}) : super(key: key);

  @override
  State<MyShelfScreen> createState() => _MyShelfScreenState();
}

class _MyShelfScreenState extends State<MyShelfScreen> {
  // This is the local state for your shelf.
  List<Book> myBooks = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Shelf'),
      ),
      // If the list is empty, show a friendly message. Otherwise, show the list.
      body: myBooks.isEmpty
          ? const Center(
        child: Text(
          'Your shelf is empty. Scan a book to add it!',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: myBooks.length,
        itemBuilder: (context, index) {
          final book = myBooks[index];
          return BookCard(
            book: book,
            onTap: () {
              debugPrint('Tapped on my own book: ${book.title}');
            },
          );
        },
      ),
    );
  }
}