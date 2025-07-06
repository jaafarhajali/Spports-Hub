import 'package:flutter/material.dart';

class ValidationUtils {
  // Email validation regex
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  // Phone number validation regex (international format)
  static final RegExp _phoneRegex = RegExp(
    r'^[\+]?[1-9][\d]{0,15}$',
  );

  // Password validation regex patterns
  static final RegExp _hasUppercase = RegExp(r'[A-Z]');
  static final RegExp _hasLowercase = RegExp(r'[a-z]');
  static final RegExp _hasDigit = RegExp(r'[0-9]');
  static final RegExp _hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>]');

  /// Validates email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!_emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validates phone number format
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove any spaces, dashes, or parentheses
    final cleanedValue = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    if (cleanedValue.length < 10) {
      return 'Phone number must be at least 10 digits';
    }
    
    if (!_phoneRegex.hasMatch(cleanedValue)) {
      return 'Please enter a valid phone number';
    }
    
    return null;
  }

  /// Validates password with comprehensive requirements
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    
    if (!_hasUppercase.hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    
    if (!_hasLowercase.hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    
    if (!_hasDigit.hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    
    if (!_hasSpecialChar.hasMatch(value)) {
      return 'Password must contain at least one special character';
    }
    
    return null;
  }

  /// Validates password confirmation
  static String? validatePasswordConfirmation(String? value, String? originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != originalPassword) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  /// Validates required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates username
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    
    if (value.length < 3) {
      return 'Username must be at least 3 characters long';
    }
    
    if (value.length > 30) {
      return 'Username must be less than 30 characters';
    }
    
    // Check for valid characters (letters, numbers, underscores)
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    
    return null;
  }

  /// Validates numeric input
  static String? validateNumeric(String? value, String fieldName, {double? min, double? max}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    final numericValue = double.tryParse(value);
    if (numericValue == null) {
      return 'Please enter a valid number';
    }
    
    if (min != null && numericValue < min) {
      return '$fieldName must be at least $min';
    }
    
    if (max != null && numericValue > max) {
      return '$fieldName must not exceed $max';
    }
    
    return null;
  }

  /// Validates positive number
  static String? validatePositiveNumber(String? value, String fieldName) {
    return validateNumeric(value, fieldName, min: 0.01);
  }

  /// Validates non-negative number
  static String? validateNonNegativeNumber(String? value, String fieldName) {
    return validateNumeric(value, fieldName, min: 0);
  }

  /// Validates text length
  static String? validateLength(String? value, String fieldName, {int? minLength, int? maxLength}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    if (minLength != null && value.length < minLength) {
      return '$fieldName must be at least $minLength characters long';
    }
    
    if (maxLength != null && value.length > maxLength) {
      return '$fieldName must be less than $maxLength characters';
    }
    
    return null;
  }

  /// Gets password strength indicator
  static PasswordStrength getPasswordStrength(String password) {
    if (password.isEmpty) return PasswordStrength.none;
    
    int score = 0;
    
    // Length check
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    
    // Character type checks
    if (_hasUppercase.hasMatch(password)) score++;
    if (_hasLowercase.hasMatch(password)) score++;
    if (_hasDigit.hasMatch(password)) score++;
    if (_hasSpecialChar.hasMatch(password)) score++;
    
    // Additional complexity checks
    if (password.length >= 16) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]{2,}').hasMatch(password)) score++;
    
    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.medium;
    if (score <= 6) return PasswordStrength.strong;
    return PasswordStrength.veryStrong;
  }

  /// Validates URL format
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null; // URL is optional in most cases
    }
    
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );
    
    if (!urlRegex.hasMatch(value)) {
      return 'Please enter a valid URL';
    }
    
    return null;
  }

  /// Validates date range
  static String? validateDateRange(DateTime? startDate, DateTime? endDate) {
    if (startDate == null || endDate == null) {
      return 'Both start and end dates are required';
    }
    
    if (startDate.isAfter(endDate)) {
      return 'Start date must be before end date';
    }
    
    if (startDate.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return 'Start date cannot be in the past';
    }
    
    return null;
  }
}

enum PasswordStrength {
  none,
  weak,
  medium,
  strong,
  veryStrong,
}

extension PasswordStrengthExtension on PasswordStrength {
  String get label {
    switch (this) {
      case PasswordStrength.none:
        return 'None';
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
      case PasswordStrength.veryStrong:
        return 'Very Strong';
    }
  }
  
  double get value {
    switch (this) {
      case PasswordStrength.none:
        return 0.0;
      case PasswordStrength.weak:
        return 0.25;
      case PasswordStrength.medium:
        return 0.5;
      case PasswordStrength.strong:
        return 0.75;
      case PasswordStrength.veryStrong:
        return 1.0;
    }
  }
  
  Color get color {
    switch (this) {
      case PasswordStrength.none:
        return const Color(0xFF9E9E9E);
      case PasswordStrength.weak:
        return const Color(0xFFFF5252);
      case PasswordStrength.medium:
        return const Color(0xFFFF9800);
      case PasswordStrength.strong:
        return const Color(0xFF4CAF50);
      case PasswordStrength.veryStrong:
        return const Color(0xFF2E7D32);
    }
  }
}