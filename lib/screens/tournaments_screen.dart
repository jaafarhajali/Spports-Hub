import 'package:flutter/material.dart';
import '../models/tournament.dart';
import '../services/tournament_service.dart';
import '../services/team_service.dart';
import '../models/team.dart';

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
  
  List<Tournament> _tournaments = [];
  bool _isLoading = true;
  String? _error;
  Team? _userTeam;
  
  final TournamentService _tournamentService = TournamentService();
  final TeamService _teamService = TeamService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final tournaments = await _tournamentService.getAllTournaments();
      Team? userTeam;
      
      try {
        userTeam = await _teamService.getMyTeam();
      } catch (e) {
        print('Could not load user team: $e');
        userTeam = null;
      }

      setState(() {
        _tournaments = tournaments ?? [];
        _userTeam = userTeam;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _joinTournament(Tournament tournament) async {
    if (_userTeam == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need to create or join a team first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final teamId = _userTeam?.id;
      if (teamId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Team information not available'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      final result = await _tournamentService.joinTournament(tournament.id, teamId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Tournament join request processed'),
            backgroundColor: result['success'] ? Colors.green : Colors.red,
          ),
        );
        if (result['success']) {
          _loadData(); // Reload tournaments on success
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join tournament: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Tournament> get _filteredTournaments {
    return _tournamentService.filterTournaments(_tournaments, _selectedFilter);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading tournaments',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filteredTournaments = _filteredTournaments;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Featured Tournament Banner (first upcoming tournament)
          if (filteredTournaments.isNotEmpty && 
              filteredTournaments.any((t) => t.isRegistrationOpen))
            _buildFeaturedTournament(
              filteredTournaments.firstWhere((t) => t.isRegistrationOpen, 
                  orElse: () => filteredTournaments.first),
              context,
            ),

          const SizedBox(height: 20),

          // Filter Chips
          _buildFilterChipsRow(),

          const SizedBox(height: 20),

          // Tournament Cards
          if (filteredTournaments.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 64,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tournaments found',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try changing the filter or check back later',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          else
            ...filteredTournaments.map(
              (tournament) => Column(
                children: [
                  _buildTournamentCard(tournament, context),
                  const SizedBox(height: 16),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Builds a featured tournament banner
  Widget _buildFeaturedTournament(
    Tournament tournament,
    BuildContext context,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 200,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withOpacity(0.8),
            colorScheme.primaryContainer,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Background pattern
            Positioned.fill(
              child: CustomPaint(
                painter: _FeaturedTournamentPainter(),
              ),
            ),

            // Featured badge
            Positioned(
              top: 20,
              left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.amber[600],
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'FEATURED',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Prize badge
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.card_giftcard,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '\$${tournament.rewardPrize.toStringAsFixed(0)}',
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

            // Main content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  
                  // Tournament title
                  Text(
                    tournament.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Tournament details
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.white.withOpacity(0.9),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                tournament.formattedDateRange,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${tournament.teams.length}/${tournament.maxTeams}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Register button
                  SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: tournament.isRegistrationOpen
                          ? () => _joinTournament(tournament)
                          : null,
                      icon: Icon(
                        tournament.isRegistrationOpen
                            ? Icons.app_registration
                            : Icons.sports,
                        size: 20,
                      ),
                      label: Text(
                        tournament.isRegistrationOpen
                            ? 'Join Tournament'
                            : 'Registration Closed',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
    Tournament tournament,
    BuildContext context,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDarkMode ? Colors.grey.shade800 : Colors.white,
            isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: -8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced Header with gradient overlay
            Container(
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withOpacity(0.8),
                    colorScheme.primaryContainer,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Background pattern
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _TournamentCardPainter(colorScheme.primary),
                    ),
                  ),
                  
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status badge and stadium
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    tournament.isRegistrationOpen
                                        ? Icons.play_circle_outline
                                        : tournament.isOngoing
                                            ? Icons.sports
                                            : Icons.check_circle_outline,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    tournament.isRegistrationOpen
                                        ? 'Open'
                                        : tournament.isOngoing
                                            ? 'Live'
                                            : 'Ended',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.stadium,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    tournament.stadiumName ?? 'TBD',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const Spacer(),
                        
                        // Tournament name
                        Text(
                          tournament.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Date and teams info
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.white.withOpacity(0.9),
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                tournament.formattedDateRange,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${tournament.teams.length}/${tournament.maxTeams}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
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
            ),

            // Enhanced Content section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description if available
                  if (tournament.description.isNotEmpty) ...[
                    Text(
                      tournament.description,
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                        fontSize: 14,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Enhanced Prize and Entry Fee Cards
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primary.withOpacity(0.1),
                                colorScheme.primary.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.primary.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.card_giftcard,
                                    color: colorScheme.primary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Prize Pool',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '\$${tournament.rewardPrize.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.grey.shade700.withOpacity(0.3)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDarkMode
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.attach_money,
                                    color: isDarkMode
                                        ? Colors.grey.shade300
                                        : Colors.grey.shade700,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Entry Fee',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDarkMode
                                          ? Colors.grey.shade300
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '\$${tournament.entryPricePerTeam.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Enhanced Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: Icon(
                            Icons.info_outline,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                          label: Text(
                            'Details',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: colorScheme.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: tournament.isRegistrationOpen
                              ? () => _joinTournament(tournament)
                              : null,
                          icon: Icon(
                            tournament.isRegistrationOpen
                                ? Icons.app_registration
                                : tournament.isOngoing
                                    ? Icons.sports
                                    : Icons.check_circle,
                            size: 18,
                          ),
                          label: Text(
                            tournament.isRegistrationOpen
                                ? 'Join Now'
                                : tournament.isOngoing
                                    ? 'Ongoing'
                                    : 'Ended',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tournament.isRegistrationOpen
                                ? colorScheme.primary
                                : Colors.grey,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: tournament.isRegistrationOpen ? 2 : 0,
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

class _TournamentCardPainter extends CustomPainter {
  final Color primaryColor;

  _TournamentCardPainter(this.primaryColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Draw circular patterns
    final center1 = Offset(size.width * 0.8, size.height * 0.2);
    final center2 = Offset(size.width * 0.2, size.height * 0.8);
    final center3 = Offset(size.width * 1.1, size.height * 0.6);

    canvas.drawCircle(center1, 40, paint);
    canvas.drawCircle(center2, 30, paint);
    canvas.drawCircle(center3, 60, paint);

    // Draw some lines for decoration
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.3);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.1,
      size.width,
      size.height * 0.4,
    );
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FeaturedTournamentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Draw larger decorative circles
    final center1 = Offset(size.width * 0.85, size.height * 0.15);
    final center2 = Offset(size.width * 0.15, size.height * 0.85);
    final center3 = Offset(size.width * 1.2, size.height * 0.5);

    canvas.drawCircle(center1, 60, paint);
    canvas.drawCircle(center2, 40, paint);
    canvas.drawCircle(center3, 80, paint);

    // Draw flowing lines
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path1 = Path();
    path1.moveTo(0, size.height * 0.2);
    path1.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.1,
      size.width * 0.6,
      size.height * 0.3,
    );
    path1.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.4,
      size.width,
      size.height * 0.2,
    );
    canvas.drawPath(path1, linePaint);

    final path2 = Path();
    path2.moveTo(0, size.height * 0.6);
    path2.quadraticBezierTo(
      size.width * 0.4,
      size.height * 0.4,
      size.width * 0.7,
      size.height * 0.7,
    );
    path2.quadraticBezierTo(
      size.width * 0.9,
      size.height * 0.8,
      size.width,
      size.height * 0.6,
    );
    canvas.drawPath(path2, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
