import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/stadium.dart';
import '../models/tournament.dart';
import '../services/stadium_service.dart';
import '../services/tournament_service.dart';
import '../auth_service.dart';
import '../themes/app_theme.dart';

class CreateTournamentScreen extends StatefulWidget {
  final Tournament? tournament;
  
  const CreateTournamentScreen({super.key, this.tournament});

  @override
  State<CreateTournamentScreen> createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends State<CreateTournamentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _entryPriceController = TextEditingController();
  final _rewardPrizeController = TextEditingController();
  final _maxTeamsController = TextEditingController();
  
  final StadiumService _stadiumService = StadiumService();
  final TournamentService _tournamentService = TournamentService();
  final AuthService _authService = AuthService();
  
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedStadiumId;
  List<Stadium> _availableStadiums = [];
  bool _isLoading = false;
  bool _isLoadingStadiums = true;
  bool _canCreateTournaments = false;
  bool get _isEditing => widget.tournament != null;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _entryPriceController.dispose();
    _rewardPrizeController.dispose();
    _maxTeamsController.dispose();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    await _checkPermissionsAndLoadStadiums();
    
    // Pre-fill form if editing
    if (_isEditing) {
      _prefillFormForEditing();
    }
  }
  
  void _prefillFormForEditing() {
    final tournament = widget.tournament!;
    _nameController.text = tournament.name;
    _descriptionController.text = tournament.description;
    // Format prices to remove unnecessary decimal places
    _entryPriceController.text = tournament.entryPricePerTeam % 1 == 0 
        ? tournament.entryPricePerTeam.toInt().toString() 
        : tournament.entryPricePerTeam.toString();
    _rewardPrizeController.text = tournament.rewardPrize % 1 == 0 
        ? tournament.rewardPrize.toInt().toString() 
        : tournament.rewardPrize.toString();
    _maxTeamsController.text = tournament.maxTeams.toString();
    _startDate = tournament.startDate;
    _endDate = tournament.endDate;
    _selectedStadiumId = tournament.stadiumId;
  }

  Future<void> _checkPermissionsAndLoadStadiums() async {
    try {
      setState(() {
        _isLoadingStadiums = true;
      });

      // Check if user can create tournaments
      final canCreate = await _tournamentService.canCreateTournaments();
      
      if (!canCreate) {
        setState(() {
          _canCreateTournaments = false;
          _isLoadingStadiums = false;
        });
        return;
      }

      // Load available stadiums
      final stadiums = await _stadiumService.getStadiums();
      setState(() {
        _canCreateTournaments = true;
        _availableStadiums = stadiums;
        _isLoadingStadiums = false;
      });
    } catch (e) {
      setState(() {
        _canCreateTournaments = false;
        _isLoadingStadiums = false;
      });
      if (mounted) {
        _showErrorSnackBar('Failed to load stadiums: ${e.toString()}');
      }
    }
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        // Reset end date if it's before the new start date
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    if (_startDate == null) {
      _showErrorSnackBar('Please select start date first');
      return;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate!.add(const Duration(days: 1)),
      firstDate: _startDate!.add(const Duration(days: 1)),
      lastDate: _startDate!.add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startDate == null || _endDate == null) {
      _showErrorSnackBar('Please select both start and end dates');
      return;
    }

    if (_selectedStadiumId == null || _selectedStadiumId!.isEmpty) {
      _showErrorSnackBar('Please select a stadium');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isEditing) {
        // Update existing tournament
        final tournament = await _tournamentService.updateTournament(
          tournamentId: widget.tournament!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          entryPricePerTeam: double.parse(_entryPriceController.text),
          rewardPrize: double.parse(_rewardPrizeController.text),
          maxTeams: int.parse(_maxTeamsController.text),
          startDate: _startDate!,
          endDate: _endDate!,
          stadiumId: _selectedStadiumId!,
        );

        if (mounted) {
          _showSuccessSnackBar('Tournament "${tournament.name}" updated successfully!');
          Navigator.pop(context, true);
        }
      } else {
        // Create new tournament
        final tournament = await _tournamentService.createTournament(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          entryPricePerTeam: double.parse(_entryPriceController.text),
          rewardPrize: double.parse(_rewardPrizeController.text),
          maxTeams: int.parse(_maxTeamsController.text),
          startDate: _startDate!,
          endDate: _endDate!,
          stadiumId: _selectedStadiumId!,
        );

        if (mounted) {
          _showSuccessSnackBar('Tournament "${tournament.name}" created successfully!');
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to ${_isEditing ? 'update' : 'create'} tournament: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Tournament' : 'Create Tournament',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDarkMode ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDarkMode ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
        ),
      ),
      body: _isLoadingStadiums
          ? const Center(child: CircularProgressIndicator())
          : !_canCreateTournaments
              ? _buildPermissionDeniedView()
              : _buildCreateTournamentForm(),
    );
  }

  Widget _buildPermissionDeniedView() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.warningYellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.warningYellow.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.lock_outline,
                size: 48,
                color: AppTheme.warningYellow,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Access Restricted',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? AppTheme.darkSurface.withOpacity(0.5)
                    : AppTheme.lightSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Only stadium owners can create tournaments.\nPlease contact an administrator if you believe this is an error.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppTheme.gradientOrange,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.mediumShadow,
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Go Back',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateTournamentForm() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppTheme.gradientPurple,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentPurple.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Background pattern
                  Positioned(
                    right: -30,
                    top: -30,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -40,
                    bottom: -40,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                  // Content
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.emoji_events,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _isEditing ? 'Edit Tournament' : 'Create New Tournament',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isEditing ? 'Update your tournament details' : 'Set up your tournament details',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Tournament Name
            _buildTextFormField(
              controller: _nameController,
              label: 'Tournament Name',
              hint: 'Enter tournament name',
              icon: Icons.title,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Tournament name is required';
                }
                if (value.trim().length < 3) {
                  return 'Name must be at least 3 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // Description
            _buildTextFormField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Enter tournament description',
              icon: Icons.description,
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Description is required';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // Stadium Selection
            _buildStadiumDropdown(),

            const SizedBox(height: 20),

            // Entry Price and Reward Prize
            Row(
              children: [
                Expanded(
                  child: _buildTextFormField(
                    controller: _entryPriceController,
                    label: 'Entry Price (\$)',
                    hint: '0',
                    icon: Icons.attach_money,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      final price = double.tryParse(value);
                      if (price == null || price < 0) {
                        return 'Enter valid price';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextFormField(
                    controller: _rewardPrizeController,
                    label: 'Reward Prize (\$)',
                    hint: '0',
                    icon: Icons.card_giftcard,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      final prize = double.tryParse(value);
                      if (prize == null || prize < 0) {
                        return 'Enter valid prize';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Max Teams
            _buildTextFormField(
              controller: _maxTeamsController,
              label: 'Maximum Teams',
              hint: 'Enter max number of teams',
              icon: Icons.group,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Required';
                }
                final teams = int.tryParse(value);
                if (teams == null || teams < 2) {
                  return 'Minimum 2 teams required';
                }
                if (teams > 64) {
                  return 'Maximum 64 teams allowed';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // Date Selection
            _buildDateSelectionRow(),

            const SizedBox(height: 40),

            // Create Button
            Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppTheme.gradientGreen,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.successGreen.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: (_isLoading || _availableStadiums.isEmpty) ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isEditing ? Icons.edit : Icons.add, 
                            size: 20
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isEditing ? 'Update Tournament' : 'Create Tournament',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Cancel Button
            Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.errorRed,
                  width: 1.5,
                ),
              ),
              child: OutlinedButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide.none,
                  foregroundColor: AppTheme.errorRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[50],
      ),
    );
  }

  Widget _buildStadiumDropdown() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    if (_availableStadiums.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue),
        ),
        child: Row(
          children: [
            Icon(Icons.info, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No stadiums available for tournament creation',
                style: TextStyle(color: Colors.blue[800]),
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedStadiumId,
      decoration: InputDecoration(
        labelText: 'Stadium',
        prefixIcon: Icon(Icons.stadium, color: colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[50],
      ),
      items: _availableStadiums.map((stadium) {
        return DropdownMenuItem<String>(
          value: stadium.id,
          child: Text(
            '${stadium.name} - ${stadium.location}',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (String? stadiumId) {
        setState(() {
          _selectedStadiumId = stadiumId;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a stadium';
        }
        return null;
      },
    );
  }

  Widget _buildDateSelectionRow() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _selectStartDate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Start Date',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _startDate != null
                        ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                        : 'Select date',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: _selectEndDate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.event, color: colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'End Date',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _endDate != null
                        ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                        : 'Select date',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}