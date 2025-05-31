import 'package:flutter/material.dart';

/// Screen that displays available sports academies
class AcademiesScreen extends StatelessWidget {
  const AcademiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCategoryFilters(),
        const SizedBox(height: 20),
        _buildAcademyListItem(
          'Elite Football Academy',
          'Football training for all ages and skill levels',
          4.8,
          'https://images.unsplash.com/photo-1434648957308-5e6a859697e8',
          context,
        ),
        const SizedBox(height: 16),
        _buildAcademyListItem(
          'Tennis Pro Academy',
          'Professional tennis coaching with top trainers',
          4.5,
          'https://images.unsplash.com/photo-1595435934249-5df7ed86e1c0',
          context,
        ),
        const SizedBox(height: 16),
        _buildAcademyListItem(
          'Swim Masters',
          'Swimming lessons from beginner to advanced',
          4.7,
          'https://images.unsplash.com/photo-1576013551627-0ae7d1d6f79e',
          context,
        ),
      ],
    );
  }

  /// Builds the horizontal list of category filter chips
  Widget _buildCategoryFilters() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('All', true),
          _buildFilterChip('Football', false),
          _buildFilterChip('Basketball', false),
          _buildFilterChip('Tennis', false),
          _buildFilterChip('Swimming', false),
          _buildFilterChip('Martial Arts', false),
        ],
      ),
    );
  }

  /// Builds an individual filter chip for categories
  Widget _buildFilterChip(String label, bool selected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: selected,
        label: Text(label),
        onSelected: (bool value) {},
        backgroundColor: Colors.grey.shade200,
        selectedColor: Colors.blue.withAlpha(51), // 0.2 opacity
        checkmarkColor: Colors.blue,
        labelStyle: TextStyle(
          color: selected ? Colors.blue : Colors.black87,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  /// Builds an individual list item for an academy
  Widget _buildAcademyListItem(
    String name,
    String description,
    double rating,
    String imageUrl,
    BuildContext context,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              imageUrl,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '$rating',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('View Details'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
