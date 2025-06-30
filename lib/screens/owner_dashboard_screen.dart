import 'package:flutter/material.dart';
import '../auth_service.dart';
import '../services/stadium_service.dart';
import '../services/academy_service.dart';
import '../services/tournament_service.dart';
import '../models/academy.dart';
import '../services/app_config.dart';
import 'my_stadiums_screen.dart';
import 'my_academies_screen.dart';
import 'my_tournaments_screen.dart';
import 'stadium_form_screen.dart';
import 'academy_form_screen.dart';
import 'create_tournament_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final StadiumService _stadiumService = StadiumService();
  final AcademyService _academyService = AcademyService();
  final TournamentService _tournamentService = TournamentService();

  TabController? _tabController;
  String _userRole = '';
  int _stadiumCount = 0;
  int _academyCount = 0;
  int _tournamentCount = 0;
  bool _isLoading = true;

  // Academy management
  List<Academy> _academies = [];
  bool _isLoadingAcademies = false;

  @override
  void initState() {
    super.initState();
    // Initialize with just one tab initially
    _tabController = TabController(length: 1, vsync: this);
    _loadData();
  }

  void _initializeTabs() {
    if (mounted) {
      _tabController?.dispose();
      // Only dashboard tab now
      _tabController = TabController(length: 1, vsync: this);
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }
  

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final userRole = await _authService.getUserRole();
      if (mounted) {
        setState(() {
          _userRole = userRole ?? '';
        });

        // Reinitialize tabs now that we have the user role
        _initializeTabs();
      }

      // Load academies for academy owners
      if (_userRole == 'academyOwner' || _userRole == 'admin') {
        _loadMyAcademies();
      }

      // Load counts based on user role
      if (_userRole == 'stadiumOwner' || _userRole == 'admin') {
        final stadiums = await _stadiumService.getMyStadiums();
        if (mounted) {
          setState(() {
            _stadiumCount = stadiums.length;
          });
        }
      }

      if (_userRole == 'academyOwner' || _userRole == 'admin') {
        final academies = await _academyService.getMyAcademies();
        if (mounted) {
          setState(() {
            _academyCount = academies.length;
          });
        }
      }

      // Load tournament count for stadium owners
      if (_userRole == 'stadiumOwner' || _userRole == 'admin') {
        try {
          final tournaments = await _tournamentService.getMyTournaments();
          if (mounted) {
            setState(() {
              _tournamentCount = tournaments.length;
            });
          }
        } catch (e) {
          print('Error loading tournaments: $e');
          if (mounted) {
            setState(() {
              _tournamentCount = 0;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }





  Future<void> _loadMyAcademies() async {
    if (_userRole != 'academyOwner' && _userRole != 'admin') return;

    if (mounted) {
      setState(() {
        _isLoadingAcademies = true;
      });
    }

    try {
      final academies = await _academyService.getMyAcademies();
      if (mounted) {
        setState(() {
          _academies = academies;
          _isLoadingAcademies = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAcademies = false;
        });
      }
      print('Error loading academies: $e');
    }
  }

  Future<void> _navigateToCreateAcademy() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AcademyFormScreen()),
    );

    if (result == true) {
      _loadData();
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
        content: Text(
          'Are you sure you want to delete "${academy.name}"? This action cannot be undone.',
        ),
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
        _loadData(); // Refresh dashboard stats
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Management Dashboard'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildDashboardTab(),
    );
  }

  Widget _buildDashboardTab() {
    final colorScheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Welcome section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _userRole == 'stadiumOwner'
                          ? Icons.stadium
                          : Icons.school,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome ${_userRole == 'stadiumOwner'
                                ? 'Stadium'
                                : _userRole == 'academyOwner'
                                ? 'Academy'
                                : _userRole == 'admin'
                                ? 'Admin'
                                : ''} Owner!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Manage your facilities and services',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Stats cards
          // Build stats cards based on user role
          if (_userRole.isNotEmpty) ...[
            Row(
              children: [
                if (_userRole == 'stadiumOwner' || _userRole == 'admin')
                  Expanded(
                    child: _buildStatCard(
                      'Stadiums',
                      _stadiumCount.toString(),
                      Icons.stadium,
                      Colors.blue,
                    ),
                  ),
                if ((_userRole == 'stadiumOwner' || _userRole == 'admin') &&
                    (_userRole == 'academyOwner'))
                  const SizedBox(width: 12),
                if (_userRole == 'academyOwner' || _userRole == 'admin')
                  Expanded(
                    child: _buildStatCard(
                      'Academies',
                      _academyCount.toString(),
                      Icons.school,
                      Colors.green,
                    ),
                  ),
              ],
            ),
          ] else ...[
            // Loading placeholder for stats
            Container(
              padding: const EdgeInsets.all(16),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ],

          const SizedBox(height: 16),

          if (_userRole == 'stadiumOwner' || _userRole == 'admin')
            _buildStatCard(
              'Tournaments',
              _tournamentCount.toString(),
              Icons.emoji_events,
              Colors.orange,
            ),

          const SizedBox(height: 24),

          // Quick Actions
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Create buttons based on user role
          if (_userRole.isNotEmpty) ...[
            Row(
              children: [
                if (_userRole == 'stadiumOwner' || _userRole == 'admin')
                  Expanded(
                    child: _buildQuickActionCard(
                      'Create Stadium',
                      Icons.add_business,
                      Colors.blue,
                      () => _navigateToCreateStadium(),
                    ),
                  ),
                if ((_userRole == 'stadiumOwner' || _userRole == 'admin') &&
                    (_userRole == 'academyOwner'))
                  const SizedBox(width: 12),
                if (_userRole == 'academyOwner' || _userRole == 'admin')
                  Expanded(
                    child: _buildQuickActionCard(
                      'Create Academy',
                      Icons.add,
                      Colors.green,
                      () => _navigateToCreateAcademy(),
                    ),
                  ),
              ],
            ),
          ] else ...[
            // Loading placeholder for quick actions
            Container(
              padding: const EdgeInsets.all(16),
              child: const Center(
                child: Text('Loading actions...'),
              ),
            ),
          ],

          if (_userRole == 'stadiumOwner' || _userRole == 'admin') ...[
            const SizedBox(height: 12),
            _buildQuickActionCard(
              'Create Tournament',
              Icons.emoji_events,
              Colors.orange,
              () => _navigateToCreateTournament(),
            ),
          ],

          const SizedBox(height: 24),

          // Management actions
          const Text(
            'Management',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Stadium management
          if (_userRole == 'stadiumOwner' || _userRole == 'admin')
            _buildManagementCard(
              'My Stadiums',
              'View, edit, and delete your stadiums',
              Icons.stadium,
              Colors.blue,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyStadiumsScreen(),
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Academy management
          if (_userRole == 'academyOwner' || _userRole == 'admin')
            _buildManagementCard(
              'My Academies',
              'View, edit, and delete your academies',
              Icons.school,
              Colors.green,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyAcademiesScreen(),
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Tournament management
          if (_userRole == 'stadiumOwner' || _userRole == 'admin')
            _buildManagementCard(
              'My Tournaments',
              'View, edit, and delete your tournaments',
              Icons.emoji_events,
              Colors.orange,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyTournamentsScreen(),
                ),
              ),
            ),
        ],
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
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildPlaceholderImage(),
                                )
                              : _buildPlaceholderImage();
                        },
                      )
                    : _buildPlaceholderImage(),

                // Action buttons overlay
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
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
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
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
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
                    children:
                        academy.sports.take(3).map((sport) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              sport,
                              style: TextStyle(
                                color: Colors.green.shade700,
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

  Future<void> _navigateToCreateStadium() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StadiumFormScreen()),
    );

    if (result == true) {
      _loadData(); // Refresh data
    }
  }

  Future<void> _navigateToCreateTournament() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateTournamentScreen()),
    );

    if (result == true) {
      _loadData(); // Refresh data
    }
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String count,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
