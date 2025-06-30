import 'dart:typed_data';
import 'dart:io';
import '../services/app_config.dart';

class ImageUtils {
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedExtensions = ['jpg', 'jpeg', 'png', 'gif'];
  
  static bool isValidImageFile(File file) {
    try {
      final extension = file.path.split('.').last.toLowerCase();
      return allowedExtensions.contains(extension);
    } catch (e) {
      return false;
    }
  }
  
  static bool isValidImageSize(File file) {
    try {
      final fileSize = file.lengthSync();
      return fileSize <= maxFileSize;
    } catch (e) {
      return false;
    }
  }
  
  static bool isValidImageBytesSize(Uint8List bytes) {
    return bytes.length <= maxFileSize;
  }
  
  static String getFileSizeString(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
  
  static String? validateImageFile(File? file) {
    if (file == null) return null;
    
    if (!isValidImageFile(file)) {
      return 'Please select a valid image file (${allowedExtensions.join(', ')})';
    }
    
    if (!isValidImageSize(file)) {
      final fileSize = getFileSizeString(file.lengthSync());
      final maxSize = getFileSizeString(maxFileSize);
      return 'Image size ($fileSize) exceeds maximum allowed size ($maxSize)';
    }
    
    return null;
  }
  
  static String? validateImageBytes(Uint8List? bytes) {
    if (bytes == null) return null;
    
    if (!isValidImageBytesSize(bytes)) {
      final fileSize = getFileSizeString(bytes.length);
      final maxSize = getFileSizeString(maxFileSize);
      return 'Image size ($fileSize) exceeds maximum allowed size ($maxSize)';
    }
    
    return null;
  }
  
  /// Get stadium image URL with proper path construction
  static String getStadiumImageUrl(String photoPath) {
    if (photoPath.startsWith('http')) {
      return photoPath;
    }
    
    if (photoPath.startsWith('/images')) {
      return '${AppConfig.apiUrl}$photoPath';
    }
    
    return '${AppConfig.apiUrl}/images/stadiumsImages/$photoPath';
  }
  
  /// Get academy image URL with proper path construction
  static String getAcademyImageUrl(String photoPath) {
    if (photoPath.startsWith('http')) {
      return photoPath;
    }
    
    if (photoPath.startsWith('/images')) {
      return '${AppConfig.apiUrl}$photoPath';
    }
    
    return '${AppConfig.apiUrl}/images/academiesImages/$photoPath';
  }
  
  /// Get tournament image URL with proper path construction
  static String getTournamentImageUrl(String photoPath) {
    if (photoPath.startsWith('http')) {
      return photoPath;
    }
    
    if (photoPath.startsWith('/images')) {
      return '${AppConfig.apiUrl}$photoPath';
    }
    
    return '${AppConfig.apiUrl}/images/tournamentsImages/$photoPath';
  }
}