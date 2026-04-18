import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/app_user.dart';

class AuthRepository {
  final _auth = FirebaseAuth.instance;
  final _db   = FirebaseFirestore.instance;

  Stream<AppUser?> get authStateChanges => _auth.authStateChanges().map(
        (user) => user != null
        ? AppUser(uid: user.uid, email: user.email!, displayName: user.displayName ?? '')
        : null,
  );

  Future<AppUser> register(String email, String password, String name) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(), password: password,
    );
    await cred.user!.updateDisplayName(name.trim());
    await cred.user!.reload();
    final user = AppUser(
      uid: cred.user!.uid,
      email: cred.user!.email!,
      displayName: name.trim(),
    );
    await _db.collection('users').doc(user.uid).set({
      'email': user.email,
      'displayName': user.displayName,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return user;
  }

  Future<AppUser> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(), password: password,
    );
    return AppUser(
      uid: cred.user!.uid,
      email: cred.user!.email!,
      displayName: cred.user!.displayName ?? '',
    );
  }

  Future<void> logout() => _auth.signOut();
}