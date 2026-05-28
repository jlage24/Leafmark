import 'package:flutter/material.dart';
import '../../data/services/swap_service.dart';
import '../../domain/models/swap_request.dart';

class SwapProvider extends ChangeNotifier {
  final SwapService _service;

  SwapProvider({SwapService? service}) : _service = service ?? SwapService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Stream<List<SwapRequest>> incoming(String uid) =>
      _service.incomingRequests(uid);

  Stream<List<SwapRequest>> outgoing(String uid) =>
      _service.outgoingRequests(uid);

  Stream<List<SwapRequest>> exchangeHistory(String uid) =>
      _service.exchangeHistory(uid);

  Stream<int> exchangeCount(String uid) =>
      exchangeHistory(uid).map((list) => list.length);

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

  Future<void> accept(SwapRequest req) async {
    try {
      await _service.acceptSwapAndLockBooks(req);
    } catch (e) {
      debugPrint('Accept error: $e');
      rethrow;
    }
  }

  Future<void> acceptById(String id) async {
    try {
      await _service.acceptSwapById(id);
    } catch (e) {
      debugPrint('Accept by id error: $e');
      rethrow;
    }
  }

  Future<void> reject(String id) async {
    try {
      await _service.rejectSwapById(id);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> completePhysicalExchange(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.completePhysicalExchange(id);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancel(String id) async {
    try {
      await _service.cancelRequest(id);
    } catch (e) {
      rethrow;
    }
  }
}