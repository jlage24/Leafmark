import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../books/presentation/providers/book_shelf_provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import '../../../../../main_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.status == AuthStatus.authenticated && auth.user != null) {
          final shelf = context.read<BookShelfProvider>();
          final uid = auth.user!.uid;
          Future.microtask(() => shelf.loadBooks(uid, auth.user!.displayName));
        }
        switch (auth.status) {
          case AuthStatus.unknown:
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          case AuthStatus.authenticated:
            return const MainScreen();
          case AuthStatus.unauthenticated:
            return const LoginScreen();
        }
      },
    );
  }
}
