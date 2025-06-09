import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'academies_screen.dart';
import 'tournaments_screen.dart';
import 'booking_screen.dart';

import '../widgets/theme_toggle_button.dart';
import '../log page/signin_page.dart'; // Add this import

class SportsHub extends StatefulWidget {
  const SportsHub({super.key});

  @override
  State<SportsHub> createState() => _SportsHubState();
}

class _SportsHubState extends State<SportsHub>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _animationController;

  // For search bar animation
  bool _isSearchExpanded = false;
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  final List<Widget> _screens = [
    const HomeScreen(),
    const AcademiesScreen(),
    const TournamentsScreen(),
    const BookingScreen(),
  ];

  final List<String> _screenTitles = [
    'Sports Hub',
    'Academies',
    'Tournaments',
    'Book a Facility',
  ];

  final List<String> _screenSubtitles = [
    'Find and book sports facilities',
    'Browse sports academies',
    'Find and join tournaments',
    'Book available facilities',
  ];

  final List<String> _searchHints = [
    'Search facilities, academies, events...',
    'Search academies...',
    'Search tournaments...',
    'Search facilities...',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus && !_isSearchExpanded) {
        setState(() {
          _isSearchExpanded = true;
        });
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // Close search if open
      if (_isSearchExpanded) {
        _closeSearch();
      }
    });
  }

  void _closeSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();

    // Add a slight delay to ensure the keyboard is dismissed first
    Future.delayed(const Duration(milliseconds: 50), () {
      setState(() {
        _isSearchExpanded = false;
      });
      _animationController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context),
      body: SafeArea(
        child: Column(
          children: [
            // Custom app bar with title and search - Fixed overflow
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child:
                  _isSearchExpanded
                      ? _buildExpandedSearchBar()
                      : _buildAppBar(isDarkMode),
            ),

            // Screen content
            Expanded(
              child: IndexedStack(index: _selectedIndex, children: _screens),
            ),
          ],
        ),
      ),
      floatingActionButton:
          _selectedIndex == 2 || _selectedIndex == 3
              ? FloatingActionButton(
                onPressed: () {},
                backgroundColor: colorScheme.primary,
                elevation: 4,
                child: Icon(
                  _selectedIndex == 2 ? Icons.add : Icons.calendar_today,
                  color: Colors.white,
                ),
              )
              : null,
      bottomNavigationBar: _buildBottomNavBar(isDarkMode, colorScheme),
    );
  }

  Widget _buildAppBar(bool isDarkMode) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row with title and action buttons
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title section - with proper flex
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _screenTitles[_selectedIndex],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _screenSubtitles[_selectedIndex],
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Action buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {},
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  iconSize: 20,
                ),
                const ThemeToggleButton(),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Search bar
        _buildSearchBar(isDarkMode),
      ],
    );
  }

  Widget _buildSearchBar(bool isDarkMode) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isSearchExpanded = true;
        });
        _animationController.forward();
        _searchFocusNode.requestFocus();
      },
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              size: 16,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _searchHints[_selectedIndex],
                style: TextStyle(
                  color:
                      isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedSearchBar() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 40,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _closeSearch,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            iconSize: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: _searchHints[_selectedIndex],
                  hintStyle: TextStyle(
                    color:
                        isDarkMode
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                    fontSize: 12,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  suffixIcon:
                      _searchController.text.isNotEmpty
                          ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              size: 16,
                              color:
                                  isDarkMode
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                          : null,
                ),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 12,
                ),
                textInputAction: TextInputAction.search,
                onChanged: (value) {
                  setState(() {});
                },
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    print('Searching for: $value');
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(bool isDarkMode, ColorScheme colorScheme) {
    // Use a more efficient way to build navigation items
    final navItems = <Widget>[
      _buildNavItem(0, Icons.home_rounded, 'Home'),
      _buildNavItem(1, Icons.school_rounded, 'Academies'),
      _buildNavItem(2, Icons.emoji_events_rounded, 'Tournaments'),
      _buildNavItem(3, Icons.calendar_month_rounded, 'Booking'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? colorScheme.surface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 10,
            offset: const Offset(0, -1),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ...navItems,
              // Menu button
              InkWell(
                onTap: () => _scaffoldKey.currentState?.openDrawer(),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withAlpha(26),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.menu_rounded,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Flexible(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color:
                    isSelected
                        ? Colors.white
                        : isDarkMode
                        ? Colors.white70
                        : Colors.black54,
                size: 20,
              ),
              // Only show text if this item is selected
              if (isSelected) ...[
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDarkMode ? colorScheme.surface : Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withAlpha(179),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: colorScheme.primary.withAlpha(179),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'John Doe',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Active Member',
                            style: TextStyle(
                              color: Colors.white.withAlpha(204),
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.mail_outline,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'user@example.com',
                          style: TextStyle(
                            color: Colors.white.withAlpha(230),
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerSection('Account'),
          _buildDrawerItem(context, Icons.person_outline, 'My Profile'),
          _buildDrawerItem(context, Icons.history, 'Booking History'),
          _buildDrawerItem(context, Icons.favorite_border, 'Favorites'),
          _buildDrawerSection('Settings'),
          _buildDrawerItem(context, Icons.settings_outlined, 'Settings'),
          _buildDrawerItem(
            context,
            Icons.notifications_outlined,
            'Notifications',
          ),
          _buildDrawerSection('Host'),
          _buildDrawerItem(context, Icons.stadium_outlined, 'Add Facility'),
          _buildDrawerItem(
            context,
            Icons.emoji_events_outlined,
            'Create Tournament',
          ),
          const Divider(),
          _buildDrawerItem(context, Icons.help_outline, 'Help & Support'),
          _buildDrawerItem(context, Icons.logout_outlined, 'Logout'),
        ],
      ),
    );
  }

  Widget _buildDrawerSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Icon(icon, color: colorScheme.primary, size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
      onTap: () {
        Navigator.pop(context); // Close the drawer

        // Handle navigation or action
        if (title == 'Logout') {
          // Use this approach for more reliable navigation:
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => SignInPage()),
            (route) => false, // This clears the navigation stack
          );
        }
      },
    );
  }
}
