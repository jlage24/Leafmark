class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String username;

  final String? bio;
  final String? profilePictureUrl;
  final List<String> favoriteAuthors;
  final double rating;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.username,
    this.bio,
    this.profilePictureUrl,
    this.favoriteAuthors = const [],
    this.rating = 0.0,
  });

  AppUser copyWith({
    String? displayName,
    String? email,
    String? username,
    String? bio,
    String? profilePictureUrl,
    List<String>? favoriteAuthors,
    double? rating,
  }) => AppUser(
    uid: uid,
    email: email ?? this.email,
    displayName: displayName ?? this.displayName,
    username: username ?? this.username,
    bio: bio ?? this.bio,
    profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
    favoriteAuthors: favoriteAuthors ?? this.favoriteAuthors,
    rating: rating ?? this.rating,
  );
}