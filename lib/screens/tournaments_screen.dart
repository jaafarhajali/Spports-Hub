import 'package:flutter/material.dart';
import '../models/tournament.dart';
import '../services/tournament_service.dart';
import '../services/team_service.dart';
import '../models/team.dart';
import '../widgets/tournament_payment_popup.dart';

class TournamentsScreen extends StatefulWidget {
  final String? searchQuery;
  
  const TournamentsScreen({super.key, this.searchQuery});

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen> {
  List<Tournament> _tournaments = [];
  List<Tournament> _filteredTournaments = [];
  bool _isLoading = true;
  String? _error;
  Team? _userTeam;
  final TournamentService _tournamentService = TournamentService();
  final TeamService _teamService = TeamService();
  
  // Color palette for tournament cards
  final List<Color> _tournamentColors = [
    Colors.blue,
    Colors.purple,
    Colors.teal,
    Colors.orange,
    Colors.pink,
    Colors.indigo,
    Colors.cyan,
    Colors.amber,
    Colors.deepOrange,
    Colors.green,
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  @override
  void didUpdateWidget(TournamentsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery) {
      _applySearchFilter();
    }
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load tournaments first
      List<Tournament> tournaments = [];
      try {
        tournaments = await _tournamentService.getAllTournaments();
      } catch (e) {
        print('Error loading tournaments: $e');
        tournaments = [];
      }
      
      // Load user team
      Team? userTeam;
      try {
        userTeam = await _teamService.getMyTeam();
      } catch (e) {
        print('Could not load user team: $e');
        userTeam = null;
      }

      if (mounted) {
        setState(() {
          _tournaments = tournaments;
          _userTeam = userTeam;
          _isLoading = false;
        });
        
        _applySearchFilter();
      }
    } catch (e) {
      print('Error loading tournaments: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _joinTournament(Tournament tournament) async {
    // Check if user has a team
    if (_userTeam == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You need to create or join a team first'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Check if tournament is still open for registration
    if (!tournament.isRegistrationOpen) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tournament registration is closed'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Show payment popup first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TournamentPaymentPopup(
        tournament: tournament,
        onPaymentSuccess: (paymentResult) async {
          Navigator.of(context).pop(); // Close payment popup
          await _processTournamentJoin(tournament, paymentResult);
        },
        onCancel: () {
          Navigator.of(context).pop(); // Close payment popup
        },
      ),
    );
  }

  Future<void> _processTournamentJoin(Tournament tournament, Map<String, dynamic> paymentResult) async {
    try {
      final teamId = _userTeam?.id;
      if (teamId == null || teamId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Team information not available'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Joining tournament...'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      
      final result = await _tournamentService.joinTournament(tournament.id, teamId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Tournament join request processed'),
            backgroundColor: result['success'] == true ? Colors.green : Colors.red,
          ),
        );
        
        if (result['success'] == true) {
          _loadData(); // Reload tournaments on success
        }
      }
    } catch (e) {
      print('Error joining tournament: $e');
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

  void _applySearchFilter() {
    if (!mounted) return;
    
    setState(() {
      // Apply search filter if there's a search query
      if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
        final query = widget.searchQuery!.toLowerCase();
        _filteredTournaments = _tournaments.where((tournament) {
          return tournament.name.toLowerCase().contains(query) ||
                 tournament.description.toLowerCase().contains(query) ||
                 (tournament.stadiumName?.toLowerCase().contains(query) ?? false);
        }).toList();
      } else {
        _filteredTournaments = List.from(_tournaments);
      }
    });
  }
  
  Color _getTournamentColor(String tournamentId) {
    // Use tournament ID hash to get consistent color for each tournament
    final hash = tournamentId.hashCode;
    return _tournamentColors[hash.abs() % _tournamentColors.length];
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
            ...filteredTournaments.asMap().entries.map(
              (entry) {
                final tournament = entry.value;
                final color = _getTournamentColor(tournament.id);
                return Column(
                  children: [
                    _buildTournamentCard(tournament, context, color),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }


  /// Builds an individual card for a tournament
  Widget _buildTournamentCard(
    Tournament tournament,
    BuildContext context,
    Color primaryColor,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    
    // Validate tournament data
    if (tournament.id.isEmpty || tournament.name.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Invalid tournament data',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showTournamentDetails(tournament, primaryColor),
      child: Container(
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
              color: primaryColor.withOpacity(0.1),
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
                    primaryColor,
                    primaryColor.withOpacity(0.8),
                    primaryColor.withOpacity(0.6),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Background pattern
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _TournamentCardPainter(primaryColor),
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
                                    tournament.stadiumName?.isNotEmpty == true 
                                        ? tournament.stadiumName! 
                                        : 'Stadium TBD',
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
                                primaryColor.withOpacity(0.1),
                                primaryColor.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: primaryColor.withOpacity(0.2),
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
                                    color: primaryColor,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Prize Pool',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${tournament.rewardPrize.toStringAsFixed(0)} LBP',
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
                                '${tournament.entryPricePerTeam.toStringAsFixed(0)} LBP',
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
                          onPressed: () => _showTournamentDetails(tournament, primaryColor),
                          icon: Icon(
                            Icons.info_outline,
                            size: 18,
                            color: primaryColor,
                          ),
                          label: Text(
                            'Details',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: primaryColor),
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
                                ? primaryColor
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
    )
    );
  }

  /// Shows detailed tournament information in a popup dialog
  void _showTournamentDetails(Tournament tournament, Color primaryColor) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
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
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with tournament name and close button
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryColor,
                        primaryColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tournament.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tournament Details',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Description
                        _buildDetailSection(
                          'Description',
                          tournament.description,
                          Icons.description,
                          isDarkMode,
                        ),
                        const SizedBox(height: 16),
                        
                        // Stadium info
                        if (tournament.stadiumName != null)
                          _buildDetailSection(
                            'Stadium',
                            tournament.stadiumName!,
                            Icons.stadium,
                            isDarkMode,
                          ),
                        const SizedBox(height: 16),
                        
                        // Tournament details grid
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDarkMode 
                                ? Colors.grey.shade800.withOpacity(0.5)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDetailItem(
                                      'Max Teams',
                                      '${tournament.maxTeams}',
                                      Icons.groups,
                                      isDarkMode,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildDetailItem(
                                      'Current Teams',
                                      '${tournament.teams.length}',
                                      Icons.group,
                                      isDarkMode,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDetailItem(
                                      'Entry Fee',
                                      '${tournament.entryPricePerTeam.toStringAsFixed(0)} LBP',
                                      Icons.attach_money,
                                      isDarkMode,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildDetailItem(
                                      'Status',
                                      tournament.isRegistrationOpen ? 'Open' : 'Closed',
                                      tournament.isRegistrationOpen ? Icons.lock_open : Icons.lock,
                                      isDarkMode,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Join button
                        if (tournament.isRegistrationOpen)
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _joinTournament(tournament);
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Join Tournament'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds a detail section with title and content
  Widget _buildDetailSection(String title, String content, IconData icon, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  /// Builds a detail item for the grid
  Widget _buildDetailItem(String label, String value, IconData icon, bool isDarkMode) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ],
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

