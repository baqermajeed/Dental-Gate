/// Example domain model — replace or extend for your entities.
class AppUser {
  const AppUser({
    required this.id,
    required this.displayName,
  });

  final String id;
  final String displayName;
}
