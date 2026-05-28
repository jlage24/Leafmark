import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/domain/models/app_user.dart';

abstract class UserSearchRepository {
  Future<List<AppUser>> searchUsers(
      String query, {
        String? excludeUid,
        int limit = 20,
      });
}

class UserSearchService implements UserSearchRepository {
  final FirebaseFirestore _db;

  UserSearchService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<AppUser>> searchUsers(
      String query, {
        String? excludeUid,
        int limit = 20,
      }) async {
    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return [];
    }

    final Map<String, AppUser> usersById = {};

    final usernameResults = await _db
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: normalizedQuery)
        .where('username', isLessThanOrEqualTo: '$normalizedQuery\uf8ff')
        .limit(limit)
        .get();

    for (final doc in usernameResults.docs) {
      if (doc.id == excludeUid) continue;
      usersById[doc.id] = AppUser.fromMap(doc.data(), doc.id);
    }

    if (usersById.length < limit) {
      final fallbackResults = await _db.collection('users').limit(50).get();

      for (final doc in fallbackResults.docs) {
        if (doc.id == excludeUid) continue;

        final user = AppUser.fromMap(doc.data(), doc.id);

        final matchesUsername =
        user.username.toLowerCase().contains(normalizedQuery);
        final matchesDisplayName =
        user.displayName.toLowerCase().contains(normalizedQuery);

        if (matchesUsername || matchesDisplayName) {
          usersById[doc.id] = user;
        }

        if (usersById.length >= limit) break;
      }
    }

    final users = usersById.values.toList();

    users.sort((a, b) {
      final aUsernameStarts =
      a.username.toLowerCase().startsWith(normalizedQuery);
      final bUsernameStarts =
      b.username.toLowerCase().startsWith(normalizedQuery);

      if (aUsernameStarts && !bUsernameStarts) return -1;
      if (!aUsernameStarts && bUsernameStarts) return 1;

      return a.displayName.toLowerCase().compareTo(
        b.displayName.toLowerCase(),
      );
    });

    return users.take(limit).toList();
  }
}