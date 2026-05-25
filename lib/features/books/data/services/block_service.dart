import 'package:cloud_firestore/cloud_firestore.dart';

class BlockService {
  final FirebaseFirestore _db;

  BlockService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  // Bloqueia um utilizador guardando-o
  Future<void> blockUser(String currentUid, String targetUid) async {
    await _db
        .collection('users')
        .doc(currentUid)
        .collection('blocked_users')
        .doc(targetUid)
        .set({
      'blockedUid': targetUid,
      'blockedAt': FieldValue.serverTimestamp(),
    });
  }

  // Desbloqueia um utilizador
  Future<void> unblockUser(String currentUid, String targetUid) async {
    await _db
        .collection('users')
        .doc(currentUid)
        .collection('blocked_users')
        .doc(targetUid)
        .delete();
  }

  // Stream para obter os IDs dos utilizadores bloqueados pelo utilizador atual em tempo real
  Stream<List<String>> getBlockedUsersStream(String currentUid) {
    return _db
        .collection('users')
        .doc(currentUid)
        .collection('blocked_users')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.id).toList());
  }

  // Verifica pontualmente se existe um bloqueio
  Future<bool> isBlocked(String currentUid, String targetUid) async {
    final doc = await _db
        .collection('users')
        .doc(currentUid)
        .collection('blocked_users')
        .doc(targetUid)
        .get();
    return doc.exists;
  }

  // Verifica se há um bloqueio mútuo (importante para os Swaps)
  Future<bool> hasBlockRelationship(String uid1, String uid2) async {
    final blockedBy1 = await isBlocked(uid1, uid2);
    if (blockedBy1) return true;
    final blockedBy2 = await isBlocked(uid2, uid1);
    return blockedBy2;
  }
}