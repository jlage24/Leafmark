import 'package:flutter/material.dart';
import 'features/books/presentation/screens/browse_screen.dart';
import 'features/books/presentation/screens/isbn_scanner_screen.dart';
import 'features/auth/presentation/screens/profile_screen.dart';
import 'features/chat/presentation/screens/chat_list_screen.dart';
import 'features/search/presentation/screens/search_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    BrowseScreen(),
    SearchScreen(),
    SizedBox.shrink(),
    ChatListScreen(),
    ProfileScreen(),
  ];

  void _onTabTapped(int index) {
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const IsbnScannerScreen()),
      );
      return;
    }

    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabTapped,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Discover',
          ),
          const NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.qr_code_scanner_rounded,
                color: scheme.onPrimary,
                size: 24,
              ),
            ),
            selectedIcon: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.qr_code_scanner_rounded,
                color: scheme.onPrimary,
                size: 24,
              ),
            ),
            label: 'Scan',
          ),
          const NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum_rounded),
            label: 'Chats',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
