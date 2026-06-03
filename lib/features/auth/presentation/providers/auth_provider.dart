import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/models/app_user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final _repo = AuthRepository();

  AppUser? _user;
  AuthStatus _status = AuthStatus.unknown;
  String? _errorMessage;

  AppUser? get user => _user;
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _repo.authStateChanges.listen((user) {
      _user = user;
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

  Future<bool> updateProfile({
    String? bio,
    String? profilePictureUrl,
    String? bannerPictureUrl,
    List<String>? favoriteAuthors,
    String? favoriteBookTitle,
    String? favoriteBookAuthor,
    String? favoriteBookCoverUrl,
  }) async {
    if (_user == null) return false;
    _errorMessage = null;

    try {
      await _repo
          .updateProfile(
            uid: _user!.uid,
            bio: bio,
            profilePictureUrl: profilePictureUrl,
            bannerPictureUrl: bannerPictureUrl,
            favoriteAuthors: favoriteAuthors,
            favoriteBookTitle: favoriteBookTitle,
            favoriteBookAuthor: favoriteBookAuthor,
            favoriteBookCoverUrl: favoriteBookCoverUrl,
          )
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw Exception("Network timeout.");
            },
          );

      _user = _user!.copyWith(
        bio: bio,
        profilePictureUrl: profilePictureUrl,
        bannerPictureUrl: bannerPictureUrl,
        favoriteAuthors: favoriteAuthors,
        favoriteBookTitle: favoriteBookTitle,
        favoriteBookAuthor: favoriteBookAuthor,
        favoriteBookCoverUrl: favoriteBookCoverUrl,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update profile. Try again.';
      notifyListeners();
      return false;
    }
  }

  String _parseError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password incorrect.';
      case 'email-already-in-use':
        return 'This email is already in use.';
      case 'weak-password':
        return 'Your password should be at least 6 characters long.';
      case 'network-request-failed':
        return 'Could not connect to the internet.';
      default:
        return 'An unknown error occurred. Try again.';
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _errorMessage = null;
    try {
      await _repo.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _parsePasswordError(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unknown error occurred. Try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAccount({required String password}) async {
    _errorMessage = null;
    try {
      await _repo.deleteAccount(password: password);
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _parsePasswordError(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unknown error occurred. Try again.';
      notifyListeners();
      return false;
    }
  }

  String _parsePasswordError(String code) {
    switch (code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Current password incorrect.';
      case 'weak-password':
        return 'Your new password should be at least 6 characters long.';
      case 'requires-recent-login':
        return 'Please log out and log back in to perform this action.';
      default:
        return 'An unknown error occurred. Try again.';
    }
  }
}
