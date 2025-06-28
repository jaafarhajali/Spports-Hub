import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';
import '../services/team_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  final TeamService _teamService = TeamService();

  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Unread', 'Team Invites', 'Info'];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Try to load from backend first, fallback to mock data
      List<AppNotification> notifications;
      try {
        notifications = await _notificationService.getAllNotifications();
        if (notifications.isEmpty) {
          // If no notifications from backend, show mock data for demo
          notifications = await _notificationService.getMockNotifications();
        }
      } catch (e) {
        print('Failed to load from backend, using mock data: $e');
        notifications = await _notificationService.getMockNotifications();
      }

      setState(() {
        _notifications = _notificationService.sortByDate(notifications);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<AppNotification> get _filteredNotifications {
    switch (_selectedFilter) {
      case 'Unread':
        return _notifications.where((n) => !n.read).toList();
      case 'Team Invites':
        return _notificationService.getTeamInvitations(_notifications);
      case 'Info':
        return _notificationService.getInfoNotifications(_notifications);
      case 'All':
      default:
        return _notifications;
    }
  }

  Future<void> _handleInviteAction(AppNotification notification, bool accept) async {
    try {
      final teamId = notification.teamId;
      final notificationId = notification.id;

      if (teamId == null) {
        _showSnackBar('Invalid invitation data', isError: true);
        return;
      }

      setState(() => _isLoading = true);

      bool success;
      if (accept) {
        success = await _teamService.acceptInvite(
          teamId: teamId,
          notificationId: notificationId,
        );
        if (success) {
          _showSnackBar('Successfully joined the team!');
        }
      } else {
        success = await _teamService.rejectInvite(
          notificationId: notificationId,
        );
        if (success) {
          _showSnackBar('Invitation declined');
        }
      }

      if (success) {
        // Remove the notification from the list
        setState(() {
          _notifications.removeWhere((n) => n.id == notification.id);
        });
      }
    } catch (e) {
      _showSnackBar('Failed to process invitation: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(AppNotification notification) async {
    if (notification.read) return;

    try {
      await _notificationService.markAsRead(notification.id);
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = notification.copyWith(read: true);
        }
      });
    } catch (e) {
      print('Failed to mark as read: $e');
    }
  }

  Future<void> _deleteNotification(AppNotification notification) async {
    try {
      final success = await _notificationService.deleteNotification(notification.id);
      if (success) {
        setState(() {
          _notifications.removeWhere((n) => n.id == notification.id);
        });
        _showSnackBar('Notification deleted');
      }
    } catch (e) {
      _showSnackBar('Failed to delete notification: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: _isLoading && _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Loading notifications...',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading notifications',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadNotifications,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Filter chips
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _filters.map((filter) {
                            final isSelected = filter == _selectedFilter;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(filter),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedFilter = filter;
                                  });
                                },
                                backgroundColor: isDarkMode
                                    ? Colors.grey[800]
                                    : Colors.grey[200],
                                selectedColor: colorScheme.primary.withOpacity(0.2),
                                checkmarkColor: colorScheme.primary,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    // Notifications list
                    Expanded(
                      child: _filteredNotifications.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.notifications_none,
                                    size: 64,
                                    color: Colors.grey.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No notifications found',
                                    style: Theme.of(context).textTheme.headlineSmall,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _selectedFilter == 'All'
                                        ? 'You\'re all caught up!'
                                        : 'No $_selectedFilter notifications',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadNotifications,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _filteredNotifications.length,
                                itemBuilder: (context, index) {
                                  final notification = _filteredNotifications[index];
                                  return _buildNotificationCard(notification, colorScheme, isDarkMode);
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildNotificationCard(
    AppNotification notification,
    ColorScheme colorScheme,
    bool isDarkMode,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: notification.read
            ? (isDarkMode ? const Color(0xFF1E1E1E) : Colors.white)
            : (isDarkMode ? const Color(0xFF2A2A2A) : colorScheme.primary.withOpacity(0.05)),
        child: InkWell(
          onTap: () => _markAsRead(notification),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon, type, and timestamp
                Row(
                  children: [
                    // Icon based on notification type
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getNotificationColor(notification.type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getNotificationIcon(notification.type),
                        color: _getNotificationColor(notification.type),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getNotificationTypeLabel(notification.type),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getNotificationColor(notification.type),
                            ),
                          ),
                          Text(
                            notification.timeAgo,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Unread indicator
                    if (!notification.read)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),

                    // Delete button
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 18,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      onPressed: () => _deleteNotification(notification),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Message
                Text(
                  notification.message,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: notification.read ? FontWeight.normal : FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),

                // Action buttons for team invites
                if (notification.isInvite && notification.teamId != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () => _handleInviteAction(notification, false),
                          child: const Text('Decline'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () => _handleInviteAction(notification, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Accept'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'invite':
        return Icons.group_add;
      case 'info':
        return Icons.info_outline;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'invite':
        return Colors.blue;
      case 'info':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getNotificationTypeLabel(String type) {
    switch (type) {
      case 'invite':
        return 'TEAM INVITATION';
      case 'info':
        return 'INFORMATION';
      default:
        return 'NOTIFICATION';
    }
  }
}