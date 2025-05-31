import 'package:flutter/material.dart';

class TournamentsScreen extends StatefulWidget {
  const TournamentsScreen({super.key});

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = [
    'All',
    'Upcoming',
    'Ongoing',
    'Past',
    'My Tournaments',
  ];
  final List<Map<String, dynamic>> _tournaments = [
    {
      'title': 'Summer Football Championship',
      'dates': 'May 25 - June 10, 2025',
      'venue': 'City Sports Arena',
      'status': '32 teams registered',
      'color': Colors.green,
      'sport': 'Football',
      'image': 'https://images.unsplash.com/photo-1575361204480-aadea25e6e68',
      'entry_fee': '\$100 per team',
      'prize': '\$2,000',
      'isFeatured': true,
    },
    {
      'title': 'Basketball All-Stars',
      'dates': 'June 15-20, 2025',
      'venue': 'Central Basketball Court',
      'status': '16 teams registered',
      'color': Colors.orange,
      'sport': 'Basketball',
      'image': 'https://images.unsplash.com/photo-1546519638-68e109498ffc',
      'entry_fee': '\$80 per team',
      'prize': '\$1,500',
      'isFeatured': false,
    },
    {
      'title': 'Tennis Open Tournament',
      'dates': 'July 1-7, 2025',
      'venue': 'Green Park Tennis Courts',
      'status': 'Registration open until June 20',
      'color': Colors.blue,
      'sport': 'Tennis',
      'image': 'https://images.unsplash.com/photo-1595435934249-5df7ed86e1c0',
      'entry_fee': '\$50 per player',
      'prize': '\$1,000',
      'isFeatured': true,
    },
    {
      'title': 'City Swimming Championship',
      'dates': 'August 10-12, 2025',
      'venue': 'Olympic Swimming Pool',
      'status': 'Registration opens June 1',
      'color': Colors.cyan,
      'sport': 'Swimming',
      'image': 'https://images.unsplash.com/photo-1576013551627-0ae7d1d6f79e',
      'entry_fee': '\$40 per player',
      'prize': '\$800',
      'isFeatured': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Featured Tournament Banner (first upcoming tournament)
        if (_tournaments.any((t) => t['isFeatured'] == true))
          _buildFeaturedTournament(
            _tournaments.firstWhere((t) => t['isFeatured'] == true),
            context,
          ),

        const SizedBox(height: 20),

        // Filter Chips
        _buildFilterChipsRow(),

        const SizedBox(height: 20),

        // Tournament Cards
        ..._tournaments.map(
          (tournament) => Column(
            children: [
              _buildTournamentCard(
                tournament['title'],
                tournament['dates'],
                tournament['venue'],
                tournament['status'],
                tournament['color'],
                tournament['sport'],
                tournament['image'],
                tournament['entry_fee'],
                tournament['prize'],
                context,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds a featured tournament banner
  Widget _buildFeaturedTournament(
    Map<String, dynamic> tournament,
    BuildContext context,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 180,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: NetworkImage(tournament['image']),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withAlpha(128), // 0.5 opacity
            BlendMode.darken,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: tournament['color'].withAlpha(102), // 0.4 opacity
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Featured tag
          Positioned(
            top: 16,
            left: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                // Use colorScheme for a subtle border
                border: Border.all(
                  color: colorScheme.primary.withAlpha(51), // 0.2 opacity
                  width: 0.5,
                ),
                color: tournament['color'],
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(20),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.star, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'FEATURED',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Sport type tag
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(153), // 0.6 opacity
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tournament['sport'],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Add this to prevent overflow
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  // Wrap in Flexible to allow text to shrink if needed
                  child: Text(
                    tournament['title'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Colors.white.withAlpha(230), // 0.9 opacity
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tournament['dates'],
                      style: TextStyle(
                        color: Colors.white.withAlpha(230), // 0.9 opacity
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Colors.white.withAlpha(230), // 0.9 opacity
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tournament['venue'],
                      style: TextStyle(
                        color: Colors.white.withAlpha(230), // 0.9 opacity
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8), // Reduced from 12 to 8
                SizedBox(
                  // Constrain the button height
                  height: 36,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: colorScheme.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0, // Reduced padding
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Register Now',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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

  /// Builds the filter chips row
  Widget _buildFilterChipsRow() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color:
            isDarkMode
                ? Colors.grey.shade800.withAlpha(128)
                : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
          width: 1,
        ),
      ),
      // Reduced padding to prevent overflow
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      // Use SingleChildScrollView with Row instead of ListView for better performance
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children:
              _filters.map((label) {
                final selected = label == _selectedFilter;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFilter = label;
                    });
                  },
                  child: _buildFilterChip(label, selected),
                );
              }).toList(),
        ),
      ),
    );
  }

  /// Builds an individual filter chip for tournament categories
  Widget _buildFilterChip(String label, bool selected) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color:
                selected
                    ? Colors.transparent
                    : isDarkMode
                    ? Colors.grey.shade600
                    : Colors.grey.shade400,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
                selected
                    ? Colors.white
                    : isDarkMode
                    ? Colors.white
                    : Colors.black87,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  /// Builds an individual card for a tournament
  Widget _buildTournamentCard(
    String title,
    String dates,
    String venue,
    String status,
    Color color,
    String sport,
    String imageUrl,
    String entryFee,
    String prize,
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
            color: Colors.black.withAlpha(13), // 0.05 opacity
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Image.network(
                  imageUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withAlpha(179)], // 0.7 opacity
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(153), // 0.6 opacity
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    sport,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Content section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                // Info rows
                _buildInfoRow(Icons.calendar_today, dates, context),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.location_on, venue, context),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.people, status, context),

                const SizedBox(height: 12),

                // Entry fee and prize
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isDarkMode
                                  ? Colors.grey.shade700.withOpacity(0.3)
                                  : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Entry Fee',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    isDarkMode
                                        ? Colors.grey.shade300
                                        : Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              entryFee,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isDarkMode
                                  ? colorScheme.primary.withOpacity(0.15)
                                  : colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Prize',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    isDarkMode
                                        ? colorScheme.primary.withOpacity(0.8)
                                        : colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              prize,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color:
                                isDarkMode
                                    ? Colors.grey.shade600
                                    : Colors.grey.shade400,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ), // Reduced from 12
                          minimumSize: const Size(0, 36), // Set minimum size
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color:
                                  isDarkMode
                                      ? Colors.grey.shade300
                                      : Colors.grey.shade800,
                            ),
                            const SizedBox(width: 4), // Reduced from 8
                            Text(
                              'Details',
                              style: TextStyle(
                                color:
                                    isDarkMode
                                        ? Colors.grey.shade300
                                        : Colors.grey.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8), // Reduced from 12
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ), // Reduced from 12
                          minimumSize: const Size(0, 36), // Set minimum size
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.app_registration, size: 16),
                            SizedBox(width: 4), // Reduced from 8
                            Text(
                              'Register',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
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

  /// Builds an information row with icon and text
  Widget _buildInfoRow(IconData icon, String text, BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
