import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/app_user.dart';

class AuthRepository {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Stream<AppUser?> get authStateChanges async* {
    await for (final user in _auth.authStateChanges()) {
      if (user == null) {
        yield null;
      } else {
        final doc = await _db.collection('users').doc(user.uid).get();
        final data = doc.data();
        yield AppUser(
          uid: user.uid,
          email: user.email!,
          displayName: data?['displayName'] ?? user.displayName ?? '',
          username: data?['username'] ?? '',
          bio: data?['bio'] as String?,
          profilePictureUrl: data?['profilePictureUrl'] as String?,
          bannerPictureUrl: data?['bannerPictureUrl'] as String?,
          favoriteAuthors: List<String>.from(data?['favoriteAuthors'] ?? []),
          rating: (data?['ratings'] as num?)?.toDouble() ?? 0.0,
          favoriteBookTitle: data?['favoriteBookTitle'] as String?,
          favoriteBookAuthor: data?['favoriteBookAuthor'] as String?,
          favoriteBookCoverUrl: data?['favoriteBookCoverUrl'] as String?,
        );
      }
    }
  }

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
      'bio': null,
      'profilePictureUrl': null,
      'favoriteAuthors': [],
      'ratings': 0.0,
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
      bio: data?['bio'] as String?,
      profilePictureUrl: data?['profilePictureUrl'] as String?,
      bannerPictureUrl: data?['bannerPictureUrl'] as String?,
      favoriteAuthors: List<String>.from(data?['favoriteAuthors'] ?? []),
      rating: (data?['ratings'] as num?)?.toDouble() ?? 0.0,
      favoriteBookTitle: data?['favoriteBookTitle'] as String?,
      favoriteBookAuthor: data?['favoriteBookAuthor'] as String?,
      favoriteBookCoverUrl: data?['favoriteBookCoverUrl'] as String?,
    );
  }

  Future<void> updateProfile({
    required String uid,
    String? bio,
    String? profilePictureUrl,
    String? bannerPictureUrl,
    List<String>? favoriteAuthors,
    String? favoriteBookTitle,
    String? favoriteBookAuthor,
    String? favoriteBookCoverUrl,
  }) async {
    final Map<String, dynamic> updates = {};
    if (bio != null) updates['bio'] = bio;
    if (profilePictureUrl != null) {
      updates['profilePictureUrl'] = profilePictureUrl;
    }
    if (bannerPictureUrl != null) {
      updates['bannerPictureUrl'] = bannerPictureUrl;
    }
    if (favoriteAuthors != null) updates['favoriteAuthors'] = favoriteAuthors;
    if (favoriteBookTitle != null) {
      updates['favoriteBookTitle'] = favoriteBookTitle;
    }
    if (favoriteBookAuthor != null) {
      updates['favoriteBookAuthor'] = favoriteBookAuthor;
    }
    if (favoriteBookCoverUrl != null) {
      updates['favoriteBookCoverUrl'] = favoriteBookCoverUrl;
    }

    if (updates.isNotEmpty) {
      await _db.collection('users').doc(uid).update(updates);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw FirebaseAuthException(
        code: 'no-user-logged-in',
        message: 'No authenticated user found.',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  Future<void> deleteAccount({required String password}) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw FirebaseAuthException(
        code: 'no-user-logged-in',
        message: 'No authenticated user found.',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );

    await user.reauthenticateWithCredential(credential);

    // Get username before deleting document to free it up
    final doc = await _db.collection('users').doc(user.uid).get();
    final username = doc.data()?['username'] as String?;

    final batch = _db.batch();
    batch.delete(_db.collection('users').doc(user.uid));
    if (username != null && username.isNotEmpty) {
      batch.delete(_db.collection('usernames').doc(username.toLowerCase()));
    }
    await batch.commit();

    await user.delete();
  }

  Future<void> logout() => _auth.signOut();
}
