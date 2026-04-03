import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'features/books/presentation/providers/book_shelf_provider.dart';
import 'main_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LeafMarkApp());
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
        theme: AppTheme.light,
        home: const MainScreen(),
      ),
    );
  }
}