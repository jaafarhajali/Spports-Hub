import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:first_attempt/services/user_service.dart';

class UserProfileAvatar extends StatefulWidget {
  final Map<String, dynamic>? userProfile;
  final File? selectedImage;
  final Uint8List? selectedImageBytes; // For web support
  final bool isEditing;
  final VoidCallback? onImagePick;
  final UserService userService;

  const UserProfileAvatar({
    super.key,
    required this.userProfile,
    required this.selectedImage,
    this.selectedImageBytes,
    required this.isEditing,
    required this.onImagePick,
    required this.userService,
  });

  @override
  State<UserProfileAvatar> createState() => _UserProfileAvatarState();
}

class _UserProfileAvatarState extends State<UserProfileAvatar> {
  String? _imageKey;

  @override
  void initState() {
    super.initState();
    _updateImageKey();
  }

  @override
  void didUpdateWidget(UserProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userProfile?['profilePhoto'] !=
            widget.userProfile?['profilePhoto'] ||
        oldWidget.selectedImage != widget.selectedImage ||
        oldWidget.selectedImageBytes != widget.selectedImageBytes) {
      _updateImageKey();
    }
  }

  void _updateImageKey() {
    final profilePhoto = widget.userProfile?['profilePhoto'];
    final selectedPath = widget.selectedImage?.path;
    _imageKey =
        'avatar_${DateTime.now().millisecondsSinceEpoch}_${profilePhoto ?? selectedPath ?? 'default'}';
  }

  Widget _buildDefaultAvatar(ColorScheme colorScheme) {
    final userName = widget.userProfile?['name'] ?? widget.userProfile?['username'] ?? 'User';
    final firstLetter = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';
    
    return Container(
      color: colorScheme.primary.withOpacity(0.1),
      child: Center(
        child: Text(
          firstLetter,
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color:
                  widget.isEditing
                      ? colorScheme.primary.withOpacity(0.5)
                      : colorScheme.primary.withOpacity(0.3),
              width: widget.isEditing ? 4 : 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipOval(child: _buildImage(colorScheme)),
        ),
        if (widget.isEditing)
          Positioned(
            bottom: 0,
            right: 0,
            child: AnimatedScale(
              scale: widget.isEditing ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: GestureDetector(
                onTap: widget.onImagePick,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImage(ColorScheme colorScheme) {
    // Priority: Selected image bytes (web) > Selected image file (mobile) > Network image > Default avatar
    
    // Handle selected image for web
    if (kIsWeb && widget.selectedImageBytes != null) {
      return Image.memory(
        widget.selectedImageBytes!,
        fit: BoxFit.cover,
        key: Key('selected_bytes_${widget.selectedImageBytes.hashCode}'),
        errorBuilder: (context, error, stackTrace) {
          print('Error loading selected image bytes: $error');
          return _buildDefaultAvatar(colorScheme);
        },
      );
    }
    
    // Handle selected image for mobile
    if (!kIsWeb && widget.selectedImage != null) {
      return Image.file(
        widget.selectedImage!,
        fit: BoxFit.cover,
        key: Key('selected_file_${widget.selectedImage!.path}'),
        errorBuilder: (context, error, stackTrace) {
          print('Error loading selected image file: $error');
          return _buildDefaultAvatar(colorScheme);
        },
      );
    }

    // Handle network image from profile
    final profilePhoto = widget.userProfile?['profilePhoto'];
    if (profilePhoto != null && profilePhoto.isNotEmpty) {
      final imageUrl = widget.userService.getProfilePhotoUrl(profilePhoto);
      if (imageUrl != null) {
        return Image.network(
          imageUrl,
          fit: BoxFit.cover,
          key: Key(_imageKey!),
          headers: const {
            'Accept': 'image/*',
            'Cache-Control': 'no-cache',
          },
          errorBuilder: (context, error, stackTrace) {
            print('Error loading network image from $imageUrl: $error');
            return _buildDefaultAvatar(colorScheme);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              alignment: Alignment.center,
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            );
          },
        );
      }
    }

    return _buildDefaultAvatar(colorScheme);
  }
}
