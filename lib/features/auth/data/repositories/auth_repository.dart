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

    // Helper to delete all documents in a collection
    Future<void> deleteCollection(String collectionPath) async {
      final snapshot = await _db.collection(collectionPath).get();
      if (snapshot.docs.isEmpty) return;
      final b = _db.batch();
      for (final doc in snapshot.docs) {
        b.delete(doc.reference);
      }
      await b.commit();
    }

    // Delete user subcollections
    await deleteCollection('users/${user.uid}/shelf');
    await deleteCollection('users/${user.uid}/wishlist');
    await deleteCollection('users/${user.uid}/followers');
    await deleteCollection('users/${user.uid}/following');
    await deleteCollection('users/${user.uid}/blocked_users');

    // Wipe swaps and chats involving the user
    final swapsAsRequester = await _db.collection('swap_requests').where('requesterId', isEqualTo: user.uid).get();
    final swapsAsOwner = await _db.collection('swap_requests').where('ownerId', isEqualTo: user.uid).get();
    
    final swapBatch = _db.batch();
    final processedSwaps = <String>{};
    for (final doc in [...swapsAsRequester.docs, ...swapsAsOwner.docs]) {
      if (!processedSwaps.add(doc.id)) continue;
      
      // Delete the messages subcollection of this chat
      await deleteCollection('chats/${doc.id}/messages');
      
      swapBatch.delete(doc.reference);
      swapBatch.delete(_db.collection('chats').doc(doc.id));
    }
    await swapBatch.commit();

    // Wipe ratings
    final ratingsAsReviewer = await _db.collection('ratings').where('reviewerId', isEqualTo: user.uid).get();
    final ratingsAsReviewee = await _db.collection('ratings').where('revieweeId', isEqualTo: user.uid).get();
    final ratingBatch = _db.batch();
    for (final doc in [...ratingsAsReviewer.docs, ...ratingsAsReviewee.docs]) {
      ratingBatch.delete(doc.reference);
    }
    await ratingBatch.commit();

    // Wipe reports
    final reportsAsReporter = await _db.collection('reports').where('reporterId', isEqualTo: user.uid).get();
    final reportsAsReported = await _db.collection('reports').where('reportedUid', isEqualTo: user.uid).get();
    final reportBatch = _db.batch();
    for (final doc in [...reportsAsReporter.docs, ...reportsAsReported.docs]) {
      reportBatch.delete(doc.reference);
    }
    await reportBatch.commit();

    // Wipe notifications
    final notifsAsRecipient = await _db.collection('notifications').where('recipientId', isEqualTo: user.uid).get();
    final notifsAsSender = await _db.collection('notifications').where('senderId', isEqualTo: user.uid).get();
    final notifBatch = _db.batch();
    for (final doc in [...notifsAsRecipient.docs, ...notifsAsSender.docs]) {
      notifBatch.delete(doc.reference);
    }
    await notifBatch.commit();

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
