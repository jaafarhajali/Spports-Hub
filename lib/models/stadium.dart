// lib/models/stadium.dart
class SlotModel {
  final String startTime;
  final String endTime;
  final bool isBooked;
  final String? bookingId;

  SlotModel({
    required this.startTime,
    required this.endTime,
    required this.isBooked,
    this.bookingId,
  });

  factory SlotModel.fromJson(Map<String, dynamic> json) {
    return SlotModel(
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      isBooked: json['isBooked'] ?? false,
      bookingId: json['bookingId'],
    );
  }
}

class CalendarEntry {
  final DateTime date;
  final List<SlotModel> slots;

  CalendarEntry({required this.date, required this.slots});

  factory CalendarEntry.fromJson(Map<String, dynamic> json) {
    return CalendarEntry(
      date: DateTime.parse(json['date']),
      slots:
          (json['slots'] as List?)
              ?.map((slot) => SlotModel.fromJson(slot))
              .toList() ??
          [],
    );
  }
}

class Stadium {
  final String id;
  final String ownerId;
  final String name;
  final String location;
  final List<String> photos;
  final double pricePerMatch;
  final int maxPlayers;
  final Map<String, dynamic> penaltyPolicy;
  final Map<String, dynamic> workingHours;
  final List<CalendarEntry> calendar;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? owner;

  Stadium({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.location,
    required this.photos,
    required this.pricePerMatch,
    required this.maxPlayers,
    required this.penaltyPolicy,
    required this.workingHours,
    required this.calendar,
    required this.createdAt,
    required this.updatedAt,
    this.owner,
  });

  factory Stadium.fromJson(Map<String, dynamic> json) {
    return Stadium(
      id: json['_id'] ?? '',
      ownerId:
          json['ownerId'] is String
              ? json['ownerId']
              : json['ownerId']?['_id'] ?? '',
      name: json['name'] ?? 'Unknown Stadium',
      location: json['location'] ?? 'Unknown Location',
      photos: List<String>.from(json['photos'] ?? []),
      pricePerMatch: (json['pricePerMatch'] ?? 0).toDouble(),
      maxPlayers: json['maxPlayers'] ?? 1,
      penaltyPolicy:
          json['penaltyPolicy'] ?? {'hoursBefore': 2, 'penaltyAmount': 0},
      workingHours: json['workingHours'] ?? {'start': '09:00', 'end': '18:00'},
      calendar:
          (json['calendar'] as List?)
              ?.map((entry) => CalendarEntry.fromJson(entry))
              .toList() ??
          [],
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'])
              : DateTime.now(),
      owner: json['ownerId'] is Map ? json['ownerId'] : null,
    );
  }
  // Helper method to get available time slots for a specific date
  List<SlotModel> getAvailableSlots(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final calendarEntry = calendar.firstWhere(
      (entry) =>
          DateTime(entry.date.year, entry.date.month, entry.date.day) ==
          dateOnly,
      orElse: () => CalendarEntry(date: dateOnly, slots: []),
    );

    // If calendar entry exists, return its available slots
    if (calendarEntry.slots.isNotEmpty) {
      return calendarEntry.slots.where((slot) => !slot.isBooked).toList();
    }

    // Fallback: generate time slots from working hours if calendar is empty
    return _generateTimeSlotsFromWorkingHours();
  }

  // Helper method to get all time slots for a specific date (both available and unavailable)
  List<SlotModel> getAllSlots(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final calendarEntry = calendar.firstWhere(
      (entry) =>
          DateTime(entry.date.year, entry.date.month, entry.date.day) ==
          dateOnly,
      orElse: () => CalendarEntry(date: dateOnly, slots: []),
    );

    // If calendar entry exists, return all its slots
    if (calendarEntry.slots.isNotEmpty) {
      return calendarEntry.slots;
    }

    // Fallback: generate time slots from working hours if calendar is empty
    return _generateTimeSlotsFromWorkingHours();
  }

  // Helper method to generate time slots from working hours (fallback)
  List<SlotModel> _generateTimeSlotsFromWorkingHours() {
    final List<SlotModel> slots = [];

    final startTime = workingHours['start'] ?? '09:00';
    final endTime = workingHours['end'] ?? '18:00';

    // Parse start and end times
    final startParts = startTime.split(':');
    final endParts = endTime.split(':');

    if (startParts.length < 2 || endParts.length < 2) {
      return []; // Return empty if invalid format
    }

    int startHour = int.tryParse(startParts[0]) ?? 9;
    int endHour = int.tryParse(endParts[0]) ?? 18;

    // If end time is 00:00, treat as 24:00
    if (endHour == 0) {
      endHour = 24;
    }

    // Generate hourly slots
    for (int hour = startHour; hour < endHour; hour++) {
      final start = '${hour.toString().padLeft(2, '0')}:00';
      final end = '${(hour + 1).toString().padLeft(2, '0')}:00';

      slots.add(SlotModel(startTime: start, endTime: end, isBooked: false));
    }

    return slots;
  }

  // Helper method to check if a specific slot is available
  bool isSlotAvailable(DateTime date, String timeSlot) {
    final availableSlots = getAvailableSlots(date);
    return availableSlots.any((slot) => slot.startTime == timeSlot);
  }
}
