// lib/models/stadium.dart
class Stadium {
  final String id;
  final String name;
  final String location;
  final List<String> photos;
  final double pricePerHour;
  final Map<String, dynamic> workingHours;
  final Map<String, dynamic> penaltyPolicy;
  final Map<String, dynamic> owner;
  final DateTime createdAt;

  Stadium({
    required this.id,
    required this.name,
    required this.location,
    required this.photos,
    required this.pricePerHour,
    required this.workingHours,
    required this.penaltyPolicy,
    required this.owner,
    required this.createdAt,
  });

  factory Stadium.fromJson(Map<String, dynamic> json) {
    return Stadium(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unknown Stadium',
      location: json['location'] ?? 'Unknown Location',
      photos: List<String>.from(json['photos'] ?? []),
      pricePerHour: json['pricePerHour']?.toDouble() ?? 0.0,
      workingHours: json['workingHours'] ?? {'start': '09:00', 'end': '18:00'},
      penaltyPolicy:
          json['penaltyPolicy'] ?? {'hoursBefore': 2, 'penaltyAmount': 0},
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
