import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:leafmark/features/ratings/data/services/rating_service.dart';
import 'package:leafmark/features/ratings/domain/models/rating.dart';

void main() {
  // We use late variables so they are reset before every single test
  late FakeFirebaseFirestore fakeFirestore;
  late RatingService ratingService;

  setUp(() {
    // This runs before every test, giving us a completely clean, fresh "fake" database
    fakeFirestore = FakeFirebaseFirestore();
    ratingService = RatingService(firestore: fakeFirestore);
  });

  group('RatingService Unit Tests', () {
    final testDate = DateTime(2026, 1, 1);

    final dummyRating = Rating(
      id: 'rating123',
      reviewerId: 'userA',
      revieweeId: 'userB',
      swapId: 'swap999',
      rating: 5,
      bookConditionRating: 4,
      comment: 'Great swap!',
      createdAt: testDate,
    );

    test('submitRating saves a rating correctly to Firestore', () async {
      // Act
      await ratingService.submitRating(dummyRating);

      // Assert
      // Let's manually query our fake firestore to see if the data actually got saved
      final snapshot = await fakeFirestore.collection('ratings').doc('rating123').get();

      expect(snapshot.exists, isTrue);
      expect(snapshot.data()?['reviewerId'], 'userA');
      expect(snapshot.data()?['rating'], 5);
      expect(snapshot.data()?['comment'], 'Great swap!');
    });

    test('hasRated returns true if user already rated this swap', () async {
      // Arrange: Seed the database with a rating first
      await fakeFirestore.collection('ratings').doc('rating123').set(dummyRating.toMap());

      // Act
      final result = await ratingService.hasRated('swap999', 'userA');

      // Assert
      expect(result, isTrue);
    });

    test('hasRated returns false if user has NOT rated this swap', () async {
      // Arrange: Database is completely empty because of setUp()

      // Act
      final result = await ratingService.hasRated('swap999', 'userA');

      // Assert
      expect(result, isFalse);
    });
  });
}