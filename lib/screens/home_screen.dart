import 'package:flutter/material.dart';

/// Home screen that displays featured facilities, upcoming events, and popular academies
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // ignore: unused_local_variable
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 8),

        // Featured Banner
        _buildFeatureBanner(context),
        const SizedBox(height: 24),

        _buildSectionTitle('Featured Facilities', context),
        const SizedBox(height: 12),
        _buildFeaturedFacilities(context),
        const SizedBox(height: 24),

        _buildSectionTitle('Upcoming Events', context),
        const SizedBox(height: 12),
        _buildUpcomingEvents(context),
        const SizedBox(height: 24),

        _buildSectionTitle('Popular Academies', context),
        const SizedBox(height: 12),
        _buildPopularAcademies(context),
      ],
    );
  }

  /// Builds a promotional banner at the top of the home screen
  Widget _buildFeatureBanner(BuildContext context) {
    // ignore: unused_local_variable
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 160,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withAlpha(179),
          ], // 0.7 opacity
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26), // 0.1 opacity
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -50,
            top: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(26), // 0.1 opacity
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(26), // 0.1 opacity
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.center, // Align items in the center
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize:
                        MainAxisSize.min, // Add this to prevent overflow
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Summer Special Offer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4), // Reduce spacing
                      Text(
                        'Get 20% off on all facility bookings this month',
                        style: TextStyle(
                          color: Colors.white.withAlpha(230), // 0.9 opacity
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1, // Reduce to 1 line
                      ),
                      const SizedBox(height: 8), // Reduce spacing
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: colorScheme.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16, // Reduce padding
                            vertical: 8, // Reduce padding
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Book Now',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10), // Reduce width
                Icon(
                  Icons.sports_soccer,
                  size: 50, // Reduce size
                  color: Colors.white.withAlpha(204), // 0.8 opacity
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a section header with title and "See all" button
  Widget _buildSectionTitle(String title, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
          ),
        ),
        TextButton(
          onPressed: () {},
          child: Text(
            'See all',
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the horizontal list of featured sports facilities
  Widget _buildFeaturedFacilities(BuildContext context) {
    return SizedBox(
      height: 210, // Increase height slightly to accommodate content
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFacilityCard(
            'City Sports Arena',
            'Football, Basketball',
            4.8,
            'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e', // Updated URL
            context,
          ),
          _buildFacilityCard(
            'Olympic Swimming Pool',
            'Swimming',
            4.5,
            'https://images.unsplash.com/photo-1575429198097-0414ec08e8cd', // Updated URL
            context,
          ),
          _buildFacilityCard(
            'Green Park Tennis',
            'Tennis, Padel',
            4.7,
            'https://images.unsplash.com/photo-1595435934249-5df7ed86e1c0', // This URL is fine
            context,
          ),
        ],
      ),
    );
  }

  /// Builds an individual card for a sports facility
  Widget _buildFacilityCard(
    String name,
    String sports,
    double rating,
    String imageUrl,
    BuildContext context,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withAlpha(13),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26), // 0.1 opacity
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
              // Image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Image.network(
                  imageUrl,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  // Add error handling
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 140,
                      width: double.infinity,
                      color:
                          isDarkMode
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                      child: Center(
                        child: Icon(
                          Icons.broken_image_rounded,
                          size: 40,
                          color:
                              isDarkMode
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade500,
                        ),
                      ),
                    );
                  },
                  // Add loading placeholder
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 140,
                      width: double.infinity,
                      color:
                          isDarkMode
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                      child: Center(
                        child: CircularProgressIndicator(
                          value:
                              loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                          color: colorScheme.primary,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Rating badge
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(153), // 0.6 opacity
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize:
                        MainAxisSize.min, // Important to avoid overflow
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '$rating',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Facility info section
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ), // Reduce vertical padding
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade800 : Colors.white,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Add this to prevent overflow
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14, // Slightly smaller font
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4), // Reduce spacing
                Row(
                  children: [
                    Icon(
                      Icons.sports_score,
                      size: 12, // Slightly smaller icon
                      color:
                          isDarkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade700,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        sports,
                        style: TextStyle(
                          fontSize: 11, // Slightly smaller font
                          color:
                              isDarkMode
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade700,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
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

  /// Builds the list of upcoming sports events
  Widget _buildUpcomingEvents(BuildContext context) {
    return Column(
      children: [
        _buildEventCard(
          'City Football Tournament',
          'May 25-30, 2025',
          'City Sports Arena',
          Icons.emoji_events,
          context,
        ),
        const SizedBox(height: 12),
        _buildEventCard(
          'Swim Championship',
          'June 5-8, 2025',
          'Olympic Swimming Pool',
          Icons.pool,
          context,
        ),
      ],
    );
  }

  /// Builds an individual card for a sports event
  Widget _buildEventCard(
    String title,
    String date,
    String location,
    IconData icon,
    BuildContext context,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withAlpha(26), // 0.1 opacity
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: colorScheme.primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  // Add overflow handling
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color:
                          isDarkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    // Add Expanded to prevent overflow
                    Expanded(
                      child: Text(
                        date,
                        style: TextStyle(
                          color:
                              isDarkMode
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color:
                          isDarkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    // Add Expanded to prevent overflow
                    Expanded(
                      child: Text(
                        location,
                        style: TextStyle(
                          color:
                              isDarkMode
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Use smaller padding for the button
          Container(
            decoration: BoxDecoration(
              color: colorScheme.primary.withAlpha(26), // 0.1 opacity
              borderRadius: BorderRadius.circular(30),
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: colorScheme.primary,
              ),
              onPressed: () {},
              // Reduce padding to save space
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the horizontal list of popular academies
  Widget _buildPopularAcademies(BuildContext context) {
    return SizedBox(
      // Increase height slightly to accommodate all content
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildAcademyCard(
            'Elite Football Academy',
            'Football',
            Colors.green,
            context,
          ),
          _buildAcademyCard(
            'Tennis Pro Academy',
            'Tennis',
            Colors.orange,
            context,
          ),
          _buildAcademyCard('Swim Masters', 'Swimming', Colors.blue, context),
          _buildAcademyCard(
            'Basketball Stars',
            'Basketball',
            Colors.red,
            context,
          ),
        ],
      ),
    );
  }

  /// Builds an individual card for a sports academy
  Widget _buildAcademyCard(
    String name,
    String sport,
    Color color,
    BuildContext context,
  ) {
    // ignore: unused_local_variable
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withAlpha(179),
            color.withAlpha(230),
          ], // 0.7 and 0.9 opacity
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(77), // 0.3 opacity
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // Add this to fit content
        children: [
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            // Add overflow handling
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(77), // 0.3 opacity
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              sport,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
