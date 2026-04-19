import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/models/app_user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final _repo = AuthRepository();

  AppUser?   _user;
  AuthStatus _status = AuthStatus.unknown;
  String?    _errorMessage;

  AppUser?   get user         => _user;
  AuthStatus get status       => _status;
  String?    get errorMessage => _errorMessage;

  AuthProvider() {
    _repo.authStateChanges.listen((user) {
      _user   = user;
      _status = user != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated;
      notifyListeners();
    });
  }

  Future<bool> register(
      String email,
      String password,
      String displayName,
      String username,
      ) async {
    _errorMessage = null;
    try {
      _user = await _repo.register(email, password, displayName, username);
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _parseError(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      if (e.toString().contains('username-already-taken')) {
        _errorMessage = 'This username is already taken.';
      } else {
        _errorMessage = 'An unknown error occurred. Try again.';
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _errorMessage = null;
    try {
      _user = await _repo.login(email, password);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _parseError(e.code);
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() => _repo.logout();

  String _parseError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential': return 'Email or password incorrect.';
      case 'email-already-in-use': return 'This email is already in use.';
      case 'weak-password':        return 'Your password should be at least 6 characters long.';
      case 'network-request-failed': return 'Could not connect to the internet.';
      default: return 'An unknown error occurred. Try again.';
    }
  }
}