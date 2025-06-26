import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Add this for kIsWeb
import 'package:first_attempt/services/user_service.dart';

class UserProfileAvatar extends StatefulWidget {
  final Map<String, dynamic>? userProfile;
  final File? selectedImage;
  final bool isEditing;
  final VoidCallback? onImagePick;
  final UserService userService;

  const UserProfileAvatar({
    super.key,
    required this.userProfile,
    required this.selectedImage,
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
        oldWidget.selectedImage != widget.selectedImage) {
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
    return Container(
      color: colorScheme.primary.withOpacity(0.1),
      child: Icon(Icons.person, size: 60, color: colorScheme.primary),
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
    // Priority: Selected image > Network image > Default avatar
    if (widget.selectedImage != null) {
      // Handle web vs mobile differently
      if (kIsWeb) {
        // On web, we can't use Image.file, so we'll just show a placeholder
        // In a real app, you'd want to convert the file to bytes and use Image.memory
        return Container(
          color: colorScheme.primary.withOpacity(0.1),
          child: Icon(Icons.person, size: 60, color: colorScheme.primary),
        );
      } else {
        return Image.file(
          widget.selectedImage!,
          fit: BoxFit.cover,
          key: Key('selected_${widget.selectedImage!.path}'),
          errorBuilder: (context, error, stackTrace) {
            print('Error loading selected image: $error');
            return _buildDefaultAvatar(colorScheme);
          },
        );
      }
    }

    final profilePhoto = widget.userProfile?['profilePhoto'];
    if (profilePhoto != null && profilePhoto.isNotEmpty) {
      final imageUrl = widget.userService.getProfilePhotoUrl(profilePhoto);
      if (imageUrl != null) {
        return Image.network(
          imageUrl,
          fit: BoxFit.cover,
          key: Key(_imageKey!),
          errorBuilder: (context, error, stackTrace) {
            print('Error loading network image: $error');
            return _buildDefaultAvatar(colorScheme);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              alignment: Alignment.center,
              child: CircularProgressIndicator(
                value:
                    loadingProgress.expectedTotalBytes != null
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
