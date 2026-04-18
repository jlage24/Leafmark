class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String username;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.username,
  });

  AppUser copyWith({
    String? displayName,
    String? email,
    String? username,
  }) => AppUser(
    uid: uid,
    email: email ?? this.email,
    displayName: displayName ?? this.displayName,
    username: username ?? this.username,
  );
}