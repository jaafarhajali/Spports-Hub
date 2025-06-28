class AppNotification {
  final String id;
  final String userId;
  final String message;
  final bool read;
  final String type; // 'invite', 'info', 'other'
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.message,
    required this.read,
    required this.type,
    this.metadata,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    try {
      return AppNotification(
        id: json['_id']?.toString() ?? '',
        userId: json['user']?.toString() ?? '',
        message: json['message']?.toString() ?? '',
        read: json['read'] ?? false,
        type: json['type'] ?? 'other',
        metadata: json['metadata'] as Map<String, dynamic>?,
        createdAt: DateTime.tryParse(json['createdAt']) ?? DateTime.now(),
      );
    } catch (e) {
      print('Error parsing notification JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user': userId,
      'message': message,
      'read': read,
      'type': type,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Helper methods for different notification types
  bool get isInvite => type == 'invite';
  bool get isInfo => type == 'info';
  bool get isOther => type == 'other';

  // Get team invite specific data
  String? get teamId => metadata?['teamId']?.toString();
  String? get senderId => metadata?['senderId']?.toString();
  String? get tournamentId => metadata?['tournamentId']?.toString();

  // Get tournament specific data
  String? get acceptedUserId => metadata?['acceptedUserId']?.toString();
  String? get rejectedUserId => metadata?['rejectedUserId']?.toString();

  // Helper to get formatted time ago
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  // Get appropriate icon for notification type
  String get iconName {
    switch (type) {
      case 'invite':
        return 'group_add';
      case 'info':
        return 'info';
      default:
        return 'notifications';
    }
  }

  // Copy with method for updating notification state
  AppNotification copyWith({
    String? id,
    String? userId,
    String? message,
    bool? read,
    String? type,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      message: message ?? this.message,
      read: read ?? this.read,
      type: type ?? this.type,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'AppNotification(id: $id, message: $message, type: $type, read: $read)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppNotification && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}