import 'package:flutter/material.dart';

class SearchPlaceholderScreen extends StatelessWidget {
  const SearchPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 64,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text('Search is coming soon',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('You\'ll be able to search by title, author or ISBN.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}