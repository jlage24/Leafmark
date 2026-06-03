import 'package:flutter/material.dart';
import '../../data/services/block_service.dart';

class BlockProvider extends ChangeNotifier {
  final BlockService _service;

  BlockProvider({BlockService? service}) : _service = service ?? BlockService();

  Future<void> blockUser(String currentUid, String targetUid) async {
    await _service.blockUser(currentUid, targetUid);
    notifyListeners();
  }

  Future<void> unblockUser(String currentUid, String targetUid) async {
    await _service.unblockUser(currentUid, targetUid);
    notifyListeners();
  }

  Stream<List<String>> getBlockedUsers(String currentUid) {
    return _service.getBlockedUsersStream(currentUid);
  }
}
