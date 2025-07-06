import 'package:flutter/material.dart';
import '../models/team.dart';
import '../services/team_service.dart';
import '../utils/validation_utils.dart';

class InviteUserScreen extends StatefulWidget {
  final String teamId;

  const InviteUserScreen({
    super.key,
    required this.teamId,
  });

  @override
  State<InviteUserScreen> createState() => _InviteUserScreenState();
}

class _InviteUserScreenState extends State<InviteUserScreen> {
  final TeamService _teamService = TeamService();
  final TextEditingController _searchController = TextEditingController();
  
  List<TeamMember> _searchResults = [];
  bool _isSearching = false;
  String _selectedSearchField = 'username';
  String? _error;

  final List<String> _searchFields = [
    'username',
    'email', 
    'phoneNumber',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getHintText() {
    final screenWidth = MediaQuery.of(context).size.width;
    final field = _selectedSearchField.replaceAll('Number', ' number');
    
    if (screenWidth < 360) {
      // Short hint for very small screens
      return 'Enter $field';
    } else if (screenWidth < 400) {
      // Medium hint for small screens
      return 'Search $field...';
    } else {
      // Full hint for larger screens
      return 'Enter $field...';
    }
  }

  Future<void> _searchUsers() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _error = null;
      });
      return;
    }

    // Validate search input
    if (query.length < 2) {
      setState(() {
        _error = 'Search term must be at least 2 characters long';
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    // Sanitize search input - remove potential harmful characters
    final sanitizedQuery = query
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll('&', '')
        .replaceAll(';', '');
    if (sanitizedQuery != query) {
      setState(() {
        _error = 'Search term contains invalid characters';
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    // Validate based on search field type
    String? validationError;
    switch (_selectedSearchField) {
      case 'email':
        validationError = ValidationUtils.validateEmail(query);
        break;
      case 'phone':
        validationError = ValidationUtils.validatePhone(query);
        break;
      case 'username':
        // For username search, we can be more lenient than creation validation
        if (query.length < 2) {
          validationError = 'Username search must be at least 2 characters';
        }
        break;
    }

    if (validationError != null) {
      setState(() {
        _error = validationError;
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    try {
      setState(() {
        _isSearching = true;
        _error = null;
      });

      final results = await _teamService.searchUsers(
        keyword: query,
        field: _selectedSearchField,
      );

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  Future<void> _inviteUser(TeamMember user) async {
    try {
      await _teamService.inviteUser(
        userIdToInvite: user.id,
        teamId: widget.teamId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invitation sent to ${user.username}'),
            backgroundColor: Colors.green,
          ),
        );

        // Remove the invited user from search results
        setState(() {
          _searchResults.removeWhere((u) => u.id == user.id);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to invite ${user.username}: ${e.toString()}'),
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
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Invite Users'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Fixed header section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
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
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person_search,
                    color: colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Find Team Members',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Search for users to invite to your team',
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Search Field Selector
            Text(
              'Search by:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSearchField,
                  isExpanded: true,
                  icon: Icon(Icons.arrow_drop_down, color: colorScheme.primary),
                  items: _searchFields.map((field) {
                    return DropdownMenuItem(
                      value: field,
                      child: Text(
                        field.replaceAll('Number', ' Number'),
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedSearchField = value;
                        _searchResults = [];
                        _error = null;
                      });
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: _getHintText(),
                  hintMaxLines: 1,
                  prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                  suffixIcon: _isSearching
                      ? Container(
                          width: 40,
                          padding: const EdgeInsets.all(12),
                          child: const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _searchController.text.isNotEmpty 
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              iconSize: 20,
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchResults = [];
                                  _error = null;
                                });
                              },
                            )
                          : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                ),
                onChanged: (value) {
                  // Debounce search
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (_searchController.text == value) {
                      _searchUsers();
                    }
                  });
                },
                onSubmitted: (value) => _searchUsers(),
              ),
            ),
                ],
              ),
            ),
            // Scrollable results section  
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSearchResults(colorScheme, isDarkMode),
              ),
            ),
          ],
        ),
      ),
      
    );
  }

  Widget _buildSearchResults(ColorScheme colorScheme, bool isDarkMode) {
    if (_error != null) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Search Error',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _searchUsers,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_searchController.text.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search,
                size: 64,
                color: Colors.grey.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Start Searching',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Enter a ${_selectedSearchField.replaceAll('Number', ' number')} to find users',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_searchResults.isEmpty && !_isSearching) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_off,
                size: 64,
                color: Colors.grey.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No Users Found',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text('Try a different search term'),
            ],
          ),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Search Results (${_searchResults.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final user = _searchResults[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: colorScheme.primary.withOpacity(0.1),
                      child: Text(
                        user.username.isNotEmpty 
                            ? user.username[0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            user.username,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: TextStyle(
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (user.phoneNumber.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              user.phoneNumber,
                              style: TextStyle(
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    MediaQuery.of(context).size.width < 400
                        ? ElevatedButton(
                            onPressed: () => _inviteUser(user),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              minimumSize: const Size(60, 36),
                            ),
                            child: const Icon(Icons.send, size: 16),
                          )
                        : ElevatedButton.icon(
                            onPressed: () => _inviteUser(user),
                            icon: const Icon(Icons.send, size: 16),
                            label: const Text('Invite'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                  ],
                ),
                ),
              );
            },
            childCount: _searchResults.length,
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 16),
        ),
      ],
    );
  }
}