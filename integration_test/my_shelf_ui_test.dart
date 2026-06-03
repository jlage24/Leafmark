import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:leafmark/features/auth/domain/models/app_user.dart';
import 'package:leafmark/features/auth/presentation/providers/auth_provider.dart';
import 'package:leafmark/features/books/domain/models/book.dart';
import 'package:leafmark/features/books/presentation/providers/book_shelf_provider.dart';
import 'package:leafmark/features/books/presentation/screens/my_shelf_screen.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:provider/provider.dart';

class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  AppUser? get user => const AppUser(
    uid: 'test-uid',
    email: 'test@test.com',
    displayName: 'Test User',
    username: 'testuser',
  );

  @override
  AuthStatus get status => AuthStatus.authenticated;

  @override
  String? get errorMessage => null;

  @override
  Future<bool> login(String email, String password) async => true;

  @override
  Future<bool> register(
    String email,
    String password,
    String name,
    String username,
  ) async => true;

  @override
  Future<void> logout() async {}

  @override
  Future<bool> updateProfile({
    String? bio,
    String? profilePictureUrl,
    String? bannerPictureUrl,
    List<String>? favoriteAuthors,
    String? favoriteBookTitle,
    String? favoriteBookAuthor,
    String? favoriteBookCoverUrl,
  }) async => true;

  @override
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async => true;

  @override
  Future<bool> deleteAccount({required String password}) async => true;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
  });

  Book makeBook(String id, {required String title}) => Book(
    id: id,
    isbn: '9780000000001',
    title: title,
    authors: 'Test Author',
    condition: BookCondition.good,
    addedAt: DateTime(2026, 1, 1),
    conditionPhotoUrls: const [
      'https://res.cloudinary.com/leafmark/condition-photo.jpg',
    ],
    category: 'Sci-Fi',
    location: 'Porto',
  );

  BookShelfProvider makeProvider() =>
      BookShelfProvider(firestore: fakeFirestore);

  Widget buildShelf(BookShelfProvider provider) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => FakeAuthProvider()),
        ChangeNotifierProvider<BookShelfProvider>.value(value: provider),
      ],
      child: const MaterialApp(home: MyShelfScreen()),
    );
  }

  Future<void> seedShelf(Book book) async {
    final provider = makeProvider();
    await provider.loadBooks('test-uid', 'Test User');
    await provider.addBook(book);
  }

  group('MyShelfScreen UI Integration Tests', () {
    testWidgets('persisted book is rendered after screen loads shelf', (
      tester,
    ) async {
      await seedShelf(makeBook('book1', title: 'Dune'));

      final provider = makeProvider();

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(buildShelf(provider));
        await tester.pumpAndSettle();
      });

      expect(find.text('My Shelf'), findsOneWidget);
      expect(find.text('Dune'), findsOneWidget);
      expect(find.text('Test Author'), findsOneWidget);
      expect(provider.books.length, 1);
      expect(provider.books.first.conditionPhotoUrls, [
        'https://res.cloudinary.com/leafmark/condition-photo.jpg',
      ]);
    });

    testWidgets('removing a book through the screen persists after reload', (
      tester,
    ) async {
      await seedShelf(makeBook('book1', title: 'Dune'));

      final provider = makeProvider();

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(buildShelf(provider));
        await tester.pumpAndSettle();

        await tester.longPress(find.text('Dune'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Remove from shelf'));
        await tester.pumpAndSettle();
      });

      expect(find.text('"Dune" removed from your shelf'), findsOneWidget);
      expect(
        find.text('Your shelf is empty'),
        findsOneWidget,
      );
      expect(
        find.text('Scan or search for a book to start building your exchange shelf.'),
        findsOneWidget,
      );

      final reloadedProvider = makeProvider();
      await reloadedProvider.loadBooks('test-uid', 'Test User');

      expect(reloadedProvider.books, isEmpty);
    });

    testWidgets('screen only displays the authenticated user shelf', (
      tester,
    ) async {
      final currentUserProvider = makeProvider();
      await currentUserProvider.loadBooks('test-uid', 'Test User');
      await currentUserProvider.addBook(
        makeBook('book1', title: 'Visible Book'),
      );

      final otherUserProvider = makeProvider();
      await otherUserProvider.loadBooks('other-uid', 'Other User');
      await otherUserProvider.addBook(makeBook('book2', title: 'Hidden Book'));

      final provider = makeProvider();

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(buildShelf(provider));
        await tester.pumpAndSettle();
      });

      expect(find.text('Visible Book'), findsOneWidget);
      expect(find.text('Hidden Book'), findsNothing);
    });
  });
}
