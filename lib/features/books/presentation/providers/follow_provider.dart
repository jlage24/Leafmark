import 'package:flutter/material.dart';
import '../../data/services/follow_service.dart';

class FollowProvider extends ChangeNotifier {
  final FollowService _service;

  FollowProvider({FollowService? service}) : _service = service ?? FollowService();

  Future<void> followUser(String followerId, String followedId) async {
    await _service.followUser(followerId, followedId);
    notifyListeners();
  }

  Future<void> unfollowUser(String followerId, String followedId) async {
    await _service.unfollowUser(followerId, followedId);
    notifyListeners();
  }

  Stream<bool> isFollowing(String followerId, String followedId) {
    return _service.isFollowingStream(followerId, followedId);
  }

  Stream<int> getFollowersCount(String uid) {
    return _service.getFollowersCount(uid);
  }
}