import 'package:flutter/material.dart';
import 'features/books/presentation/screens/my_shelf_screen.dart';
import 'features/books/presentation/screens/browse_screen.dart';
import 'features/books/presentation/screens/isbn_scanner_screen.dart';
import 'features/auth/presentation/screens/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    MyShelfScreen(),
    BrowseScreen(),
    ProfileScreen(),
  ];

  void _openScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const IsbnScannerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
        onPressed: _openScanner,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        tooltip: 'Scan a book',
        child: const Icon(Icons.document_scanner_outlined),
      )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) =>
            setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'My Shelf',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Browse',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}