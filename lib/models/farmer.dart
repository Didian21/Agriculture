class Farmer {
  final String username;
  final String password;
  final String profileName;
  final List<String> records;

  Farmer({
    required this.username,
    required this.password,
    required this.profileName,
    this.records = const [],
  });
}
