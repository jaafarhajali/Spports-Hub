// lib/models/booking.dart
class Booking {
  final String id;
  final String userId;
  final String stadiumId;
  final DateTime matchDate;
  final String timeSlot;
  final String? refereeId;
  final String status;
  final bool penaltyApplied;
  final double? penaltyAmount;
  final DateTime createdAt;
  final Map<String, dynamic>? stadiumDetails;
  final Map<String, dynamic>? refereeDetails;

  Booking({
    required this.id,
    required this.userId,
    required this.stadiumId,
    required this.matchDate,
    required this.timeSlot,
    this.refereeId,
    required this.status,
    required this.penaltyApplied,
    this.penaltyAmount,
    required this.createdAt,
    this.stadiumDetails,
    this.refereeDetails,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      stadiumId:
          json['stadiumId'] is String
              ? json['stadiumId']
              : json['stadiumId']?['_id'] ?? '',
      matchDate: DateTime.parse(json['matchDate']),
      timeSlot: json['timeSlot'] ?? '',
      refereeId:
          json['refereeId'] is String
              ? json['refereeId']
              : json['refereeId']?['_id'],
      status: json['status'] ?? 'approved',
      penaltyApplied: json['penaltyApplied'] ?? false,
      penaltyAmount: json['penaltyAmount']?.toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      stadiumDetails: json['stadiumId'] is Map ? json['stadiumId'] : null,
      refereeDetails: json['refereeId'] is Map ? json['refereeId'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stadiumId': stadiumId,
      'matchDate': matchDate.toIso8601String(),
      'timeSlot': timeSlot,
      'refereeId': refereeId,
    };
  }

  // Helper methods for booking status
  bool get isActive => status == 'approved';
  bool get isCancelled => status == 'cancelled';
  bool get isCompleted => status == 'completed';

  // Helper method to check if booking can be cancelled
  bool get canBeCancelled {
    if (!isActive) return false;
    final now = DateTime.now();
    return matchDate.isAfter(now);
  }
}
