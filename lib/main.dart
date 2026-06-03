import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'core/app_theme.dart';
import 'core/theme_provider.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/books/presentation/providers/book_shelf_provider.dart';
import 'features/chat/presentation/providers/chat_provider.dart';
import 'features/search/presentation/providers/search_provider.dart';
import 'features/swaps/presentation/providers/swap_provider.dart';
import 'features/ratings/presentation/providers/rating_provider.dart';
import 'features/wishlist/presentation/providers/wishlist_provider.dart';
import 'features/books/presentation/providers/block_provider.dart';
import 'features/books/presentation/providers/follow_provider.dart';
import 'features/notifications/presentation/providers/notification_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final prefs = await SharedPreferences.getInstance();
  final savedTheme = prefs.getString('theme_mode');
  runApp(LeafMarkApp(savedTheme: savedTheme));
}

class LeafMarkApp extends StatelessWidget {
  final String? savedTheme;
  const LeafMarkApp({super.key, this.savedTheme});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BookShelfProvider()),
        ChangeNotifierProvider(create: (_) => SwapProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => RatingProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => BlockProvider()),
        ChangeNotifierProvider(create: (_) => FollowProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider(savedTheme)),
        ChangeNotifierProxyProvider<AuthProvider, ChatProvider>(
          create: (ctx) => ChatProvider(auth: ctx.read<AuthProvider>()),
          update: (ctx, auth, previous) => previous ?? ChatProvider(auth: auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
          create: (ctx) => NotificationProvider(auth: ctx.read<AuthProvider>()),
          update: (ctx, auth, previous) =>
              previous ?? NotificationProvider(auth: auth),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'LeafMark',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.themeMode,
            themeAnimationDuration: const Duration(milliseconds: 500),
            themeAnimationCurve: Curves.easeInOutCubic,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
