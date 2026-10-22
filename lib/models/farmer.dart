class Farmer {
  final String username;
  final String password;
  final String profileName;
  final String landSize;
  final String cropPlanted;
  final String location;
  final String contactNumber;
  final List<String> records;

  Farmer({
    required this.username,
    required this.password,
    required this.profileName,
    this.landSize = '1.0 ha',
    this.cropPlanted = 'Rice',
    this.location = 'Pagsanjan',
    this.contactNumber = '09123456789',
    this.records = const [],
  });
}
