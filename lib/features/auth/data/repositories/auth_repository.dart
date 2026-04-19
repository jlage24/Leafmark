import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/app_user.dart';

class AuthRepository {
  final _auth = FirebaseAuth.instance;
  final _db   = FirebaseFirestore.instance;

  Stream<AppUser?> get authStateChanges async* {
    await for (final user in _auth.authStateChanges()) {
      if (user == null) {
        yield null;
      } else {
        // searches for the username in the Firestore database
        final doc = await _db.collection('users').doc(user.uid).get();
        final data = doc.data();
        yield AppUser(
          uid: user.uid,
          email: user.email!,
          displayName: data?['displayName'] ?? user.displayName ?? '',
          username: data?['username'] ?? '',
        );
      }
    }
  }

  /// Returns true if the username is already taken.
  Future<bool> isUsernameTaken(String username) async {
    final doc = await _db
        .collection('usernames')
        .doc(username.toLowerCase())
        .get();
    return doc.exists;
  }

  Future<AppUser> register(
      String email,
      String password,
      String displayName,
      String username,
      ) async {
    final normalizedUsername = username.trim().toLowerCase();

    if (await isUsernameTaken(normalizedUsername)) {
      throw Exception('username-already-taken');
    }

    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    await cred.user!.updateDisplayName(displayName.trim());
    await cred.user!.reload();

    final user = AppUser(
      uid: cred.user!.uid,
      email: cred.user!.email!,
      displayName: displayName.trim(),
      username: normalizedUsername,
    );

    final batch = _db.batch();

    batch.set(_db.collection('users').doc(user.uid), {
      'email': user.email,
      'displayName': user.displayName,
      'username': user.username,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(_db.collection('usernames').doc(normalizedUsername), {
      'uid': user.uid,
    });

    await batch.commit();

    return user;
  }

  Future<AppUser> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final doc = await _db.collection('users').doc(cred.user!.uid).get();
    final data = doc.data();

    return AppUser(
      uid: cred.user!.uid,
      email: cred.user!.email!,
      displayName: data?['displayName'] ?? cred.user!.displayName ?? '',
      username: data?['username'] ?? '',
    );
  }

  Future<void> logout() => _auth.signOut();
}