import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:first_attempt/services/user_service.dart';
import 'package:first_attempt/widgets/user_profile_avatar.dart';
import 'package:first_attempt/utils/image_utils.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  Map<String, dynamic>? _userProfile;
  File? _selectedImage;
  Uint8List? _selectedImageBytes; // For web support
  bool _isLoading = false;
  bool _isEditing = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _userService.getUserProfile();
      if (profile != null) {
        setState(() {
          _userProfile = profile;
          _usernameController.text = profile['username'] ?? '';
          _emailController.text = profile['email'] ?? '';
          _phoneController.text = profile['phoneNumber'] ?? '';
        });
      }
    } catch (e) {
      _showSnackBar('Failed to load profile: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      // Show image source selection dialog
      final ImageSource? source = await _showImageSourceDialog();
      if (source == null) return;

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        if (kIsWeb) {
          // For web, read as bytes
          final bytes = await image.readAsBytes();
          
          // Validate image bytes
          final validation = ImageUtils.validateImageBytes(bytes);
          if (validation != null) {
            _showSnackBar(validation, isError: true);
            return;
          }
          
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImage = null; // Clear file reference for web
          });
        } else {
          // For mobile, use file
          final file = File(image.path);
          
          // Validate image file
          final validation = ImageUtils.validateImageFile(file);
          if (validation != null) {
            _showSnackBar(validation, isError: true);
            return;
          }
          
          setState(() {
            _selectedImage = file;
            _selectedImageBytes = null; // Clear bytes reference for mobile
          });
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      _showSnackBar('Failed to pick image: $e', isError: true);
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              if (!kIsWeb) // Camera is not available on web
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _isUploadingImage = _selectedImage != null || _selectedImageBytes != null;
    });

    try {
      final result = await _userService.updateProfile(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        profilePhoto: _selectedImage,
        profilePhotoBytes: _selectedImageBytes,
      );

      if (result['success']) {
        _showSnackBar('Profile updated successfully!');
        setState(() {
          _isEditing = false;
          // Keep the selected image to show the update
          // _selectedImage = null;  // Don't clear this immediately
        });

        // Clear image cache to force refresh
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();

        await _loadUserProfile(); // Reload profile data

        // Now clear the selected image after reload
        setState(() {
          _selectedImage = null;
          _selectedImageBytes = null;
        });
      } else {
        _showSnackBar(result['message'] ?? 'Update failed', isError: true);
      }
    } catch (e) {
      _showSnackBar('Failed to update profile: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
        _isUploadingImage = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.edit, color: colorScheme.primary),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            TextButton(
              onPressed: () => setState(() {
                    _isEditing = false;
                    _selectedImage = null;
                    _selectedImageBytes = null;
                    // Reset form
                    _usernameController.text = _userProfile?['username'] ?? '';
                    _emailController.text = _userProfile?['email'] ?? '';
                    _phoneController.text = _userProfile?['phoneNumber'] ?? '';
                  }),
              child: Text(
                'Cancel',
                style: TextStyle(color: colorScheme.primary),
              ),
            ),
        ],
      ),
      body:
          _isLoading && _userProfile == null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Loading your profile...',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildProfileHeader(colorScheme, isDarkMode),
                      const SizedBox(height: 32),
                      _buildProfileCard(colorScheme, isDarkMode),
                      const SizedBox(height: 24),
                      if (_isEditing) _buildActionButtons(colorScheme),
                      if (!_isEditing) _buildTestSection(colorScheme),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildProfileHeader(ColorScheme colorScheme, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withOpacity(0.1),
            colorScheme.secondary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          UserProfileAvatar(
            userProfile: _userProfile,
            selectedImage: _selectedImage,
            selectedImageBytes: _selectedImageBytes,
            isEditing: _isEditing,
            onImagePick: _pickImage,
            userService: _userService,
          ),
          const SizedBox(height: 16),
          Text(
            _userProfile?['username'] ?? 'User',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _userProfile?['email'] ?? '',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _userProfile?['role'] ?? 'User',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(ColorScheme colorScheme, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          _buildInputField(
            controller: _usernameController,
            label: 'Username',
            icon: Icons.person_outline,
            enabled: _isEditing,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Username is required';
              }
              if (value.trim().length < 3) {
                return 'Username must be at least 3 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            enabled: _isEditing,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email is required';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _phoneController,
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            enabled: _isEditing,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Phone number is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          _buildInfoRow(
            'Member Since',
            _formatDate(_userProfile?['createdAt']),
            Icons.calendar_today,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Last Updated',
            _formatDate(_userProfile?['updatedAt']),
            Icons.update,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Account Status',
            _userProfile?['isActive'] == true ? 'Active' : 'Inactive',
            Icons.verified_outlined,
            statusColor:
                _userProfile?['isActive'] == true ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
        filled: true,
        fillColor:
            enabled
                ? (isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[50])
                : (isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[100]),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    Color? statusColor,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color:
              statusColor ?? (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color:
                      statusColor ??
                      (isDarkMode ? Colors.white : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _updateProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isUploadingImage ? 'Uploading Image...' : 'Saving...',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    'Save Changes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  Widget _buildTestSection(ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile Photo Testing',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _testImageDisplay(),
              icon: const Icon(Icons.image),
              label: const Text('Test Image Display'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.secondary,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Current profile photo: ${_userProfile?['profilePhoto'] ?? 'None'}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _testImageDisplay() {
    final testUrl = _userService.getTestProfilePhotoUrl();
    _showSnackBar('Test image URL: $testUrl');
    
    // Also show in dialog for better visibility
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile Photo Test'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Test URL: $testUrl'),
            const SizedBox(height: 16),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  testUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.error, color: Colors.red),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                ),
              ),
            ),
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
}
