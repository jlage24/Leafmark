import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'features/books/presentation/providers/book_shelf_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => BookShelfProvider(),
      child: const LeafMarkApp(),
    ),
  );
}
class LeafMarkApp extends StatelessWidget {
  const LeafMarkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BookShelfProvider()),
      ],
      child: MaterialApp(
        title: 'LeafMark',
        debugShowCheckedModeBanner: false,
        theme: LeafMarkTheme.light,
        home: const MyShelfScreen(),
      ),
    );
  }
}