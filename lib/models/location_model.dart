class Location {
  final String locationId;
  final String documentType;
  final String address;
  final double latitude;
  final double longitude;
  final String city;
  final String state;
  final String country;
  final String contactInformation;

  Location({
    required this.locationId,
    required this.documentType,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.state,
    required this.country,
    required this.contactInformation,
  });

  Map<String, dynamic> toJson() => {
        'locationId': locationId,
        'documentType': documentType,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'city': city,
        'state': state,
        'country': country,
        'contactInformation': contactInformation,
      };

  factory Location.fromJson(Map<String, dynamic> json) => Location(
        locationId: json['locationId'],
        documentType: json['documentType'],
        address: json['address'],
        latitude: json['latitude'],
        longitude: json['longitude'],
        city: json['city'],
        state: json['state'],
        country: json['country'],
        contactInformation: json['contactInformation'],
      );
}