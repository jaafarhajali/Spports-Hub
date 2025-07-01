import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/stadium_service.dart';
import '../auth_service.dart';
import '../themes/app_theme.dart';

class CreateStadiumScreen extends StatefulWidget {
  const CreateStadiumScreen({super.key});

  @override
  State<CreateStadiumScreen> createState() => _CreateStadiumScreenState();
}

class _CreateStadiumScreenState extends State<CreateStadiumScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _maxPlayersController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _penaltyHoursController = TextEditingController();
  final _penaltyAmountController = TextEditingController();

  final StadiumService _stadiumService = StadiumService();
  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();

  final List<File> _selectedImages = [];
  bool _isLoading = false;
  bool _canCreateStadium = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _setDefaultValues();
  }

  void _setDefaultValues() {
    _startTimeController.text = '09:00';
    _endTimeController.text = '22:00';
    _penaltyHoursController.text = '2';
    _penaltyAmountController.text = '10000';
  }

  Future<void> _checkPermissions() async {
    final canCreate = await _stadiumService.canCreateStadiums();
    setState(() {
      _canCreateStadium = canCreate;
    });

    if (!canCreate) {
      _showErrorSnackBar('You do not have permission to create stadiums');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: Text(
          'Create Stadium',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color:
                isDarkMode
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color:
              isDarkMode ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
        ),
      ),
      body:
          !_canCreateStadium
              ? _buildPermissionDenied()
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBasicInfoSection(),
                      const SizedBox(height: 24),
                      _buildWorkingHoursSection(),
                      const SizedBox(height: 24),
                      _buildPenaltyPolicySection(),
                      const SizedBox(height: 24),
                      _buildPhotosSection(),
                      const SizedBox(height: 32),
                      _buildCreateButton(),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildPermissionDenied() {
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
                color: AppTheme.errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.errorRed.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.block,
                size: 48,
                color: AppTheme.errorRed,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Permission Denied',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color:
                    isDarkMode
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    isDarkMode
                        ? AppTheme.darkSurface.withOpacity(0.5)
                        : AppTheme.lightSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'You need to be a stadium owner to create stadiums.',
                style: TextStyle(
                  fontSize: 16,
                  color:
                      isDarkMode
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isDarkMode
                  ? AppTheme.darkBorder.withOpacity(0.3)
                  : AppTheme.lightBorder.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: AppTheme.mediumShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppTheme.gradientBlue,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.info, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Basic Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color:
                      isDarkMode
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildInputField(
            controller: _nameController,
            label: 'Stadium Name *',
            hint: 'Enter stadium name',
            icon: Icons.sports_soccer,
            isDarkMode: isDarkMode,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Stadium name is required';
              }
              if (value.trim().length < 3) {
                return 'Stadium name must be at least 3 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Location *',
              hintText: 'Enter stadium location',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Location is required';
              }
              if (value.trim().length < 3) {
                return 'Location must be at least 3 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price per Match (LBP) *',
                    hintText: '50000',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.monetization_on),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Price is required';
                    }
                    final price = double.tryParse(value);
                    if (price == null || price <= 0) {
                      return 'Enter valid price';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _maxPlayersController,
                  decoration: const InputDecoration(
                    labelText: 'Max Players *',
                    hintText: '22',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.people),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Max players required';
                    }
                    final players = int.tryParse(value);
                    if (players == null || players <= 0) {
                      return 'Enter valid number';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkingHoursSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Working Hours',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _startTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Start Time *',
                      hintText: '09:00',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.access_time),
                    ),
                    readOnly: true,
                    onTap: () => _selectTime(_startTimeController),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Start time is required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _endTimeController,
                    decoration: const InputDecoration(
                      labelText: 'End Time *',
                      hintText: '22:00',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.access_time),
                    ),
                    readOnly: true,
                    onTap: () => _selectTime(_endTimeController),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'End time is required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPenaltyPolicySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Penalty Policy',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cancellation penalty for bookings',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _penaltyHoursController,
                    decoration: const InputDecoration(
                      labelText: 'Hours Before *',
                      hintText: '2',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.schedule),
                      suffixText: 'hours',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Hours required';
                      }
                      final hours = int.tryParse(value);
                      if (hours == null || hours < 0) {
                        return 'Enter valid hours';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _penaltyAmountController,
                    decoration: const InputDecoration(
                      labelText: 'Penalty Amount (LBP) *',
                      hintText: '10000',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.monetization_on),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Penalty amount required';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount < 0) {
                        return 'Enter valid amount';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stadium Photos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add up to 5 photos (optional)',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            if (_selectedImages.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _selectedImages[index],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _selectedImages.length >= 5
                            ? null
                            : _pickImageFromCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _selectedImages.length >= 5
                            ? null
                            : _pickImageFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return Container(
      width: double.infinity,
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
        onPressed: _isLoading ? null : _createStadium,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child:
            _isLoading
                ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Create Stadium',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Future<void> _selectTime(TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      final formattedTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      controller.text = formattedTime;
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image from camera');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image from gallery');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _createStadium() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final stadium = await _stadiumService.createStadium(
        name: _nameController.text.trim(),
        location: _locationController.text.trim(),
        pricePerMatch: double.parse(_priceController.text),
        maxPlayers: int.parse(_maxPlayersController.text),
        workingHours: {
          'start': _startTimeController.text,
          'end': _endTimeController.text,
        },
        penaltyPolicy: {
          'hoursBefore': int.parse(_penaltyHoursController.text),
          'penaltyAmount': double.parse(_penaltyAmountController.text),
        },
        photos: _selectedImages.isNotEmpty ? _selectedImages : null,
      );

      _showSuccessSnackBar('Stadium created successfully!');
      Navigator.of(context).pop(stadium);
    } catch (e) {
      _showErrorSnackBar('Failed to create stadium: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
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
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDarkMode,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    String? suffixText,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        style: TextStyle(
          color:
              isDarkMode ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          suffixText: suffixText,
          labelStyle: TextStyle(
            color:
                isDarkMode
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppTheme.gradientBlue,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDarkMode ? AppTheme.darkBorder : AppTheme.lightBorder,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDarkMode ? AppTheme.darkBorder : AppTheme.lightBorder,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppTheme.errorRed, width: 2),
          ),
          filled: true,
          fillColor: isDarkMode ? AppTheme.darkSurface : AppTheme.lightSurface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
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
}
