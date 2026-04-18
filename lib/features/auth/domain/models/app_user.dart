class AppUser {
  final String uid;
  final String email;
  final String displayName;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
  });

  AppUser copyWith({String? displayName, String? email}) => AppUser(
    uid: uid,
    email: email ?? this.email,
    displayName: displayName ?? this.displayName,
  );
}