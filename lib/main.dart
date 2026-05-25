import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/app_theme.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/books/presentation/providers/book_shelf_provider.dart';
import 'features/chat/presentation/providers/chat_provider.dart';
import 'features/search/presentation/providers/search_provider.dart';
import 'features/swaps/presentation/providers/swap_provider.dart';
import 'features/ratings/presentation/providers/rating_provider.dart';
import 'features/wishlist/presentation/providers/wishlist_provider.dart';
import 'features/books/presentation/providers/block_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const LeafMarkApp());
}

class LeafMarkApp extends StatelessWidget {
  const LeafMarkApp({super.key});

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
        ChangeNotifierProxyProvider<AuthProvider, ChatProvider>(
          create: (ctx) => ChatProvider(auth: ctx.read<AuthProvider>()),
          update: (ctx, auth, previous) =>
          previous ?? ChatProvider(auth: auth),
        ),
      ],
      child: MaterialApp(
        title: 'LeafMark',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const SplashScreen(),
      ),
    );
  }
}