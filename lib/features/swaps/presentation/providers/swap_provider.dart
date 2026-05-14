import 'package:flutter/material.dart';
import '../../data/services/swap_service.dart';
import '../../domain/models/swap_request.dart';

class SwapProvider extends ChangeNotifier {
  final _service = SwapService();
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Stream<List<SwapRequest>> incoming(String uid) => _service.incomingRequests(uid);
  Stream<List<SwapRequest>> outgoing(String uid) => _service.outgoingRequests(uid);
  Stream<List<SwapRequest>> exchangeHistory(String uid) => _service.exchangeHistory(uid);
  Stream<int> exchangeCount(String uid) => exchangeHistory(uid).map((list) => list.length);

  Future<String> sendRequest(SwapRequest request) async {
    _isLoading = true;
    notifyListeners();
    try {
      return await _service.createSwapRequest(request);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> accept(String id) => _service.updateStatus(id, SwapStatus.accepted);
  Future<void> reject(String id) => _service.updateStatus(id, SwapStatus.rejected);
  Future<void> cancel(String id) => _service.deleteRequest(id);
}