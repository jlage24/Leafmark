import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leafmark/features/auth/domain/models/app_user.dart';
import 'package:leafmark/features/search/data/services/user_search_service.dart';
import 'package:provider/provider.dart';
import 'package:leafmark/features/search/presentation/providers/search_provider.dart';
import 'package:leafmark/features/search/presentation/screens/search_screen.dart';

class FakeUserSearchService implements UserSearchRepository {
  @override
  Future<List<AppUser>> searchUsers(
      String query, {
        String? excludeUid,
        int limit = 20,
      }) async {
    return [];
  }
}

void main() {
  group('SearchScreen', () {
    Widget buildSubject() {
      return ChangeNotifierProvider(
        create: (_) => SearchProvider(
          userSearchService: FakeUserSearchService(),
        ),
        child: const MaterialApp(home: SearchScreen()),
      );
    }

    testWidgets('Should render the search bar.', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Discover'), findsOneWidget);
      expect(find.text('Find books to swap or readers to follow.'), findsOneWidget);
    });

    testWidgets('Should display initial message when there is no search.', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Start exploring'), findsOneWidget);
      expect(
        find.text('Search by title, author or ISBN to find your next swap.'),
        findsOneWidget,
      );
    });

    testWidgets('Typing in the search bar updates the text.', (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.enterText(find.byType(TextField), 'Dune');
      await tester.pump();

      expect(find.text('Dune'), findsOneWidget);
    });
  });
}