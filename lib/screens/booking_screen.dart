import 'package:flutter/material.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _selectedDateIndex = 0;
  String _selectedSport = 'All';
  int _selectedTimeSlot = 0;

  final List<String> _sportTypes = [
    'All',
    'Football',
    'Basketball',
    'Tennis',
    'Swimming',
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDateSelector(),
        const SizedBox(height: 20),
        _buildSportFilters(),
        const SizedBox(height: 20),
        _buildAvailableFacilities(context),
      ],
    );
  }

  /// Builds the date selection component
  Widget _buildDateSelector() {
    final today = DateTime.now();
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Date',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.primary.withAlpha(25),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 14, // Show 2 weeks
              itemBuilder: (context, index) {
                final date = today.add(Duration(days: index));
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
        ),
      ],
    );
  }

  /// Builds an individual date selection item
  Widget _buildDateItem(DateTime date, bool isSelected) {
    final dayName = _getShortDayName(date.weekday);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final isToday =
        DateTime.now().day == date.day &&
        DateTime.now().month == date.month &&
        DateTime.now().year == date.year;

    return Container(
      width: 65,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: isSelected ? colorScheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isToday && !isSelected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.primary.withAlpha(51), // ~0.2 opacity
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Today',
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (!isToday || isSelected)
            Text(
              dayName,
              style: TextStyle(
                color:
                    isSelected
                        ? Colors.white
                        : isDarkMode
                        ? Colors.grey.shade300
                        : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? Colors.white.withAlpha(51) // ~0.2 opacity
                      : isToday
                      ? colorScheme.primary.withAlpha(25) // ~0.1 opacity
                      : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                date.day.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color:
                      isSelected
                          ? Colors.white
                          : isToday
                          ? colorScheme.primary
                          : isDarkMode
                          ? Colors.white
                          : Colors.black87,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getShortMonthName(date.month),
            style: TextStyle(
              color:
                  isSelected
                      ? Colors.white.withAlpha(230) // ~0.9 opacity
                      : isDarkMode
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  /// Helper method to get short day name from weekday number
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

  /// Helper method to get short month name
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

  /// Builds the sport type filter section
  Widget _buildSportFilters() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sport Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _sportTypes.length,
              itemBuilder: (context, index) {
                final sport = _sportTypes[index];
                final isSelected = sport == _selectedSport;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSport = sport;
                    });
                  },
                  child: _buildFilterChip(sport, isSelected),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Builds an individual filter chip for sport types
  Widget _buildFilterChip(String label, bool selected) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Chip(
        label: Text(label),
        labelStyle: TextStyle(
          color:
              selected
                  ? Colors.white
                  : isDarkMode
                  ? Colors.white
                  : Colors.black87,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
        backgroundColor: selected ? colorScheme.primary : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(
            color:
                selected
                    ? Colors.transparent
                    : Colors.grey.withAlpha(76), // ~0.3 opacity
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  /// Builds the list of available facilities to book
  Widget _buildAvailableFacilities(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Facilities',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        _buildFacilityCard(
          'City Sports Center',
          'Football Field',
          '2 km away',
          ['10:00 AM', '11:00 AM', '12:00 PM', '1:00 PM', '2:00 PM', '3:00 PM'],
          50,
          'https://images.unsplash.com/photo-1594470117722-de4b9a02ebed',
          4.8,
          context,
        ),
        const SizedBox(height: 16),
        _buildFacilityCard(
          'Olympic Complex',
          'Basketball Court',
          '4 km away',
          ['9:00 AM', '10:00 AM', '3:00 PM', '4:00 PM', '5:00 PM'],
          35,
          'https://images.unsplash.com/photo-1546519638-68e109498ffc',
          4.6,
          context,
        ),
        const SizedBox(height: 16),
        _buildFacilityCard(
          'Green Park Tennis Club',
          'Tennis Court',
          '1.5 km away',
          ['8:00 AM', '9:00 AM', '2:00 PM', '6:00 PM', '7:00 PM'],
          40,
          'https://images.unsplash.com/photo-1595435934249-5df7ed86e1c0',
          4.7,
          context,
        ),
      ],
    );
  }

  /// Builds an individual card for a facility that can be booked
  Widget _buildFacilityCard(
    String name,
    String type,
    String distance,
    List<String> availableSlots,
    double price,
    String imageUrl,
    double rating,
    BuildContext context,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13), // ~0.05 opacity
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              // Facility image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Image.network(
                  imageUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

              // Price badge
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(179), // ~0.7 opacity
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.attach_money,
                        color: Colors.greenAccent,
                        size: 16,
                      ),
                      Text(
                        '$price/hr',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Distance badge
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(230), // ~0.9 opacity
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: colorScheme.primary,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        distance,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              _getSportIcon(type),
                              size: 16,
                              color:
                                  isDarkMode
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              type,
                              style: TextStyle(
                                color:
                                    isDarkMode
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Rating
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withAlpha(
                          25,
                        ), // ~0.1 opacity
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            rating.toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Available Slots',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: availableSlots.length,
                    itemBuilder: (context, index) {
                      final bool isSelected = index == _selectedTimeSlot;
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
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: colorScheme.primary),
                            borderRadius: BorderRadius.circular(30),
                            color:
                                isSelected
                                    ? colorScheme.primary
                                    : Colors.transparent,
                          ),
                          child: Text(
                            availableSlots[index],
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isSelected
                                      ? Colors.white
                                      : colorScheme.primary,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Book Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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

  /// Helper method to get sport icon
  IconData _getSportIcon(String sportType) {
    if (sportType.contains('Football')) {
      return Icons.sports_soccer;
    } else if (sportType.contains('Basketball')) {
      return Icons.sports_basketball;
    } else if (sportType.contains('Tennis')) {
      return Icons.sports_tennis;
    } else if (sportType.contains('Swimming')) {
      return Icons.pool;
    } else {
      return Icons.sports;
    }
  }
}
