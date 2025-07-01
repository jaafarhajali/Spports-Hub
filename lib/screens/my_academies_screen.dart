import 'package:flutter/material.dart';
import '../models/academy.dart';
import '../services/academy_service.dart';
import '../services/app_config.dart';
import '../auth_service.dart';
import 'academy_form_screen.dart';

class MyAcademiesScreen extends StatefulWidget {
  const MyAcademiesScreen({super.key});

  @override
  State<MyAcademiesScreen> createState() => _MyAcademiesScreenState();
}

class _MyAcademiesScreenState extends State<MyAcademiesScreen> {
  final AcademyService _academyService = AcademyService();
  final AuthService _authService = AuthService();
  List<Academy> _academies = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isAdmin = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _checkAdminStatusAndLoadAcademies();
  }

  Future<void> _checkAdminStatusAndLoadAcademies() async {
    try {
      final userRole = await _authService.getUserRole();
      final userId = await _authService.getUserId();
      setState(() {
        _isAdmin = userRole == 'admin';
        _currentUserId = userId;
      });
      _loadMyAcademies();
    } catch (e) {
      print('Error checking admin status: $e');
      _loadMyAcademies();
    }
  }

  Future<void> _loadMyAcademies() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<Academy> academies;
      if (_isAdmin) {
        // Admin can see all academies in the system
        academies = await _academyService.getAllAcademiesAdmin();
      } else {
        // Regular users see only their own academies
        academies = await _academyService.getMyAcademies();
      }
      
      setState(() {
        _academies = academies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load academies: ${e.toString()}';
      });
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
      _loadMyAcademies();
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
      _loadMyAcademies();
    }
  }

  Future<void> _deleteAcademy(Academy academy) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Academy'),
        content: Text('Are you sure you want to delete "${academy.name}"? This action cannot be undone.'),
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
        _loadMyAcademies();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting academy: ${e.toString()}')),
        );
      }
    }
  }

  bool _canEditAcademy(Academy academy) {
    // Admin can edit any academy
    if (_isAdmin) return true;
    
    // Academy owners can edit their own academies
    // Since we're using getMyAcademies() for academy owners, 
    // all academies shown should be editable by them
    if (!_isAdmin) {
      return true; // Academy owners can edit all academies shown in their "My Academies" view
    }
    
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isAdmin ? 'All Academies (Admin)' : 'My Academies'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: _navigateToCreateAcademy,
            icon: const Icon(Icons.add),
            tooltip: 'Add Academy',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMyAcademies,
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
                          onPressed: _loadMyAcademies,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _academies.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.school_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _isAdmin ? 'No academies in system' : 'No academies yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isAdmin ? 'No academies have been created yet' : 'Create your first academy to get started',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _navigateToCreateAcademy,
                              icon: const Icon(Icons.add),
                              label: const Text('Create Academy'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _academies.length,
                        itemBuilder: (context, index) {
                          final academy = _academies[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildAcademyCard(academy),
                          );
                        },
                      ),
      ),
    );
  }

  Widget _buildAcademyCard(Academy academy) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Academy image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                academy.photos.isNotEmpty && academy.photos.first.isNotEmpty
                    ? Builder(
                        builder: (context) {
                          final imageUrl = _getImageUrl(academy.photos.first);
                          return imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  height: 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                                )
                              : _buildPlaceholderImage();
                        },
                      )
                    : _buildPlaceholderImage(),

                // Action buttons overlay - only show for admin or academy owner
                if (_canEditAcademy(academy))
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
                            onPressed: () => _navigateToEditAcademy(academy),
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
                            onPressed: () => _deleteAcademy(academy),
                            icon: const Icon(Icons.delete, color: Colors.white),
                            iconSize: 20,
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Rating badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

                // Contact info
                Row(
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      academy.contact['phone'] ?? '',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.email_outlined,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        academy.contact['email'] ?? '',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Sports offered
                if (academy.sports.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: academy.sports.take(3).map((sport) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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

                // Action buttons - only show for admin or academy owner
                if (_canEditAcademy(academy))
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _navigateToEditAcademy(academy),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Edit'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _deleteAcademy(academy),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

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
    
    return '${AppConfig.baseUrl}/images/academiesImages/$photoPath';
  }
}