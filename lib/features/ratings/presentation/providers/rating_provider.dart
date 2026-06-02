import 'package:flutter/material.dart';
import '../../domain/models/rating.dart';
import '../../data/services/rating_service.dart';

class RatingProvider extends ChangeNotifier {
  final RatingService _ratingService;

  RatingProvider({RatingService? ratingService})
    : _ratingService = ratingService ?? RatingService();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Submits the rating to Firestore
  Future<bool> submitRating(Rating rating) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Security check: Make sure they haven't already rated this exact swap
      final alreadyRated = await _ratingService.hasRated(
        rating.swapId,
        rating.reviewerId,
      );
      if (alreadyRated) {
        _errorMessage = 'You have already rated this exchange.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _ratingService.submitRating(rating);
      _isLoading = false;
      notifyListeners();
      return true; // Success!
    } catch (e) {
      _errorMessage = 'Failed to submit rating. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Stream<List<Rating>> getRatingsForUser(String uid) {
    return _ratingService.getRatingsForUser(uid);
  }

  // Checks if the current user has already rated this swap
  Future<bool> hasRated(String swapId, String reviewerId) async {
    try {
      return await _ratingService.hasRated(swapId, reviewerId);
    } catch (e) {
      return false;
    }
  }
}
