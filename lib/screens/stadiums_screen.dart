import 'package:flutter/material.dart';
import '../models/stadium.dart';
import '../services/stadium_service.dart';

// Change class name from BookingScreen to StadiumsScreen
class StadiumsScreen extends StatefulWidget {
  const StadiumsScreen({super.key});

  @override
  State<StadiumsScreen> createState() => _StadiumsScreenState();
}

// Update state class name
class _StadiumsScreenState extends State<StadiumsScreen> {
  int _selectedDateIndex = 0;
  String _selectedSport = 'All';
  int _selectedTimeSlot = 0;
  bool _isLoading = true;
  String? _errorMessage;
  List<Stadium> _allStadiums = [];
  List<Stadium> _filteredStadiums = [];
  final StadiumService _stadiumService = StadiumService();

  // List of available sports for filtering
  final List<String> _sportTypes = [
    'All',
    'Football',
    'Basketball',
    'Tennis',
    'Swimming',
    'Volleyball',
  ];

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
        _applyFilters(); // Apply initial filters
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading stadiums: $e');

      // Try to load mock data if API fails
      try {
        final mockStadiums = await _stadiumService.getMockStadiums();

        setState(() {
          _allStadiums = mockStadiums;
          _applyFilters();
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

  // Apply filters to the stadium list
  void _applyFilters() {
    if (_selectedSport == 'All') {
      _filteredStadiums = List.from(_allStadiums);
    } else {
      _filteredStadiums =
          _allStadiums.where((stadium) {
            final name = stadium.name.toLowerCase();
            final sportType = _selectedSport.toLowerCase();
            return name.contains(sportType);
          }).toList();
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
            _buildSportFilters(),
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
  Widget _buildSportFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sport Type',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children:
              _sportTypes.map((sport) {
                final isSelected = sport == _selectedSport;
                return FilterChip(
                  label: Text(sport),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedSport = sport;
                      _applyFilters();
                    });
                  },
                  backgroundColor: Colors.grey.withOpacity(0.1),
                  selectedColor: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.2),
                  checkmarkColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                    color:
                        isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).textTheme.bodyLarge?.color,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

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
    final timeSlots = _generateTimeSlots(
      stadium.workingHours['start'] ?? '09:00',
      stadium.workingHours['end'] ?? '18:00',
    );

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
                // Stadium image
                stadium.photos.isNotEmpty
                    ? Image.network(
                      stadium.photos.first,
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
                      '\$${stadium.pricePerHour.toStringAsFixed(0)}/match',
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

                // Time slot selection
                SizedBox(
                  height: 40,
                  child:
                      timeSlots.isEmpty
                          ? const Center(
                            child: Text(
                              'No time slots available',
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                          : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: timeSlots.length,
                            itemBuilder: (context, index) {
                              final isSelected = index == _selectedTimeSlot;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedTimeSlot = index;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                            : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    timeSlots[index],
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : null,
                                      fontWeight:
                                          isSelected ? FontWeight.bold : null,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                ),

                const SizedBox(height: 16),

                // Book now button
                SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final selectedDate = _availableDates[_selectedDateIndex];
                      final selectedTime =
                          timeSlots.isNotEmpty
                              ? timeSlots[_selectedTimeSlot]
                              : '10:00 AM';

                      _navigateToBookingDetails(
                        stadium.id,
                        selectedDate,
                        selectedTime,
                        stadium.pricePerHour,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
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
  }

  // Navigate to booking details screen
  void _navigateToBookingDetails(
    String stadiumId,
    DateTime date,
    String timeSlot,
    double price,
  ) {
    print('Navigating to booking details:');
    print('Stadium ID: $stadiumId');
    print('Date: $date');
    print('Time Slot: $timeSlot');
    print('Price: \$${price.toStringAsFixed(2)}');

    // TODO: Implement navigation to booking details screen
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => BookingDetailsScreen(
    //       stadiumId: stadiumId,
    //       date: date,
    //       timeSlot: timeSlot,
    //       price: price,
    //     ),
    //   ),
    // );
  }

  // Build placeholder image for stadiums without photos
  Widget _buildPlaceholderImage(Stadium stadium) {
    return Container(
      height: 160,
      width: double.infinity,
      color: Colors.grey.shade300,
      child: Center(
        child: Icon(
          _getSportIcon(_getSportTypeFromName(stadium.name)),
          size: 64,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  // Generate time slots based on working hours
  List<String> _generateTimeSlots(String start, String end) {
    final List<String> slots = [];

    // Parse start and end times
    final startParts = start.split(':');
    final endParts = end.split(':');

    if (startParts.length < 2 || endParts.length < 2) {
      return ['10:00 AM', '11:00 AM', '12:00 PM']; // Default fallback
    }

    int startHour = int.tryParse(startParts[0]) ?? 9;
    int endHour = int.tryParse(endParts[0]) ?? 18;

    // If end time is 00:00, treat as 24:00
    if (endHour == 0) {
      endHour = 24;
    }

    // Generate hourly slots
    for (int hour = startHour; hour < endHour; hour++) {
      final displayHour = hour % 12 == 0 ? 12 : hour % 12;
      final amPm = hour < 12 ? 'AM' : 'PM';
      slots.add('$displayHour:00 $amPm');
    }

    return slots;
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
}
