import 'package:flutter/material.dart';
import '../models/academy.dart';
import '../services/academy_service.dart';
import '../services/app_config.dart';
import 'academy_form_screen.dart';

/// Screen that displays available sports academies
class AcademiesScreen extends StatefulWidget {
  final String? searchQuery;
  
  const AcademiesScreen({super.key, this.searchQuery});

  @override
  State<AcademiesScreen> createState() => _AcademiesScreenState();
}

class _AcademiesScreenState extends State<AcademiesScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Academy> _allAcademies = [];
  List<Academy> _filteredAcademies = [];
  final AcademyService _academyService = AcademyService();
  bool _canCreateAcademies = false;

  @override
  void initState() {
    super.initState();
    _loadAcademies();
    _checkCreatePermission();
  }

  Future<void> _checkCreatePermission() async {
    final canCreate = await _academyService.canCreateAcademies();
    setState(() {
      _canCreateAcademies = canCreate;
    });
  }
  
  @override
  void didUpdateWidget(AcademiesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery) {
      _applySearchFilter();
    }
  }

  // Load academies from the backend
  Future<void> _loadAcademies() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final academies = await _academyService.getAcademies();

      setState(() {
        _allAcademies = academies;
        _applySearchFilter(); // Apply search filter
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading academies: $e');

      // Try to load mock data if API fails
      try {
        final mockAcademies = await _academyService.getMockAcademies();

        setState(() {
          _allAcademies = mockAcademies;
          _applySearchFilter();
          _isLoading = false;
          _errorMessage = 'Using demo data (could not connect to server)';
        });
      } catch (mockError) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load academies: ${e.toString()}';
        });
      }
    }
  }

  // Apply search filter to the academy list
  void _applySearchFilter() {
    if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      final query = widget.searchQuery!.toLowerCase();
      _filteredAcademies = _allAcademies.where((academy) {
        return academy.name.toLowerCase().contains(query) ||
               academy.description.toLowerCase().contains(query) ||
               academy.location.toLowerCase().contains(query) ||
               academy.sports.any((sport) => sport.toLowerCase().contains(query));
      }).toList();
    } else {
      _filteredAcademies = List.from(_allAcademies);
    }
  }

  Future<void> _navigateToCreateAcademy() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AcademyFormScreen(),
      ),
    );
    
    if (result == true) {
      _loadAcademies(); // Reload academies after creating
    }
  }

  Future<void> _navigateToEditAcademy(Academy academy) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AcademyFormScreen(academy: academy),
      ),
    );
    
    if (result == true) {
      _loadAcademies(); // Reload academies after editing
    }
  }

  Future<void> _deleteAcademy(Academy academy) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Academy'),
        content: Text('Are you sure you want to delete "${academy.name}"?'),
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
        await _academyService.deleteAcademy(academy.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Academy deleted successfully')),
        );
        _loadAcademies(); // Reload academies after deletion
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting academy: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadAcademies,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_errorMessage != null) _buildErrorBanner(),
            _buildAcademiesList(),
          ],
        ),
      ),
      floatingActionButton: _canCreateAcademies
          ? FloatingActionButton(
              onPressed: _navigateToCreateAcademy,
              heroTag: "academies_main_fab",
              child: const Icon(Icons.add),
            )
          : null,
    );
  }


  /// Builds error banner
  Widget _buildErrorBanner() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
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
    );
  }

  /// Builds the list of academies
  Widget _buildAcademiesList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_filteredAcademies.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Column(
            children: [
              Icon(
                Icons.school_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No academies found',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Text(
                'Try selecting a different category',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Academies (${_filteredAcademies.length})',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _filteredAcademies.length,
          itemBuilder: (context, index) {
            final academy = _filteredAcademies[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _buildAcademyCard(academy),
            );
          },
        ),
      ],
    );
  }

  /// Builds an individual academy card
  Widget _buildAcademyCard(Academy academy) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Academy image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                // Academy image
                academy.photos.isNotEmpty
                    ? Image.network(
                      _getImageUrl(academy.photos.first),
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) =>
                              _buildPlaceholderImage(),
                    )
                    : _buildPlaceholderImage(),

                // Rating badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          academy.rating.toStringAsFixed(1),
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

                // Edit/Delete menu (only show if user can edit this specific academy)
                FutureBuilder<bool>(
                  future: _academyService.canEditAcademy(academy),
                  builder: (context, snapshot) {
                    if (snapshot.data == true) {
                      return Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: Colors.white),
                            onSelected: (value) {
                              if (value == 'edit') {
                                _navigateToEditAcademy(academy);
                              } else if (value == 'delete') {
                                _deleteAcademy(academy);
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

          // Academy details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Academy name
                Text(
                  academy.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // Description
                Text(
                  academy.description,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // Location and age group
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        academy.location,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.people_outline,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      academy.ageGroup,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Sports offered
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children:
                      academy.sports.take(3).map((sport) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            sport,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                ),

                if (academy.sports.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      '+${academy.sports.length - 3} more',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showContactInfo(academy),
                        child: const Text('Contact'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showAcademyDetails(academy),
                        child: const Text('View Details'),
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

  /// Build placeholder image for academies without photos
  Widget _buildPlaceholderImage() {
    return Container(
      height: 160,
      width: double.infinity,
      color: Colors.grey.shade300,
      child: Center(
        child: Icon(Icons.school, size: 64, color: Colors.grey.shade600),
      ),
    );
  }

  /// Show contact information dialog
  void _showContactInfo(Academy academy) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Contact ${academy.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (academy.contact['phone']?.isNotEmpty == true)
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 16),
                      const SizedBox(width: 8),
                      Text(academy.contact['phone']),
                    ],
                  ),
                if (academy.contact['email']?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.email, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(academy.contact['email'])),
                    ],
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  /// Show academy details
  void _showAcademyDetails(Academy academy) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            expand: false,
            builder:
                (context, scrollController) => Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Academy name and rating
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              academy.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                academy.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Description
                      Text(
                        academy.description,
                        style: const TextStyle(fontSize: 16),
                      ),

                      const SizedBox(height: 20),

                      // Details
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: [
                            _buildDetailRow('Location', academy.location),
                            _buildDetailRow('Age Group', academy.ageGroup),
                            _buildDetailRow(
                              'Sports Offered',
                              academy.sports.join(', '),
                            ),
                            if (academy.contact['phone']?.isNotEmpty == true)
                              _buildDetailRow(
                                'Phone',
                                academy.contact['phone'],
                              ),
                            if (academy.contact['email']?.isNotEmpty == true)
                              _buildDetailRow(
                                'Email',
                                academy.contact['email'],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
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
    
    // If it's just a filename, assume it's in the academy images directory
    return '${AppConfig.baseUrl}/images/academiesImages/$photoPath';
  }
}
