// lib/models/academy.dart
class Academy {
  final String id;
  final String name;
  final String description;
  final String location;
  final List<String> sports;
  final List<String> photos;
  final double rating;
  final String ageGroup;
  final Map<String, dynamic> contact;
  final Map<String, dynamic> owner;
  final DateTime createdAt;

  Academy({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.sports,
    required this.photos,
    required this.rating,
    required this.ageGroup,
    required this.contact,
    required this.owner,
    required this.createdAt,
  });

  factory Academy.fromJson(Map<String, dynamic> json) {
    return Academy(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unknown Academy',
      description: json['description'] ?? 'No description available',
      location: json['location'] ?? 'Unknown Location',
      sports: List<String>.from(json['sports'] ?? []),
      photos: List<String>.from(json['photos'] ?? []),
      rating: json['rating']?.toDouble() ?? 4.0,
      ageGroup: json['ageGroup'] ?? 'All Ages',
      contact: {
        'phone': json['phoneNumber'] ?? json['contact']?['phone'] ?? '',
        'email': json['email'] ?? json['contact']?['email'] ?? '',
      },
      owner:
          (json['ownerId'] is Map)
              ? json['ownerId']
              : {'username': 'Unknown Owner', 'email': ''},
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
    );
  }
}
