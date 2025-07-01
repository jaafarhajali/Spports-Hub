import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import '../themes/app_theme.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  final BookingService _bookingService = BookingService();
  List<Booking> _bookings = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBookingHistory();
  }

  Future<void> _loadBookingHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _bookingService.getUserBookings();

      if (result['success']) {
        final bookings =
            (result['data'] as List)
                .map((json) => Booking.fromJson(json))
                .toList();

        setState(() {
          _bookings = bookings;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load bookings';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading bookings: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelBooking(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Booking'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Are you sure you want to cancel this booking?'),
              const SizedBox(height: 12),
              Text('Stadium: ${booking.stadiumDetails?['name'] ?? 'Unknown'}'),
              Text('Date: ${_formatDate(booking.matchDate)}'),
              Text('Time: ${booking.timeSlot}'),
              if (booking.penaltyApplied && booking.penaltyAmount != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Note: A cancellation penalty of ${booking.penaltyAmount!.toStringAsFixed(0)} LBP may be applied.',
                    style: const TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await _bookingService.cancelBooking(booking.id);

      // Close loading dialog
      Navigator.of(context).pop();

      if (result['success']) {
        _showSuccessSnackBar('Booking cancelled successfully');
        _loadBookingHistory(); // Refresh the list
      } else {
        _showErrorSnackBar(result['message'] ?? 'Failed to cancel booking');
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      _showErrorSnackBar('Error cancelling booking: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: Text(
          'Booking History',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDarkMode ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDarkMode ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
        ),
        actions: [
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
              onPressed: _loadBookingHistory,
              tooltip: 'Refresh',
            ),
          ),
        ],
      ),
      body: _buildBody(isDarkMode),
    );
  }

  Widget _buildBody(bool isDarkMode) {
    if (_isLoading) {
      return Center(
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
              'Loading your bookings...',
              style: TextStyle(
                color: isDarkMode ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
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
                'Error Loading Bookings',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? AppTheme.darkSurface.withOpacity(0.5)
                      : AppTheme.lightSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDarkMode ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    fontSize: 14,
                  ),
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
                child: ElevatedButton.icon(
                  onPressed: _loadBookingHistory,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text(
                    'Try Again',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_bookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.event_busy,
                  size: 48,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Bookings Found',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You haven\'t made any stadium bookings yet.',
                style: TextStyle(
                  color: isDarkMode ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppTheme.gradientTeal,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.mediumShadow,
                ),
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.stadium, color: Colors.white),
                  label: const Text(
                    'Browse Stadiums',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primaryBlue,
      onRefresh: _loadBookingHistory,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppTheme.gradientBlue,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.history,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Your Bookings (${_bookings.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final booking = _bookings[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildBookingCard(booking, isDarkMode),
                  );
                },
                childCount: _bookings.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Booking booking, bool isDarkMode) {
    final isActive = booking.status.toLowerCase() == 'confirmed';
    final isPending = booking.status.toLowerCase() == 'pending';
    final isCancelled = booking.status.toLowerCase() == 'cancelled';

    Color statusColor;
    IconData statusIcon;
    List<Color> statusGradient;

    if (isActive) {
      statusColor = AppTheme.successGreen;
      statusIcon = Icons.check_circle_rounded;
      statusGradient = AppTheme.gradientGreen;
    } else if (isPending) {
      statusColor = AppTheme.warningYellow;
      statusIcon = Icons.schedule_rounded;
      statusGradient = AppTheme.gradientOrange;
    } else if (isCancelled) {
      statusColor = AppTheme.errorRed;
      statusIcon = Icons.cancel_rounded;
      statusGradient = AppTheme.gradientPink;
    } else {
      statusColor = AppTheme.primaryBlue;
      statusIcon = Icons.help_rounded;
      statusGradient = AppTheme.gradientBlue;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode
              ? AppTheme.darkBorder.withOpacity(0.3)
              : AppTheme.lightBorder.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: AppTheme.mediumShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with stadium name and status
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: statusGradient,
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    booking.stadiumDetails?['name'] ?? 'Unknown Stadium',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: statusGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        booking.status.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Booking details in a card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? AppTheme.darkSurface.withOpacity(0.5)
                    : AppTheme.lightSecondary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    Icons.calendar_today_rounded,
                    'Date',
                    _formatDate(booking.matchDate),
                    isDarkMode,
                  ),
                  _buildDetailRow(
                    Icons.access_time_rounded,
                    'Time',
                    booking.timeSlot,
                    isDarkMode,
                  ),
                  _buildDetailRow(
                    Icons.location_on_rounded,
                    'Location',
                    booking.stadiumDetails?['location'] ?? 'N/A',
                    isDarkMode,
                  ),
                ],
              ),
            ),

            if (booking.penaltyApplied && booking.penaltyAmount != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.errorRed.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_rounded,
                      color: AppTheme.errorRed,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Penalty: ${booking.penaltyAmount!.toStringAsFixed(0)} LBP',
                      style: const TextStyle(
                        color: AppTheme.errorRed,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            ],

            // Action buttons
            if (booking.canBeCancelled) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.errorRed,
                    width: 1.5,
                  ),
                ),
                child: TextButton.icon(
                  onPressed: () => _cancelBooking(booking),
                  icon: const Icon(Icons.cancel_rounded, size: 18, color: AppTheme.errorRed),
                  label: const Text(
                    'Cancel Booking',
                    style: TextStyle(
                      color: AppTheme.errorRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    bool isDarkMode, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: (color ?? AppTheme.primaryBlue).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: color ?? AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: isDarkMode ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color ??
                    (isDarkMode ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
