import 'package:flutter/material.dart';
import '../models/stadium.dart';
import '../services/stadium_service.dart';
import '../services/booking_service.dart';
import '../services/app_config.dart';
import '../auth_service.dart';
import 'stadium_form_screen.dart';

class MyStadiumsScreen extends StatefulWidget {
  const MyStadiumsScreen({super.key});

  @override
  State<MyStadiumsScreen> createState() => _MyStadiumsScreenState();
}

class _MyStadiumsScreenState extends State<MyStadiumsScreen> {
  final StadiumService _stadiumService = StadiumService();
  final BookingService _bookingService = BookingService();
  final AuthService _authService = AuthService();
  List<Stadium> _stadiums = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatusAndLoadStadiums();
  }

  Future<void> _checkAdminStatusAndLoadStadiums() async {
    try {
      final userRole = await _authService.getUserRole();
      setState(() {
        _isAdmin = userRole == 'admin';
      });
      _loadMyStadiums();
    } catch (e) {
      print('Error checking admin status: $e');
      _loadMyStadiums();
    }
  }

  Future<void> _loadMyStadiums() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<Stadium> stadiums;
      if (_isAdmin) {
        // Admin can see all stadiums in the system
        stadiums = await _stadiumService.getAllStadiumsAdmin();
      } else {
        // Regular users see only their own stadiums
        stadiums = await _stadiumService.getMyStadiums();
      }
      
      setState(() {
        _stadiums = stadiums;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load stadiums: ${e.toString()}';
      });
    }
  }

  Future<void> _navigateToCreateStadium() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StadiumFormScreen(),
      ),
    );
    
    if (result == true) {
      _loadMyStadiums();
    }
  }

  Future<void> _navigateToEditStadium(Stadium stadium) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StadiumFormScreen(stadium: stadium),
      ),
    );
    
    if (result == true) {
      _loadMyStadiums();
    }
  }

  Future<void> _deleteStadium(Stadium stadium) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Stadium'),
        content: Text('Are you sure you want to delete "${stadium.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _stadiumService.deleteStadium(stadium.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stadium deleted successfully')),
        );
        _loadMyStadiums();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting stadium: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isAdmin ? 'All Stadiums (Admin)' : 'My Stadiums'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: _navigateToCreateStadium,
            icon: const Icon(Icons.add),
            tooltip: _isAdmin ? 'Create Stadium for Owner' : 'Add Stadium',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMyStadiums,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadMyStadiums,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _stadiums.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.stadium_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No stadiums yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create your first stadium to get started',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _navigateToCreateStadium,
                              icon: const Icon(Icons.add),
                              label: const Text('Create Stadium'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _stadiums.length,
                        itemBuilder: (context, index) {
                          final stadium = _stadiums[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildStadiumCard(stadium),
                          );
                        },
                      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateStadium,
        heroTag: "stadiums_fab",
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStadiumCard(Stadium stadium) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stadium image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                stadium.photos.isNotEmpty && stadium.photos.first.isNotEmpty
                    ? Builder(
                        builder: (context) {
                          final imageUrl = _getImageUrl(stadium.photos.first);
                          return imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  height: 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(stadium),
                                )
                              : _buildPlaceholderImage(stadium);
                        },
                      )
                    : _buildPlaceholderImage(stadium),

                // Action buttons overlay
                Positioned(
                  top: 12,
                  right: 12,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          onPressed: () => _navigateToEditStadium(stadium),
                          icon: const Icon(Icons.edit, color: Colors.white),
                          iconSize: 20,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          onPressed: () => _deleteStadium(stadium),
                          icon: const Icon(Icons.delete, color: Colors.white),
                          iconSize: 20,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        ),
                      ),
                    ],
                  ),
                ),

                // Price badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${stadium.pricePerMatch.toStringAsFixed(0)} LBP/match',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Stadium details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stadium name
                Text(
                  _capitalizeEachWord(stadium.name),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // Location
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: Colors.grey.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _capitalizeEachWord(stadium.location),
                        style: TextStyle(color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Stadium info
                Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      color: Colors.grey.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Max ${stadium.maxPlayers} players',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.access_time,
                      color: Colors.grey.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${stadium.workingHours['start']} - ${stadium.workingHours['end']}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                  ],
                ),

                // Owner information (admin only)
                if (_isAdmin) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          color: Colors.blue.shade700,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Owner: ${stadium.owner?['username'] ?? 'Unknown'}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              if (stadium.owner?['email'] != null)
                                Text(
                                  stadium.owner!['email'],
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Action buttons
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _navigateToEditStadium(stadium),
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Edit'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _deleteStadium(stadium),
                            icon: const Icon(Icons.delete, size: 18),
                            label: const Text('Delete'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _viewStadiumBookings(stadium),
                        icon: const Icon(Icons.event_note, size: 18),
                        label: const Text('View Bookings'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage(Stadium stadium) {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
            Theme.of(context).colorScheme.primary.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.stadium,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              _capitalizeEachWord(stadium.name),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _viewStadiumBookings(Stadium stadium) async {
    try {
      final bookings = await _bookingService.getBookingsForOwner(stadium.id);
      
      if (!mounted) return;
      
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => _buildBookingsBottomSheet(stadium, bookings),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading bookings: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildBookingsBottomSheet(Stadium stadium, List<Map<String, dynamic>> bookings) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bookings for ${stadium.name}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${bookings.length} total bookings',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Bookings list
              Expanded(
                child: bookings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No bookings found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'This stadium has no bookings yet.',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: bookings.length,
                        itemBuilder: (context, index) {
                          final booking = bookings[index];
                          return _buildBookingCard(booking, stadium);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, Stadium stadium) {
    final matchDate = DateTime.parse(booking['matchDate']);
    final timeSlot = booking['timeSlot'];
    final userName = booking['userId']?['username'] ?? 'Unknown User';
    final userEmail = booking['userId']?['email'] ?? '';
    final status = booking['status'];
    final penaltyApplied = booking['penaltyApplied'] ?? false;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (userEmail.isNotEmpty)
                        Text(
                          userEmail,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getStatusColor(status)),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  '${matchDate.day}/${matchDate.month}/${matchDate.year}',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(width: 24),
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  timeSlot,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
            
            if (penaltyApplied) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.warning, size: 16, color: Colors.orange.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Penalty applied',
                    style: TextStyle(
                      color: Colors.orange.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
            
            if (status != 'cancelled') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _cancelBookingAsOwner(booking, stadium),
                  icon: const Icon(Icons.cancel, size: 18),
                  label: const Text('Cancel Booking'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _cancelBookingAsOwner(Map<String, dynamic> booking, Stadium stadium) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Text(
          'Are you sure you want to cancel this booking for ${booking['userId']?['username'] ?? 'this user'}?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final result = await _bookingService.ownerCancelBooking(
          stadiumId: stadium.id,
          bookingId: booking['_id'],
        );

        if (mounted) {
          if (result['success']) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Booking cancelled successfully')),
            );
            Navigator.pop(context); // Close the bottom sheet
            _viewStadiumBookings(stadium); // Refresh the bookings
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result['message'] ?? 'Failed to cancel booking')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }

  String _getImageUrl(String? photoPath) {
    // Handle null or empty photo path
    if (photoPath == null || photoPath.isEmpty) {
      return ''; // Return empty string for placeholder handling
    }
    
    if (photoPath.startsWith('http')) {
      return photoPath;
    }
    
    if (photoPath.startsWith('/images')) {
      return '${AppConfig.baseUrl}$photoPath';
    }
    
    return '${AppConfig.baseUrl}/images/stadiumsImages/$photoPath';
  }

  String _capitalizeEachWord(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }
}