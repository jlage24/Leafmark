class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String username;

  final String? bio;
  final String? profilePictureUrl;
  final String? bannerPictureUrl;
  final List<String> favoriteAuthors;
  final double rating;

  final String? favoriteBookTitle;
  final String? favoriteBookAuthor;
  final String? favoriteBookCoverUrl;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.username,
    this.bio,
    this.profilePictureUrl,
    this.bannerPictureUrl,
    this.favoriteAuthors = const [],
    this.rating = 0.0,
    this.favoriteBookTitle,
    this.favoriteBookAuthor,
    this.favoriteBookCoverUrl,
  });

  AppUser copyWith({
    String? displayName,
    String? email,
    String? username,
    String? bio,
    String? profilePictureUrl,
    String? bannerPictureUrl,
    List<String>? favoriteAuthors,
    double? rating,
    String? favoriteBookTitle,
    String? favoriteBookAuthor,
    String? favoriteBookCoverUrl,
  }) => AppUser(
    uid: uid,
    email: email ?? this.email,
    displayName: displayName ?? this.displayName,
    username: username ?? this.username,
    bio: bio ?? this.bio,
    profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
    bannerPictureUrl: bannerPictureUrl ?? this.bannerPictureUrl,
    favoriteAuthors: favoriteAuthors ?? this.favoriteAuthors,
    rating: rating ?? this.rating,
    favoriteBookTitle: favoriteBookTitle ?? this.favoriteBookTitle,
    favoriteBookAuthor: favoriteBookAuthor ?? this.favoriteBookAuthor,
    favoriteBookCoverUrl: favoriteBookCoverUrl ?? this.favoriteBookCoverUrl,
  );
}