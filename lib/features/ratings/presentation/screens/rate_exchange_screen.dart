import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/rating_provider.dart';
import '../../domain/models/rating.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class RateExchangeScreen extends StatefulWidget {
  final String swapId;
  final String revieweeId;

  const RateExchangeScreen({
    super.key,
    required this.swapId,
    required this.revieweeId,
  });

  @override
  State<RateExchangeScreen> createState() => _RateExchangeScreenState();
}

class _RateExchangeScreenState extends State<RateExchangeScreen> {
  int _partnerRating = 0;
  int _bookConditionRating = 0;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Validation: Must select stars for both fields
    if (_partnerRating == 0 || _bookConditionRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a star rating for both fields.'),
        ),
      );
      return;
    }

    // Using context.read to access providers without listening to changes here
    final authProvider = context.read<AuthProvider>();
    final ratingProvider = context.read<RatingProvider>();
    final currentUser = authProvider.user;

    if (currentUser == null) return;

    final newRating = Rating(
      id: const Uuid().v4(), // Generates a unique ID for the document
      reviewerId: currentUser.uid,
      revieweeId: widget.revieweeId,
      swapId: widget.swapId,
      rating: _partnerRating,
      bookConditionRating: _bookConditionRating,
      comment: _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim(),
      createdAt: DateTime.now(),
    );

    final success = await ratingProvider.submitRating(newRating);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for your feedback!')),
      );
      Navigator.of(context).pop(); // Go back to the ChatScreen
    } else if (mounted && ratingProvider.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ratingProvider.errorMessage!)));
    }
  }

  // Helper widget to build the 5-star interactive row
  Widget _buildStarRow(
    String title,
    int currentRating,
    ValueChanged<int> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(
                index < currentRating ? Icons.star : Icons.star_border,
                color: index < currentRating ? Colors.amber : Colors.grey,
                size: 32,
              ),
              onPressed: () => onChanged(index + 1),
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch for loading state to show the spinner
    final isLoading = context.watch<RatingProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Rate Exchange')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStarRow(
              'How was your trading partner?',
              _partnerRating,
              (val) => setState(() => _partnerRating = val),
            ),
            const SizedBox(height: 24),

            _buildStarRow(
              'How accurate was the book condition?',
              _bookConditionRating,
              (val) => setState(() => _bookConditionRating = val),
            ),
            const SizedBox(height: 24),

            Text(
              'Leave a comment (optional)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Share your experience...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Submit Rating',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
