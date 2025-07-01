import 'package:flutter/material.dart';
import '../models/stadium.dart';
import '../services/stadium_service.dart';
import '../services/booking_service.dart';
import '../services/app_config.dart';
import '../themes/app_theme.dart';
import 'stadium_form_screen.dart';

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
  bool _canCreateStadiums = false;

  // Generate next 14 days for booking
  final List<DateTime> _availableDates = List.generate(
    14,
    (index) => DateTime.now().add(Duration(days: index)),
  );

  @override
  void initState() {
    super.initState();
    _loadStadiums();
    _checkCreatePermission();
  }

  Future<void> _checkCreatePermission() async {
    final canCreate = await _stadiumService.canCreateStadiums();
    setState(() {
      _canCreateStadiums = canCreate;
    });
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

  Future<void> _navigateToCreateStadium() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StadiumFormScreen(),
      ),
    );
    
    if (result == true) {
      _loadStadiums(); // Reload stadiums after creating
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
      _loadStadiums(); // Reload stadiums after editing
    }
  }

  Future<void> _deleteStadium(Stadium stadium) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Stadium'),
        content: Text('Are you sure you want to delete "${stadium.name}"?'),
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
        _loadStadiums(); // Reload stadiums after deletion
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting stadium: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppTheme.darkBackground : AppTheme.lightBackground,
      body: RefreshIndicator(
        color: AppTheme.primaryBlue,
        onRefresh: _loadStadiums,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDateSelector(),
                    const SizedBox(height: 24),
                    if (_errorMessage != null) _buildErrorBanner(),
                    _buildAvailableFacilities(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _canCreateStadiums
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: AppTheme.gradientTeal,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: AppTheme.mediumShadow,
              ),
              child: FloatingActionButton(
                onPressed: _navigateToCreateStadium,
                heroTag: "stadiums_main_fab",
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warningYellow.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warningYellow.withOpacity(0.3)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.warningYellow.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.info_outline,
              color: AppTheme.warningYellow,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notice',
                  style: TextStyle(
                    color: AppTheme.warningYellow,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: AppTheme.warningYellow.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build date selector UI
  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppTheme.gradientTeal,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.softShadow,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Select Date',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
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
                    _selectedTimeSlot = 0;
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
    final isToday = DateTime.now().day == date.day && 
                   DateTime.now().month == date.month && 
                   DateTime.now().year == date.year;

    return Container(
      margin: const EdgeInsets.only(right: 16),
      width: 70,
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(
                colors: AppTheme.gradientTeal,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: !isSelected
            ? (isDarkMode ? AppTheme.darkCard : AppTheme.lightCard)
            : null,
        borderRadius: BorderRadius.circular(18),
        border: isToday && !isSelected
            ? Border.all(color: AppTheme.primaryBlue, width: 2)
            : null,
        boxShadow: isSelected ? AppTheme.mediumShadow : AppTheme.softShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _getShortDayName(date.weekday),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: isSelected
                  ? Colors.white
                  : (isDarkMode ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            date.day.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? Colors.white
                  : (isDarkMode ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getShortMonthName(date.month),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isSelected
                  ? Colors.white.withOpacity(0.9)
                  : (isDarkMode ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary),
            ),
          ),
          if (isToday)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : AppTheme.primaryBlue,
                shape: BoxShape.circle,
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
        Container(
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
                Icons.stadium,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Available Stadiums (${_filteredStadiums.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (_isLoading)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60.0),
              child: Column(
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
                  const SizedBox(height: 16),
                  Text(
                    'Loading stadiums...',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (_filteredStadiums.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.stadium,
                      size: 48,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No stadiums available',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try selecting a different date or check back later',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                    textAlign: TextAlign.center,
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
                padding: const EdgeInsets.only(bottom: 20.0),
                child: _buildFacilityCard(stadium),
              );
            },
          ),
      ],
    );
  }

  // Build an individual facility card
  Widget _buildFacilityCard(Stadium stadium) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final gradients = [
      AppTheme.gradientBlue,
      AppTheme.gradientTeal,
      AppTheme.gradientPurple,
      AppTheme.gradientOrange,
      AppTheme.gradientGreen,
      AppTheme.gradientPink,
    ];
    final gradient = gradients[stadium.hashCode % gradients.length];

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.mediumShadow,
        border: Border.all(
          color: isDarkMode
              ? AppTheme.darkBorder.withOpacity(0.3)
              : AppTheme.lightBorder.withOpacity(0.5),
          width: 1,
        ),
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
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: gradient.first.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.payment,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${stadium.pricePerMatch.toStringAsFixed(0)} LBP',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Edit/Delete menu (only show if user can edit this specific stadium)
                FutureBuilder<bool>(
                  future: _stadiumService.canEditStadium(stadium),
                  builder: (context, snapshot) {
                    if (snapshot.data == true) {
                      return Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: Colors.white),
                            onSelected: (value) {
                              if (value == 'edit') {
                                _navigateToEditStadium(stadium);
                              } else if (value == 'delete') {
                                _deleteStadium(stadium);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),

          // Stadium details
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stadium name with gradient accent
                Row(
                  children: [
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
                    Expanded(
                      child: Text(
                        _capitalizeEachWord(stadium.name),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          const Text(
                            '4.8',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.amber,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Stadium type and location with improved styling
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? AppTheme.darkSurface.withOpacity(0.5)
                        : AppTheme.lightSecondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: gradient.first.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getSportIcon(_getSportTypeFromName(stadium.name)),
                          color: gradient.first,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getSportTypeFromName(stadium.name),
                        style: TextStyle(
                          color: isDarkMode
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryTeal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: AppTheme.secondaryTeal,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _capitalizeEachWord(stadium.location),
                          style: TextStyle(
                            color: isDarkMode
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Available time slots with better styling
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.accentPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.access_time,
                        color: AppTheme.accentPurple,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Available Time Slots',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDarkMode
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Time slot selection - Use stadium calendar data
                _buildAvailableTimeSlots(stadium),

                const SizedBox(height: 20),

                // Book now button with gradient styling
                Container(
                  height: 50,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.first.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isBooking ? null : () => _createBooking(stadium),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isBooking
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.calendar_today, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Book Now',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
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
  } // Build available time slots using stadium calendar data

  Widget _buildAvailableTimeSlots(Stadium stadium) {
    final selectedDate = _availableDates[_selectedDateIndex];
    final availableSlots = stadium.getAvailableSlots(selectedDate);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (availableSlots.isEmpty) {
      return Container(
        height: 50,
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
              Icons.error_outline,
              color: AppTheme.errorRed,
              size: 16,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'No time slots available for this date',
                style: TextStyle(
                  color: AppTheme.errorRed,
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                ),
              ),
            ),
          ],
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
      height: 44,
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
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: AppTheme.gradientPurple,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: !isSelected
                    ? (isDarkMode
                        ? AppTheme.darkSurface.withOpacity(0.5)
                        : AppTheme.lightSecondary)
                    : null,
                borderRadius: BorderRadius.circular(12),
                border: !isSelected
                    ? Border.all(
                        color: isDarkMode
                            ? AppTheme.darkBorder.withOpacity(0.3)
                            : AppTheme.lightBorder,
                        width: 1,
                      )
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.accentPurple.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                slot.startTime,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isDarkMode
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
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
    final gradients = [
      AppTheme.gradientBlue,
      AppTheme.gradientTeal,
      AppTheme.gradientPurple,
      AppTheme.gradientOrange,
      AppTheme.gradientGreen,
      AppTheme.gradientPink,
    ];
    final gradient = gradients[stadium.hashCode % gradients.length];

    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _getSportIcon(_getSportTypeFromName(stadium.name)),
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _capitalizeEachWord(stadium.name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Stadium Image',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to construct proper image URL
  String _getImageUrl(String? photoPath) {
    // Handle null or empty photo path
    if (photoPath == null || photoPath.isEmpty) {
      return ''; // Return empty string for placeholder handling
    }
    
    // If the path already starts with http, return as is
    if (photoPath.startsWith('http')) {
      return photoPath;
    }
    
    // If it's a relative path starting with /images, construct full URL
    if (photoPath.startsWith('/images')) {
      return '${AppConfig.baseUrl}$photoPath';
    }
    
    // If it's just a filename, assume it's in the stadium images directory
    return '${AppConfig.baseUrl}/images/stadiumsImages/$photoPath';
  }
}
