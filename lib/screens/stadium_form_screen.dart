import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/stadium.dart';
import '../services/stadium_service.dart';
import '../services/user_service.dart';
import '../auth_service.dart';

class StadiumFormScreen extends StatefulWidget {
  final Stadium? stadium; // null for create, Stadium object for edit
  
  const StadiumFormScreen({super.key, this.stadium});

  @override
  State<StadiumFormScreen> createState() => _StadiumFormScreenState();
}

class _StadiumFormScreenState extends State<StadiumFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _stadiumService = StadiumService();
  final _userService = UserService();
  final _authService = AuthService();
  
  // Form controllers
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _maxPlayersController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _penaltyHoursController = TextEditingController();
  final _penaltyAmountController = TextEditingController();
  
  List<File> _selectedImages = [];
  bool _isLoading = false;
  bool _isEditMode = false;
  
  // Admin owner selection
  bool _isAdmin = false;
  List<Map<String, dynamic>> _stadiumOwners = [];
  String? _selectedOwnerId;
  bool _loadingOwners = false;
  Map<String, dynamic>? _currentOwner;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.stadium != null;
    _checkAdminStatus();
    
    if (_isEditMode) {
      _populateFields();
    }
  }

  Future<void> _checkAdminStatus() async {
    try {
      final userRole = await _authService.getUserRole();
      setState(() {
        _isAdmin = userRole == 'admin';
      });
      
      if (_isAdmin) {
        _loadStadiumOwners();
      }
    } catch (e) {
      print('Error checking admin status: $e');
    }
  }

  Future<void> _loadStadiumOwners() async {
    setState(() {
      _loadingOwners = true;
    });
    
    try {
      final owners = await _userService.getStadiumOwners();
      print('Loaded ${owners.length} stadium owners: $owners');
      setState(() {
        _stadiumOwners = owners;
        _loadingOwners = false;
      });
    } catch (e) {
      setState(() {
        _loadingOwners = false;
      });
      print('Error loading stadium owners: $e');
    }
  }

  void _populateFields() {
    final stadium = widget.stadium!;
    _nameController.text = stadium.name;
    _locationController.text = stadium.location;
    
    // Format numbers properly to avoid decimal issues
    _priceController.text = stadium.pricePerMatch.toStringAsFixed(0);
    _maxPlayersController.text = stadium.maxPlayers.toString();
    _startTimeController.text = stadium.workingHours['start'] ?? '';
    _endTimeController.text = stadium.workingHours['end'] ?? '';
    
    // Handle penalty policy values safely
    final hoursBefore = stadium.penaltyPolicy['hoursBefore'];
    final penaltyAmount = stadium.penaltyPolicy['penaltyAmount'];
    
    _penaltyHoursController.text = (hoursBefore?.toInt() ?? 0).toString();
    _penaltyAmountController.text = (penaltyAmount?.toDouble() ?? 0.0).toStringAsFixed(0);
    
    // Set current owner for display in edit mode
    if (stadium.owner != null) {
      _currentOwner = {
        '_id': stadium.owner!['_id'],
        'username': stadium.owner!['username'],
        'email': stadium.owner!['email'],
      };
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _maxPlayersController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _penaltyHoursController.dispose();
    _penaltyAmountController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages = images.take(5).map((xFile) => File(xFile.path)).toList();
      });
    }
  }

  Future<void> _selectTime(TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (picked != null) {
      setState(() {
        controller.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final workingHours = {
        'start': _startTimeController.text,
        'end': _endTimeController.text,
      };

      final penaltyPolicy = {
        'hoursBefore': int.tryParse(_penaltyHoursController.text) ?? 0,
        'penaltyAmount': double.tryParse(_penaltyAmountController.text) ?? 0.0,
      };

      if (_isEditMode) {
        await _stadiumService.updateStadium(
          stadiumId: widget.stadium!.id,
          name: _nameController.text,
          location: _locationController.text,
          pricePerMatch: double.tryParse(_priceController.text) ?? 0.0,
          maxPlayers: int.tryParse(_maxPlayersController.text) ?? 1,
          workingHours: workingHours,
          penaltyPolicy: penaltyPolicy,
          photos: _selectedImages.isNotEmpty ? _selectedImages : null,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stadium updated successfully!')),
        );
      } else {
        await _stadiumService.createStadium(
          name: _nameController.text,
          location: _locationController.text,
          pricePerMatch: double.tryParse(_priceController.text) ?? 0.0,
          maxPlayers: int.tryParse(_maxPlayersController.text) ?? 1,
          workingHours: workingHours,
          penaltyPolicy: penaltyPolicy,
          photos: _selectedImages.isNotEmpty ? _selectedImages : null,
          ownerId: _isAdmin && _selectedOwnerId != null ? _selectedOwnerId : null,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stadium created successfully!')),
        );
      }

      Navigator.of(context).pop(true); // Return true to indicate success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      readOnly: readOnly,
      onTap: onTap,
      style: TextStyle(
        fontSize: 16,
        color: colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: colorScheme.primary,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withOpacity(0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withOpacity(0.3),
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
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: isDarkMode 
            ? Colors.grey.shade800.withOpacity(0.5)
            : colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 14,
        ),
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildOwnerDisplay() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800.withOpacity(0.5) : colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.person,
              size: 20,
              color: colorScheme.primary,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stadium Owner',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentOwner?['username'] ?? 'Unknown Owner',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_currentOwner?['email'] != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _currentOwner!['email']!,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerSelection() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (_loadingOwners) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade800 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Loading stadium owners...',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
    
    return DropdownButtonFormField<String>(
      value: _selectedOwnerId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Stadium Owner',
        hintText: 'Select owner or leave blank to assign to yourself',
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.person,
            size: 20,
            color: colorScheme.primary,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withOpacity(0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withOpacity(0.3),
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
        fillColor: isDarkMode 
            ? Colors.grey.shade800.withOpacity(0.5)
            : colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 14,
        ),
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
          fontSize: 14,
        ),
      ),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text(
            'None (Assign to me)',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
        const DropdownMenuItem<String>(
          value: '',
          enabled: false,
          child: Divider(),
        ),
        ..._stadiumOwners.map((owner) {
          return DropdownMenuItem<String>(
            value: owner['_id']?.toString(),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    owner['username'] ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    owner['email'] ?? '',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
      onChanged: (String? value) {
        if (value == '') return;
        setState(() {
          _selectedOwnerId = value;
        });
      },
      validator: (value) {
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Edit Stadium' : 'Create Stadium',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.stadium,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isEditMode ? 'Update Stadium Details' : 'Create New Stadium',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isEditMode 
                        ? 'Update your stadium information and settings'
                        : 'Fill in the details to create a new stadium',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Basic Information Section
            _buildSection(
              title: 'Basic Information',
              icon: Icons.info_outline,
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: 'Stadium Name',
                  hint: 'Enter the name of your stadium',
                  icon: Icons.stadium,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter stadium name';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 20),
                
                _buildTextField(
                  controller: _locationController,
                  label: 'Location',
                  hint: 'Enter the stadium location',
                  icon: Icons.location_on,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter location';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Owner Selection (Admin only for create) or Owner Display (for edit)
                if (_isAdmin && !_isEditMode) ...[ 
                  _buildOwnerSelection(),
                  const SizedBox(height: 20),
                ] else if (_isEditMode && _currentOwner != null) ...[
                  _buildOwnerDisplay(),
                  const SizedBox(height: 20),
                ],
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Stadium Configuration Section
            _buildSection(
              title: 'Stadium Configuration',
              icon: Icons.settings,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 600) {
                      // Mobile layout - stack vertically
                      return Column(
                        children: [
                          _buildTextField(
                            controller: _priceController,
                            label: 'Price per Match',
                            hint: 'Enter price in LBP',
                            icon: Icons.attach_money,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                              TextInputFormatter.withFunction((oldValue, newValue) {
                                final text = newValue.text;
                                if (text.split('.').length > 2) {
                                  return oldValue;
                                }
                                return newValue;
                              }),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter price';
                              }
                              final doubleValue = double.tryParse(value);
                              if (doubleValue == null) {
                                return 'Please enter a valid number';
                              }
                              if (doubleValue <= 0) {
                                return 'Price must be greater than 0';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _maxPlayersController,
                            label: 'Max Players',
                            hint: 'Maximum capacity',
                            icon: Icons.people,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter maximum players';
                              }
                              final intValue = int.tryParse(value);
                              if (intValue == null) {
                                return 'Please enter a valid number';
                              }
                              if (intValue <= 0) {
                                return 'Maximum players must be greater than 0';
                              }
                              return null;
                            },
                          ),
                        ],
                      );
                    } else {
                      // Desktop/tablet layout - side by side
                      return Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _priceController,
                              label: 'Price per Match',
                              hint: 'Enter price in LBP',
                              icon: Icons.attach_money,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                                TextInputFormatter.withFunction((oldValue, newValue) {
                                  final text = newValue.text;
                                  if (text.split('.').length > 2) {
                                    return oldValue;
                                  }
                                  return newValue;
                                }),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter price';
                                }
                                final doubleValue = double.tryParse(value);
                                if (doubleValue == null) {
                                  return 'Please enter a valid number';
                                }
                                if (doubleValue <= 0) {
                                  return 'Price must be greater than 0';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _maxPlayersController,
                              label: 'Max Players',
                              hint: 'Maximum capacity',
                              icon: Icons.people,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter maximum players';
                                }
                                final intValue = int.tryParse(value);
                                if (intValue == null) {
                                  return 'Please enter a valid number';
                                }
                                if (intValue <= 0) {
                                  return 'Maximum players must be greater than 0';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Working Hours Section
            _buildSection(
              title: 'Working Hours',
              icon: Icons.schedule,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 600) {
                      // Mobile layout - stack vertically
                      return Column(
                        children: [
                          _buildTextField(
                            controller: _startTimeController,
                            label: 'Start Time',
                            hint: 'Select opening time',
                            icon: Icons.access_time,
                            readOnly: true,
                            onTap: () => _selectTime(_startTimeController),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select start time';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _endTimeController,
                            label: 'End Time',
                            hint: 'Select closing time',
                            icon: Icons.access_time_filled,
                            readOnly: true,
                            onTap: () => _selectTime(_endTimeController),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select end time';
                              }
                              return null;
                            },
                          ),
                        ],
                      );
                    } else {
                      // Desktop/tablet layout - side by side
                      return Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _startTimeController,
                              label: 'Start Time',
                              hint: 'Select opening time',
                              icon: Icons.access_time,
                              readOnly: true,
                              onTap: () => _selectTime(_startTimeController),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select start time';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _endTimeController,
                              label: 'End Time',
                              hint: 'Select closing time',
                              icon: Icons.access_time_filled,
                              readOnly: true,
                              onTap: () => _selectTime(_endTimeController),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select end time';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Penalty Policy Section
            _buildSection(
              title: 'Penalty Policy',
              icon: Icons.policy,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 600) {
                      // Mobile layout - stack vertically
                      return Column(
                        children: [
                          _buildTextField(
                            controller: _penaltyHoursController,
                            label: 'Hours Before',
                            hint: 'Cancellation deadline',
                            icon: Icons.timer,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter hours';
                              }
                              final intValue = int.tryParse(value);
                              if (intValue == null || intValue < 0) {
                                return 'Please enter a valid number of hours';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _penaltyAmountController,
                            label: 'Penalty Amount',
                            hint: 'Amount in LBP',
                            icon: Icons.payment,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                              TextInputFormatter.withFunction((oldValue, newValue) {
                                final text = newValue.text;
                                if (text.split('.').length > 2) {
                                  return oldValue;
                                }
                                return newValue;
                              }),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter penalty amount';
                              }
                              final doubleValue = double.tryParse(value);
                              if (doubleValue == null || doubleValue < 0) {
                                return 'Please enter a valid penalty amount';
                              }
                              return null;
                            },
                          ),
                        ],
                      );
                    } else {
                      // Desktop/tablet layout - side by side
                      return Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _penaltyHoursController,
                              label: 'Hours Before',
                              hint: 'Cancellation deadline',
                              icon: Icons.timer,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter hours';
                                }
                                final intValue = int.tryParse(value);
                                if (intValue == null || intValue < 0) {
                                  return 'Please enter a valid number of hours';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _penaltyAmountController,
                              label: 'Penalty Amount',
                              hint: 'Amount in LBP',
                              icon: Icons.payment,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                                TextInputFormatter.withFunction((oldValue, newValue) {
                                  final text = newValue.text;
                                  if (text.split('.').length > 2) {
                                    return oldValue;
                                  }
                                  return newValue;
                                }),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter penalty amount';
                                }
                                final doubleValue = double.tryParse(value);
                                if (doubleValue == null || doubleValue < 0) {
                                  return 'Please enter a valid penalty amount';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Images Section
            _buildSection(
              title: 'Stadium Images',
              icon: Icons.photo_camera,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.3),
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: colorScheme.primary.withOpacity(0.05),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.cloud_upload,
                        size: 48,
                        color: colorScheme.primary.withOpacity(0.7),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _selectedImages.isEmpty 
                            ? 'Upload Stadium Photos'
                            : '${_selectedImages.length} photos selected',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select up to 5 high-quality images',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Choose Photos'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (_selectedImages.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(right: 12),
                          width: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _selectedImages[index],
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Submit button
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Processing...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isEditMode ? Icons.update : Icons.add_circle,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isEditMode ? 'Update Stadium' : 'Create Stadium',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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
  }
}