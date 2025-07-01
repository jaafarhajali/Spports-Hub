import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';
import '../services/team_service.dart';
import '../themes/app_theme.dart';

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

  Future<void> _handleInviteAction(
    AppNotification notification,
    bool accept,
  ) async {
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
      // Try backend first, but fallback to frontend deletion
      try {
        final success = await _notificationService.deleteNotification(
          notification.id,
        );
        if (success) {
          setState(() {
            _notifications.removeWhere((n) => n.id == notification.id);
          });
          _showSnackBar('Notification deleted');
        } else {
          // Backend failed, delete from frontend only
          setState(() {
            _notifications.removeWhere((n) => n.id == notification.id);
          });
          _showSnackBar('Notification deleted');
        }
      } catch (e) {
        // Backend call failed, delete from frontend
        print('Backend delete failed, deleting frontend only: $e');
        setState(() {
          _notifications.removeWhere((n) => n.id == notification.id);
        });
        _showSnackBar('Notification deleted');
      }
    } catch (e) {
      _showSnackBar('Failed to delete notification: $e', isError: true);
    }
  }

  Future<void> _clearAllNotifications() async {
    if (_notifications.isEmpty) {
      _showSnackBar('No notifications to clear');
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear All Notifications'),
          content: Text(
            'Are you sure you want to clear all ${_notifications.length} notifications? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      // Try backend first, but fallback to frontend clearing
      try {
        final success = await _notificationService.clearAllNotifications();
        if (success) {
          setState(() {
            _notifications.clear();
          });
          _showSnackBar('All notifications cleared');
        } else {
          // Backend failed, clear from frontend only
          setState(() {
            _notifications.clear();
          });
          _showSnackBar('All notifications cleared');
        }
      } catch (e) {
        // Backend call failed, clear from frontend
        print('Backend clear failed, clearing frontend only: $e');
        setState(() {
          _notifications.clear();
        });
        _showSnackBar('All notifications cleared');
      }
    } catch (e) {
      _showSnackBar('Failed to clear notifications: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color:
                isDarkMode
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color:
              isDarkMode ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
        ),
        actions: [
          if (_notifications.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppTheme.gradientOrange,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.softShadow,
              ),
              child: IconButton(
                icon: const Icon(Icons.clear_all, color: Colors.white),
                onPressed: _isLoading ? null : _clearAllNotifications,
                tooltip: 'Clear all notifications',
              ),
            ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppTheme.gradientTeal,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.softShadow,
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadNotifications,
            ),
          ),
        ],
      ),
      body:
          _isLoading && _notifications.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const CircularProgressIndicator(
                        color: AppTheme.primaryBlue,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Loading notifications...',
                      style: TextStyle(
                        color:
                            isDarkMode
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
              : _error != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.errorRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppTheme.errorRed.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppTheme.errorRed,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Error loading notifications',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color:
                              isDarkMode
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              isDarkMode
                                  ? AppTheme.darkSurface.withOpacity(0.5)
                                  : AppTheme.lightSecondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color:
                                isDarkMode
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.lightTextSecondary,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppTheme.gradientBlue,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppTheme.mediumShadow,
                        ),
                        child: ElevatedButton(
                          onPressed: _loadNotifications,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Retry',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : Column(
                children: [
                  // Filter chips with professional styling
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: AppTheme.gradientPurple,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.filter_list,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Filter Notifications',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color:
                                    isDarkMode
                                        ? AppTheme.darkTextPrimary
                                        : AppTheme.lightTextPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children:
                                _filters.map((filter) {
                                  final isSelected = filter == _selectedFilter;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedFilter = filter;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient:
                                              isSelected
                                                  ? const LinearGradient(
                                                    colors:
                                                        AppTheme.gradientBlue,
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  )
                                                  : null,
                                          color:
                                              !isSelected
                                                  ? (isDarkMode
                                                      ? AppTheme.darkCard
                                                      : AppTheme.lightCard)
                                                  : null,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border:
                                              !isSelected
                                                  ? Border.all(
                                                    color:
                                                        isDarkMode
                                                            ? AppTheme
                                                                .darkBorder
                                                            : AppTheme
                                                                .lightBorder,
                                                    width: 1,
                                                  )
                                                  : null,
                                          boxShadow:
                                              isSelected
                                                  ? AppTheme.softShadow
                                                  : null,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (isSelected)
                                              const Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            if (isSelected)
                                              const SizedBox(width: 4),
                                            Text(
                                              filter,
                                              style: TextStyle(
                                                color:
                                                    isSelected
                                                        ? Colors.white
                                                        : (isDarkMode
                                                            ? AppTheme
                                                                .darkTextSecondary
                                                            : AppTheme
                                                                .lightTextSecondary),
                                                fontWeight:
                                                    isSelected
                                                        ? FontWeight.w600
                                                        : FontWeight.w500,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Notifications list
                  Expanded(
                    child:
                        _filteredNotifications.isEmpty
                            ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryBlue.withOpacity(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: const Icon(
                                        Icons.notifications_none,
                                        size: 48,
                                        color: AppTheme.primaryBlue,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'No notifications found',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            isDarkMode
                                                ? AppTheme.darkTextPrimary
                                                : AppTheme.lightTextPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _selectedFilter == 'All'
                                          ? 'You\'re all caught up!'
                                          : 'No $_selectedFilter notifications',
                                      style: TextStyle(
                                        color:
                                            isDarkMode
                                                ? AppTheme.darkTextSecondary
                                                : AppTheme.lightTextSecondary,
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                            : RefreshIndicator(
                              color: AppTheme.primaryBlue,
                              onRefresh: _loadNotifications,
                              child: CustomScrollView(
                                slivers: [
                                  SliverPadding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    sliver: SliverList(
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) {
                                          final notification =
                                              _filteredNotifications[index];
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 16,
                                            ),
                                            child: _buildNotificationCard(
                                              notification,
                                              colorScheme,
                                              isDarkMode,
                                            ),
                                          );
                                        },
                                        childCount:
                                            _filteredNotifications.length,
                                      ),
                                    ),
                                  ),
                                  const SliverToBoxAdapter(
                                    child: SizedBox(height: 20),
                                  ),
                                ],
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
    final notificationColor = _getNotificationColor(notification.type);
    final gradients = {
      'invite': AppTheme.gradientBlue,
      'info': AppTheme.gradientGreen,
    };
    final gradient = gradients[notification.type] ?? AppTheme.gradientPurple;

    return Container(
      decoration: BoxDecoration(
        color:
            notification.read
                ? (isDarkMode ? AppTheme.darkCard : AppTheme.lightCard)
                : (isDarkMode
                    ? AppTheme.darkCard.withOpacity(0.9)
                    : notificationColor.withOpacity(0.05)),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              notification.read
                  ? (isDarkMode
                      ? AppTheme.darkBorder.withOpacity(0.3)
                      : AppTheme.lightBorder.withOpacity(0.5))
                  : notificationColor.withOpacity(0.3),
          width: notification.read ? 1 : 2,
        ),
        boxShadow:
            notification.read ? AppTheme.softShadow : AppTheme.mediumShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _markAsRead(notification),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon, type, and timestamp
                Row(
                  children: [
                    // Gradient accent bar
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradient,
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Icon based on notification type
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getNotificationIcon(notification.type),
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors:
                                    gradient
                                        .map((c) => c.withOpacity(0.1))
                                        .toList(),
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: notificationColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _getNotificationTypeLabel(notification.type),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: notificationColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notification.timeAgo,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color:
                                  isDarkMode
                                      ? AppTheme.darkTextTertiary
                                      : AppTheme.lightTextTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Unread indicator
                    if (!notification.read)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: notificationColor.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.circle,
                          size: 8,
                          color: Colors.white,
                        ),
                      ),

                    // Delete button
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.errorRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppTheme.errorRed,
                        ),
                        onPressed: () => _deleteNotification(notification),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Message in a container
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        isDarkMode
                            ? AppTheme.darkSurface.withOpacity(0.5)
                            : AppTheme.lightSecondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          notification.read ? FontWeight.w500 : FontWeight.w600,
                      color:
                          isDarkMode
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                      height: 1.4,
                    ),
                  ),
                ),

                // Action buttons for team invites
                if (notification.isInvite && notification.teamId != null) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.errorRed,
                              width: 1.5,
                            ),
                          ),
                          child: OutlinedButton(
                            onPressed:
                                _isLoading
                                    ? null
                                    : () => _handleInviteAction(
                                      notification,
                                      false,
                                    ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide.none,
                              foregroundColor: AppTheme.errorRed,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.close, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'Decline',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: notificationColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed:
                                _isLoading
                                    ? null
                                    : () =>
                                        _handleInviteAction(notification, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'Accept',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
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
        return AppTheme.primaryBlue;
      case 'info':
        return AppTheme.successGreen;
      default:
        return AppTheme.accentPurple;
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
