class User {
  final String userId;
  final String email;
  final String password;
  final String name;
  final String contactInformation;
  final String city;
  final String town;
  final double latitude;
  final double longitude;

  User({
    required this.userId,
    required this.email,
    required this.password,
    required this.name,
    required this.contactInformation,
    required this.city,
    required this.town,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'email': email,
        'password': password,
        'name': name,
        'contactInformation': contactInformation,
        'city': city,
        'town': town,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        userId: json['userId'],
        email: json['email'],
        password: json['password'],
        name: json['name'],
        contactInformation: json['contactInformation'],
        city: json['city'],
        town: json['town'],
        latitude: json['latitude'],
        longitude: json['longitude'],
      );
}