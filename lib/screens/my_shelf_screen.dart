import 'package:flutter/material.dart';
import '../models/book.dart';
import '../widgets/book_card.dart';
import 'book_detail_screen.dart';

class MyShelfScreen extends StatefulWidget {
  const MyShelfScreen({super.key});

  @override
  State<MyShelfScreen> createState() => _MyShelfScreenState();
}

class _MyShelfScreenState extends State<MyShelfScreen> {
  List<Book> myBooks = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Shelf'),
      ),
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookDetailScreen(book: book, isOwner: true),
                ),
              );
            },
          );
        },
      ),
    );
  }
}