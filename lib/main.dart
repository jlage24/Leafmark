import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/book_shelf_provider.dart';
import 'screens/my_shelf_screen.dart';
import 'theme/app_theme.dart';

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
        theme: LeafMarkTheme.light,
        home: const MyShelfScreen(),
      ),
    );
  }
}