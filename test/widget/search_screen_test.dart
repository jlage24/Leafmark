import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:leafmark/features/search/presentation/providers/search_provider.dart';
import 'package:leafmark/features/search/presentation/screens/search_screen.dart';

void main() {
  group('SearchScreen', () {
    Widget buildSubject() {
      return ChangeNotifierProvider(
        create: (_) => SearchProvider(),
        child: const MaterialApp(home: SearchScreen()),
      );
    }

    testWidgets('Should render the search bar.', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search for books...'), findsOneWidget);
    });

    testWidgets('Should display initial message when there is no search.', (tester) async {
      await tester.pumpWidget(buildSubject());

      // Texto real que está na UI
      expect(find.text('Type something to start searching.'), findsOneWidget);
    });

    testWidgets('Typing in the search bar updates the text.', (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.enterText(find.byType(TextField), 'Dune');
      await tester.pump();

      expect(find.text('Dune'), findsOneWidget);
    });
  });
}