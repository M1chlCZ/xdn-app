class AppUser {
  const AppUser({
    required this.uid,
    this.email,
    required this.admin,
  });
  final String uid;
  final String? email;
  final bool admin;
}