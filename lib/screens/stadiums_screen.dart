import 'package:flutter/material.dart';
import '../models/stadium.dart';
import '../services/stadium_service.dart';
import '../services/booking_service.dart';
import '../services/app_config.dart';

// Change class name from BookingScreen to StadiumsScreen
class StadiumsScreen extends StatefulWidget {
  final String? searchQuery;
  
  const StadiumsScreen({super.key, this.searchQuery});

  @override
  State<StadiumsScreen> createState() => _StadiumsScreenState();
}

// Update state class name
class _StadiumsScreenState extends State<StadiumsScreen> {
  int _selectedDateIndex = 0;
  int _selectedTimeSlot = 0;
  bool _isLoading = true;
  bool _isBooking = false;
  String? _errorMessage;
  List<Stadium> _allStadiums = [];
  List<Stadium> _filteredStadiums = [];
  final StadiumService _stadiumService = StadiumService();
  final BookingService _bookingService = BookingService();

  // Generate next 14 days for booking
  final List<DateTime> _availableDates = List.generate(
    14,
    (index) => DateTime.now().add(Duration(days: index)),
  );

  @override
  void initState() {
    super.initState();
    _loadStadiums();
  }
  
  @override
  void didUpdateWidget(StadiumsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery) {
      _applySearchFilter();
    }
  }

  // Load stadiums from the backend
  Future<void> _loadStadiums() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final stadiums = await _stadiumService.getStadiums();

      setState(() {
        _allStadiums = stadiums;
        _applySearchFilter(); // Apply search filter
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading stadiums: $e');

      // Try to load mock data if API fails
      try {
        final mockStadiums = await _stadiumService.getMockStadiums();

        setState(() {
          _allStadiums = mockStadiums;
          _applySearchFilter();
          _isLoading = false;
          _errorMessage = 'Using demo data (could not connect to server)';
        });
      } catch (mockError) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load stadiums: ${e.toString()}';
        });
      }
    }
  }

  // Apply search filter to the stadium list
  void _applySearchFilter() {
    if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      final query = widget.searchQuery!.toLowerCase();
      _filteredStadiums = _allStadiums.where((stadium) {
        return stadium.name.toLowerCase().contains(query) ||
               stadium.location.toLowerCase().contains(query);
      }).toList();
    } else {
      _filteredStadiums = List.from(_allStadiums);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadStadiums,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildDateSelector(),
            const SizedBox(height: 20),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            _buildAvailableFacilities(),
          ],
        ),
      ),
    );
  }

  // Build date selector UI
  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Date',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _availableDates.length,
            itemBuilder: (context, index) {
              final date = _availableDates[index];
              final isSelected = index == _selectedDateIndex;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDateIndex = index;
                    _selectedTimeSlot =
                        0; // Reset time slot selection when date changes
                  });
                },
                child: _buildDateItem(date, isSelected),
              );
            },
          ),
        ),
      ],
    );
  }

  // Build individual date item
  Widget _buildDateItem(DateTime date, bool isSelected) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 65,
      decoration: BoxDecoration(
        color:
            isSelected
                ? Theme.of(context).colorScheme.primary
                : isDarkMode
                ? const Color(0xFF1E1E1E)
                : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _getShortDayName(date.weekday),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color:
                  isSelected
                      ? Colors.white
                      : isDarkMode
                      ? Colors.white
                      : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            date.day.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color:
                  isSelected
                      ? Colors.white
                      : isDarkMode
                      ? Colors.white
                      : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getShortMonthName(date.month),
            style: TextStyle(
              fontSize: 12,
              color:
                  isSelected
                      ? Colors.white
                      : isDarkMode
                      ? Colors.white70
                      : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // Build sport filter chips

  // Build list of available facilities
  Widget _buildAvailableFacilities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          // Change title from "Available Facilities" to "Available Stadiums"
          'Available Stadiums',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_filteredStadiums.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Column(
                children: [
                  Icon(
                    Icons.sports_soccer_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No stadiums available',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try a different sport type or date',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredStadiums.length,
            itemBuilder: (context, index) {
              final stadium = _filteredStadiums[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _buildFacilityCard(stadium),
              );
            },
          ),
      ],
    );
  }

  // Build an individual facility card
  Widget _buildFacilityCard(Stadium stadium) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stadium image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Stack(
              children: [
                // Stadium image with proper backend URL handling
                stadium.photos.isNotEmpty
                    ? Image.network(
                      _getImageUrl(stadium.photos.first),
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) =>
                              _buildPlaceholderImage(stadium),
                    )
                    : _buildPlaceholderImage(stadium),

                // Price badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${stadium.pricePerMatch.toStringAsFixed(0)} LBP/match',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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
                // Stadium name and rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _capitalizeEachWord(stadium.name),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '4.8', // Replace with actual rating when available
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Stadium type and location
                Row(
                  children: [
                    Icon(
                      _getSportIcon(_getSportTypeFromName(stadium.name)),
                      color: Colors.grey.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getSportTypeFromName(stadium.name),
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(width: 16),
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

                const SizedBox(height: 16),

                // Available time slots
                const Text(
                  'Available Time Slots',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // Time slot selection - Use stadium calendar data
                _buildAvailableTimeSlots(stadium),

                const SizedBox(height: 16),

                // Book now button
                SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _isBooking ? null : () => _createBooking(stadium),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child:
                        _isBooking
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Text(
                              'Book Now',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  } // Build available time slots using stadium calendar data

  Widget _buildAvailableTimeSlots(Stadium stadium) {
    final selectedDate = _availableDates[_selectedDateIndex];
    final availableSlots = stadium.getAvailableSlots(selectedDate);
    if (availableSlots.isEmpty) {
      return SizedBox(
        height: 40,
        child: const Center(
          child: Text(
            'No time slots available for this date',
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    // Ensure selected time slot is within bounds
    if (_selectedTimeSlot >= availableSlots.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedTimeSlot = 0;
        });
      });
    }

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: availableSlots.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedTimeSlot;
          final slot = availableSlots[index];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTimeSlot = index;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                slot.startTime,
                style: TextStyle(
                  color: isSelected ? Colors.white : null,
                  fontWeight: isSelected ? FontWeight.bold : null,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  } // Create booking using backend API

  Future<void> _createBooking(Stadium stadium) async {
    final selectedDate = _availableDates[_selectedDateIndex];
    final availableSlots = stadium.getAvailableSlots(selectedDate);

    if (availableSlots.isEmpty) {
      _showErrorSnackBar('No time slots available for this date');
      return;
    }

    if (_selectedTimeSlot >= availableSlots.length) {
      _showErrorSnackBar('Selected time slot is not valid');
      return;
    }

    final selectedSlot = availableSlots[_selectedTimeSlot];

    // Show booking confirmation dialog
    final confirmed = await _showBookingConfirmationDialog(
      stadium,
      selectedDate,
      selectedSlot.startTime,
    );

    if (!confirmed) return;

    setState(() {
      _isBooking = true;
    });

    try {
      final result = await _bookingService.createBooking(
        stadiumId: stadium.id,
        matchDate: selectedDate,
        timeSlot: selectedSlot.startTime,
      );

      if (result['success']) {
        _showSuccessSnackBar('Booking created successfully!');
        _navigateToBookingDetails(result['data']);
        // Refresh stadium data to update availability
        _loadStadiums();
      } else {
        _showErrorSnackBar(result['message'] ?? 'Failed to create booking');
      }
    } catch (e) {
      _showErrorSnackBar('Error creating booking: ${e.toString()}');
    } finally {
      setState(() {
        _isBooking = false;
      });
    }
  }

  // Show booking confirmation dialog
  Future<bool> _showBookingConfirmationDialog(
    Stadium stadium,
    DateTime date,
    String timeSlot,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirm Booking'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Stadium: ${_capitalizeEachWord(stadium.name)}'),
                  const SizedBox(height: 8),
                  Text('Date: ${_formatDate(date)}'),
                  const SizedBox(height: 8),
                  Text('Time: $timeSlot'),
                  const SizedBox(height: 8),
                  Text(
                    'Price: ${stadium.pricePerMatch.toStringAsFixed(0)} LBP',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Are you sure you want to book this stadium?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  // Navigate to booking details
  void _navigateToBookingDetails(Map<String, dynamic> bookingData) {
    print('Booking created: $bookingData');

    // Show success dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Booking Successful!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Booking ID: ${bookingData['_id']}'),
              const SizedBox(height: 8),
              Text('Status: ${bookingData['status']}'),
              const SizedBox(height: 8),
              const Text('You will receive a confirmation shortly.'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Helper methods for UI feedback
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

  // Format date for display
  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // Helper method to determine sport type from stadium name
  String _getSportTypeFromName(String name) {
    final nameLower = name.toLowerCase();

    if (nameLower.contains('football') || nameLower.contains('soccer')) {
      return 'Football Stadium';
    } else if (nameLower.contains('basketball') ||
        nameLower.contains('court')) {
      return 'Basketball Court';
    } else if (nameLower.contains('tennis')) {
      return 'Tennis Court';
    } else if (nameLower.contains('swimming') || nameLower.contains('pool')) {
      return 'Swimming Pool';
    } else if (nameLower.contains('volleyball')) {
      return 'Volleyball Court';
    } else {
      return 'Sports Facility';
    }
  }

  // Get icon for sport type
  IconData _getSportIcon(String sportType) {
    switch (sportType.toLowerCase()) {
      case 'football stadium':
        return Icons.sports_soccer;
      case 'basketball court':
        return Icons.sports_basketball;
      case 'tennis court':
        return Icons.sports_tennis;
      case 'swimming pool':
        return Icons.pool;
      case 'volleyball court':
        return Icons.sports_volleyball;
      default:
        return Icons.sports;
    }
  }

  // Helper method to get short day name
  String _getShortDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }

  // Helper method to get short month name
  String _getShortMonthName(int month) {
    switch (month) {
      case 1:
        return 'Jan';
      case 2:
        return 'Feb';
      case 3:
        return 'Mar';
      case 4:
        return 'Apr';
      case 5:
        return 'May';
      case 6:
        return 'Jun';
      case 7:
        return 'Jul';
      case 8:
        return 'Aug';
      case 9:
        return 'Sep';
      case 10:
        return 'Oct';
      case 11:
        return 'Nov';
      case 12:
        return 'Dec';
      default:
        return '';
    }
  }

  // Helper to capitalize each word in a string
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

  // Build placeholder image for stadiums without photos
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
              _getSportIcon(_getSportTypeFromName(stadium.name)),
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

  // Helper method to construct proper image URL
  String _getImageUrl(String photoPath) {
    // If the path already starts with http, return as is
    if (photoPath.startsWith('http')) {
      return photoPath;
    }
    
    // If it's a relative path starting with /images, construct full URL
    if (photoPath.startsWith('/images')) {
      return '${AppConfig.apiUrl}$photoPath';
    }
    
    // If it's just a filename, assume it's in the stadium images directory
    return '${AppConfig.apiUrl}/images/stadiumsImages/$photoPath';
  }
}
