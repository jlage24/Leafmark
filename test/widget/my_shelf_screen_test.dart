import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:provider/provider.dart';
import 'package:leafmark/features/books/domain/models/book.dart';
import 'package:leafmark/features/books/presentation/providers/book_shelf_provider.dart';
import 'package:leafmark/features/books/presentation/screens/my_shelf_screen.dart';
import 'package:leafmark/features/auth/presentation/providers/auth_provider.dart';
import 'package:leafmark/features/auth/domain/models/app_user.dart';

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
  Future<bool> register(String email, String password, String name, String username) async => true;

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
}

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
  });

  Book makeBook(String id, {String title = 'Test Book'}) => Book(
    id: id,
    isbn: '9780000000001',
    title: title,
    authors: 'Test Author',
    condition: BookCondition.good,
    addedAt: DateTime.parse('2025-01-01T00:00:00.000'),
  );

  Widget buildShelf(BookShelfProvider provider) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => FakeAuthProvider(),
        ),
        ChangeNotifierProvider<BookShelfProvider>.value(value: provider),
      ],
      child: const MaterialApp(home: MyShelfScreen()),
    );
  }

  BookShelfProvider makeProvider() =>
      BookShelfProvider(firestore: fakeFirestore);

  group('MyShelfScreen - empty state', () {
    testWidgets('shows empty state message when shelf is empty', (tester) async {
      final provider = makeProvider();

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(buildShelf(provider));
        await tester.pumpAndSettle();
      });

      expect(find.text('Your shelf is empty. Scan a book to add it!'), findsOneWidget);
    });

    testWidgets('shows AppBar with My Shelf title', (tester) async {
      final provider = makeProvider();

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(buildShelf(provider));
        await tester.pumpAndSettle();
      });

      expect(find.text('My Shelf'), findsOneWidget);
    });
  });

  group('MyShelfScreen - books list', () {
    testWidgets('renders book title when shelf has a book', (tester) async {
      final provider = makeProvider();
      await provider.loadBooks('test-uid', null);
      await provider.addBook(makeBook('1', title: 'Nineteen Eighty-Four'));

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(buildShelf(provider));
        await tester.pumpAndSettle();
      });

      expect(find.text('Nineteen Eighty-Four'), findsOneWidget);
    });

    testWidgets('renders all books when multiple are added', (tester) async {
      final provider = makeProvider();
      await provider.loadBooks('test-uid', null);
      await provider.addBook(makeBook('1', title: 'Book One'));
      await provider.addBook(makeBook('2', title: 'Book Two'));
      await provider.addBook(makeBook('3', title: 'Book Three'));

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(buildShelf(provider));
        await tester.pumpAndSettle();
      });

      expect(find.text('Book One'), findsOneWidget);
      expect(find.text('Book Two'), findsOneWidget);
      expect(find.text('Book Three'), findsOneWidget);
    });

    testWidgets('empty state is not shown when shelf has books', (tester) async {
      final provider = makeProvider();
      await provider.loadBooks('test-uid', null);
      await provider.addBook(makeBook('1', title: 'Some Book'));

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(buildShelf(provider));
        await tester.pumpAndSettle();
      });

      expect(
        find.text('Your shelf is empty. Scan a book to add it!'),
        findsNothing,
      );
    });
  });

  group('MyShelfScreen - delete flow', () {
    testWidgets('long press opens bottom sheet with book title', (tester) async {
      final provider = makeProvider();
      await provider.loadBooks('test-uid', null);
      await provider.addBook(makeBook('1', title: 'Animal Farm'));

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(buildShelf(provider));
        await tester.pumpAndSettle();

        await tester.longPress(find.text('Animal Farm'));
        await tester.pumpAndSettle();
      });

      expect(find.text('Animal Farm'), findsWidgets);
      expect(find.text('Remove from shelf'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('tapping Cancel closes the bottom sheet', (tester) async {
      final provider = makeProvider();
      await provider.loadBooks('test-uid', null);
      await provider.addBook(makeBook('1', title: 'Animal Farm'));

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(buildShelf(provider));
        await tester.pumpAndSettle();

        await tester.longPress(find.text('Animal Farm'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
      });

      expect(find.text('Remove from shelf'), findsNothing);
      expect(find.text('Animal Farm'), findsOneWidget);
    });

    testWidgets('tapping Remove deletes book and shows snack bar', (tester) async {
      final provider = makeProvider();
      await provider.loadBooks('test-uid', null);
      await provider.addBook(makeBook('1', title: 'Animal Farm'));

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(buildShelf(provider));
        await tester.pumpAndSettle();

        await tester.longPress(find.text('Animal Farm'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Remove from shelf'));
        await tester.pumpAndSettle();
      });

      expect(find.text('Remove from shelf'), findsNothing);
      expect(find.text('"Animal Farm" removed from your shelf'), findsOneWidget);
      expect(provider.books, isEmpty);
    });
  });

  group('App bootstrap', () {
    testWidgets('BookShelfProvider is accessible from widget tree', (tester) async {
      final provider = makeProvider();

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(buildShelf(provider));
        await tester.pumpAndSettle();
      });

      final context = tester.element(find.byType(MyShelfScreen));
      expect(() => context.read<BookShelfProvider>(), returnsNormally);
    });
  });
}