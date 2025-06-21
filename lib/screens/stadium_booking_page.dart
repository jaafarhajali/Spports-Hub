import 'package:flutter/material.dart';
import '../services/stadium_service.dart';
import '../services/booking_service.dart';
import '../widgets/booking_confirmation_dialog.dart';

class StadiumBookingPage extends StatefulWidget {
  final String stadiumId;

  const StadiumBookingPage({
    super.key,
    required this.stadiumId,
  });

  @override
  State<StadiumBookingPage> createState() => _StadiumBookingPageState();
}

class _StadiumBookingPageState extends State<StadiumBookingPage> {
  final StadiumService _stadiumService = StadiumService();
  final BookingService _bookingService = BookingService();

  Map<String, dynamic>? stadiumData;
  bool isLoading = true;
  bool isBooking = false;
  DateTime selectedDate = DateTime.now();
  String? selectedTimeSlot;
  List<Map<String, dynamic>> availableSlots = [];

  @override
  void initState() {
    super.initState();
    _loadStadiumData();
  }

  Future<void> _loadStadiumData() async {
    setState(() {
      isLoading = true;
    });

    final result = await _stadiumService.getStadiumById(widget.stadiumId);
    if (result['success']) {
      setState(() {
        stadiumData = result['data'];
        isLoading = false;
      });
      _loadAvailableSlots();
    } else {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to load stadium'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _loadAvailableSlots() {
    if (stadiumData == null) return;

    // Find calendar entry for selected date
    final dateOnly = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final calendar = stadiumData!['calendar'] as List<dynamic>? ?? [];
    
    final calendarEntry = calendar.firstWhere(
      (entry) {
        final entryDate = DateTime.parse(entry['date']);
        final entryDateOnly = DateTime(entryDate.year, entryDate.month, entryDate.day);
        return entryDateOnly.isAtSameMomentAs(dateOnly);
      },
      orElse: () => null,
    );

    if (calendarEntry != null) {
      final slots = calendarEntry['slots'] as List<dynamic>? ?? [];
      setState(() {
        availableSlots = slots.map((slot) => Map<String, dynamic>.from(slot)).toList();
        selectedTimeSlot = null; // Reset selection when date changes
      });
    } else {
      setState(() {
        availableSlots = [];
        selectedTimeSlot = null;
      });
    }
  }

  Future<void> _bookSlot() async {
    if (selectedTimeSlot == null || stadiumData == null) return;

    // Show confirmation dialog
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) => BookingConfirmationDialog(
        stadiumName: stadiumData!['name'],
        location: stadiumData!['location'],
        matchDate: selectedDate.toIso8601String().split('T')[0],
        timeSlot: selectedTimeSlot!,
        pricePerMatch: (stadiumData!['pricePerMatch'] as num).toDouble(),
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );

    if (shouldProceed != true) return;

    setState(() {
      isBooking = true;
    });

    final result = await _bookingService.bookMatch(
      stadiumId: widget.stadiumId,
      matchDate: selectedDate.toIso8601String().split('T')[0],
      timeSlot: selectedTimeSlot!,
    );

    setState(() {
      isBooking = false;
    });

    if (result['success']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking successful!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Booking failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(stadiumData?['name'] ?? 'Stadium Booking'),
        backgroundColor: isDarkMode ? colorScheme.surface : Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : stadiumData == null
              ? const Center(child: Text('Stadium not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStadiumInfo(),
                      const SizedBox(height: 24),
                      _buildDateSelector(),
                      const SizedBox(height: 24),
                      _buildTimeSlots(),
                      const SizedBox(height: 24),
                      _buildBookingButton(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStadiumInfo() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stadiumData!['name'],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                stadiumData!['location'],
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.attach_money,
                size: 16,
                color: colorScheme.primary,
              ),
              Text(
                '\$${(stadiumData!['pricePerMatch'] as num).toStringAsFixed(2)} per match',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Date',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 14, // Show next 14 days
            itemBuilder: (context, index) {
              final date = DateTime.now().add(Duration(days: index));
              final isSelected = date.day == selectedDate.day &&
                  date.month == selectedDate.month &&
                  date.year == selectedDate.year;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedDate = date;
                  });
                  _loadAvailableSlots();
                },
                child: Container(
                  width: 60,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? colorScheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? colorScheme.primary : colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getDayName(date),
                        style: TextStyle(
                          color: isSelected ? Colors.white : null,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date.day.toString(),
                        style: TextStyle(
                          color: isSelected ? Colors.white : null,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlots() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Time Slots',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        availableSlots.isEmpty
            ? Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('No available slots for this date'),
                ),
              )
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availableSlots.map((slot) {
                  final startTime = slot['startTime'];
                  final endTime = slot['endTime'];
                  final isBooked = slot['isBooked'] ?? false;
                  final isSelected = selectedTimeSlot == startTime;

                  return GestureDetector(
                    onTap: isBooked
                        ? null
                        : () {
                            setState(() {
                              selectedTimeSlot = startTime;
                            });
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isBooked
                            ? Colors.grey.withOpacity(0.3)
                            : isSelected
                                ? colorScheme.primary
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isBooked
                              ? Colors.grey
                              : isSelected
                                  ? colorScheme.primary
                                  : colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '$startTime - $endTime',
                        style: TextStyle(
                          color: isBooked
                              ? Colors.grey
                              : isSelected
                                  ? Colors.white
                                  : null,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
      ],
    );
  }

  Widget _buildBookingButton() {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: selectedTimeSlot == null || isBooking ? null : _bookSlot,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isBooking
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                selectedTimeSlot == null
                    ? 'Select a time slot'
                    : 'Book for \$${(stadiumData!['pricePerMatch'] as num).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  String _getDayName(DateTime date) {
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[date.weekday % 7];
  }
}