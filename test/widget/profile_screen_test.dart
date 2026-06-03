import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:leafmark/features/auth/presentation/providers/auth_provider.dart';
import 'package:leafmark/features/auth/domain/models/app_user.dart';
import 'package:leafmark/features/auth/presentation/screens/profile_screen.dart';
import 'package:leafmark/features/books/presentation/providers/book_shelf_provider.dart';
import 'package:leafmark/features/books/presentation/providers/follow_provider.dart';
import 'package:leafmark/features/notifications/presentation/providers/notification_provider.dart';
import 'package:leafmark/features/notifications/domain/models/app_notification.dart';
import 'package:leafmark/features/books/domain/models/book.dart';
import 'package:leafmark/core/theme_provider.dart';
import 'package:leafmark/features/swaps/presentation/providers/swap_provider.dart';
import 'package:leafmark/features/swaps/domain/models/swap_request.dart';
import 'package:leafmark/features/ratings/presentation/providers/rating_provider.dart';
import 'package:leafmark/features/ratings/domain/models/rating.dart';

class MockAuthProvider extends ChangeNotifier implements AuthProvider {
  final AppUser? mockUser;
  bool changePasswordCalled = false;
  String? lastCurrentPassword;
  String? lastNewPassword;
  bool deleteAccountCalled = false;
  String? lastDeletePassword;
  bool changePasswordSuccess = true;
  bool deleteAccountSuccess = true;
  String? mockErrorMessage;

  MockAuthProvider({this.mockUser, this.mockErrorMessage});

  @override
  AppUser? get user => mockUser ?? const AppUser(
    uid: 'mock-uid',
    email: 'mock@test.com',
    displayName: 'Mock User',
    username: 'mockuser',
  );

  @override
  AuthStatus get status => AuthStatus.authenticated;

  @override
  String? get errorMessage => mockErrorMessage;

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

  @override
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    changePasswordCalled = true;
    lastCurrentPassword = currentPassword;
    lastNewPassword = newPassword;
    return changePasswordSuccess;
  }

  @override
  Future<bool> deleteAccount({required String password}) async {
    deleteAccountCalled = true;
    lastDeletePassword = password;
    return deleteAccountSuccess;
  }
}

class FakeBookShelfProvider extends ChangeNotifier implements BookShelfProvider {
  @override
  List<Book> get books => [];
  @override
  List<Book> get availableBooks => [];
  @override
  Future<void> loadBooks(String uid, String? ownerName) async {}
  @override
  Future<void> addBook(Book book) async {}
  @override
  Future<void> updateBook(Book updatedBook) async {}
  @override
  Future<void> removeBook(String id) async {}
  @override
  Future<void> clearBooks() async {}
  @override
  Future<void> lockBook({required String bookOwnerId, required String bookId, required String swapId}) async {}
  @override
  Future<void> unlockBook({required String bookOwnerId, required String bookId}) async {}
}

class FakeNotificationProvider extends ChangeNotifier implements NotificationProvider {
  @override
  Stream<int> unreadCount() => Stream.value(0);
  @override
  Stream<List<AppNotification>> notifications() => Stream.value([]);
  @override
  Future<void> markAsRead(String notificationId) async {}
  @override
  Future<void> markAllAsRead() async {}
  @override
  Future<void> deleteNotification(String notificationId) async {}
  @override
  Future<void> clearAll() async {}
}

class FakeFollowProvider extends ChangeNotifier implements FollowProvider {
  @override
  Stream<int> getFollowersCount(String uid) => Stream.value(5);
  @override
  Stream<int> getFollowingCount(String uid) => Stream.value(10);
  @override
  Future<void> followUser(String followerId, String followedId) async {}
  @override
  Future<void> unfollowUser(String followerId, String followedId) async {}
  @override
  Stream<bool> isFollowing(String followerId, String followedId) => Stream.value(false);
  @override
  Stream<List<String>> getFollowers(String uid) => Stream.value([]);
  @override
  Stream<List<String>> getFollowing(String uid) => Stream.value([]);
  @override
  Future<Map<String, String?>> fetchUserInfo(String uid) async => {};
}

class FakeSwapProvider extends ChangeNotifier implements SwapProvider {
  @override
  bool get isLoading => false;
  @override
  Stream<List<SwapRequest>> incoming(String uid) => Stream.value([]);
  @override
  Stream<List<SwapRequest>> outgoing(String uid) => Stream.value([]);
  @override
  Stream<List<SwapRequest>> exchangeHistory(String uid) => Stream.value([]);
  @override
  Stream<int> exchangeCount(String uid) => Stream.value(12);
  @override
  Future<String> sendRequest(SwapRequest request) async => '';
  @override
  Future<void> accept(SwapRequest req) async {}
  @override
  Future<void> acceptById(String id) async {}
  @override
  Future<void> reject(String id) async {}
  @override
  Future<void> completePhysicalExchange(String id) async {}
  @override
  Future<void> cancel(String id) async {}
}

class FakeRatingProvider extends ChangeNotifier implements RatingProvider {
  @override
  bool get isLoading => false;
  @override
  String? get errorMessage => null;
  @override
  Future<bool> submitRating(Rating rating) async => true;
  @override
  Stream<List<Rating>> getRatingsForUser(String uid) => Stream.value([]);
  @override
  Future<bool> hasRated(String swapId, String reviewerId) async => false;
}

void main() {
  final List<MethodCall> clipboardLog = <MethodCall>[];

  setUp(() {
    clipboardLog.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
      if (methodCall.method == 'Clipboard.setData') {
        clipboardLog.add(methodCall);
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Widget buildProfileScreen({required AuthProvider authProvider}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<BookShelfProvider>(create: (_) => FakeBookShelfProvider()),
        ChangeNotifierProvider<NotificationProvider>(create: (_) => FakeNotificationProvider()),
        ChangeNotifierProvider<FollowProvider>(create: (_) => FakeFollowProvider()),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<SwapProvider>(create: (_) => FakeSwapProvider()),
        ChangeNotifierProvider<RatingProvider>(create: (_) => FakeRatingProvider()),
      ],
      child: const MaterialApp(
        home: ProfileScreen(),
      ),
    );
  }

  Finder findField(String label) {
    return find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == label);
  }

  testWidgets('Share Profile copies template message to clipboard', (tester) async {
    final mockAuth = MockAuthProvider(
      mockUser: const AppUser(
        uid: 'test-user-id',
        email: 'test@leafmark.com',
        displayName: 'John Doe',
        username: 'johndoe',
      ),
    );

    await tester.pumpWidget(buildProfileScreen(authProvider: mockAuth));
    await tester.pumpAndSettle();

    final shareButton = find.byTooltip('Share profile');
    expect(shareButton, findsOneWidget);

    await tester.tap(shareButton);
    await tester.pumpAndSettle();

    expect(clipboardLog.length, 1);
    expect(clipboardLog.first.method, 'Clipboard.setData');
    expect(
      clipboardLog.first.arguments['text'],
      'Check out John Doe (@johndoe) on LeafMark! 📚✨',
    );
  });

  testWidgets('ChangePasswordDialog validates fields and calls provider', (tester) async {
    final mockAuth = MockAuthProvider();

    await tester.pumpWidget(buildProfileScreen(authProvider: mockAuth));
    await tester.pumpAndSettle();

    // Scroll down to make menu items visible
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();

    final changePasswordMenu = find.text('Change Password');
    expect(changePasswordMenu, findsOneWidget);
    await tester.tap(changePasswordMenu);
    await tester.pumpAndSettle();

    expect(find.byType(ChangePasswordDialog), findsOneWidget);

    await tester.tap(find.text('Change'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your current password'), findsOneWidget);
    expect(find.text('Please enter a new password'), findsOneWidget);

    await tester.enterText(findField('Current Password'), 'oldpass');
    await tester.enterText(findField('New Password'), 'new');
    await tester.enterText(findField('Confirm New Password'), 'new');
    await tester.tap(find.text('Change'));
    await tester.pumpAndSettle();

    expect(find.text('Password must be at least 6 characters'), findsOneWidget);

    await tester.enterText(findField('New Password'), 'newpassword');
    await tester.enterText(findField('Confirm New Password'), 'newpassword');
    await tester.tap(find.text('Change'));
    await tester.pumpAndSettle();

    expect(mockAuth.changePasswordCalled, true);
    expect(mockAuth.lastCurrentPassword, 'oldpass');
    expect(mockAuth.lastNewPassword, 'newpassword');

    expect(find.byType(ChangePasswordDialog), findsNothing);
  });

  testWidgets('DeleteAccountDialog warns, validates password, and calls deleteAccount', (tester) async {
    final mockAuth = MockAuthProvider();

    await tester.pumpWidget(buildProfileScreen(authProvider: mockAuth));
    await tester.pumpAndSettle();

    // Scroll down to make menu items visible
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();

    final deleteAccountMenu = find.text('Delete Account');
    expect(deleteAccountMenu, findsOneWidget);
    await tester.tap(deleteAccountMenu);
    await tester.pumpAndSettle();

    expect(find.byType(DeleteAccountDialog), findsOneWidget);
    expect(find.textContaining('Warning: This action is permanent'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Please enter your password to confirm deletion'), findsOneWidget);

    await tester.enterText(findField('Confirm Password'), 'my_password');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(mockAuth.deleteAccountCalled, true);
    expect(mockAuth.lastDeletePassword, 'my_password');

    expect(find.byType(DeleteAccountDialog), findsNothing);
  });
}
