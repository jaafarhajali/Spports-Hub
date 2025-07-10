import 'app_config.dart';
import 'user_service.dart';

class PaymentService {
  final String baseUrl = AppConfig.apiUrl;
  final UserService _userService = UserService();

  // Get user's wallet balance
  Future<Map<String, dynamic>> getWalletBalance() async {
    try {
      final result = await _userService.getCurrentUserProfile();
      if (result['success']) {
        return {'success': true, 'balance': result['data']['wallet'] ?? 0};
      } else {
        return result;
      }
    } catch (e) {
      print('Get wallet balance error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Process payment (for booking)
  Future<Map<String, dynamic>> processPayment({
    required double amount,
    required String cardNumber,
    required String expiryDate,
    required String cvv,
    String cardHolderName = 'Card Holder',
  }) async {
    try {
      // Validate card details
      if (!validateCardNumber(cardNumber)) {
        return {'success': false, 'message': 'Invalid card number'};
      }

      if (!validateExpiryDate(expiryDate)) {
        return {'success': false, 'message': 'Invalid expiry date'};
      }

      if (!validateCVV(cvv)) {
        return {'success': false, 'message': 'Invalid CVV'};
      }

      if (cardHolderName.trim().isEmpty) {
        return {'success': false, 'message': 'Card holder name is required'};
      }

      // In a real app, you would process the payment with a payment gateway here
      // For now, we'll simulate a successful payment since the booking endpoint
      // handles the wallet deduction and validation

      await Future.delayed(
        const Duration(seconds: 2),
      ); // Simulate payment processing

      return {
        'success': true,
        'message': 'Payment processed successfully',
        'transactionId': 'TXN_${DateTime.now().millisecondsSinceEpoch}',
      };
    } catch (e) {
      print('Process payment error: $e');
      return {
        'success': false,
        'message': 'Payment processing failed: ${e.toString()}',
      };
    }
  }

  // Validate card number (basic Luhn algorithm)
  bool validateCardNumber(String cardNumber) {
    // Remove spaces and non-digits
    final cleanNumber = cardNumber.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanNumber.length < 13 || cleanNumber.length > 19) {
      return false;
    }

    // Luhn algorithm
    int sum = 0;
    bool alternate = false;

    for (int i = cleanNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cleanNumber[i]);

      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit = (digit % 10) + 1;
        }
      }

      sum += digit;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }

  // Validate expiry date (MM/YY format)
  bool validateExpiryDate(String expiryDate) {
    final regex = RegExp(r'^(0[1-9]|1[0-2])\/([0-9]{2})$');
    if (!regex.hasMatch(expiryDate)) {
      return false;
    }

    final parts = expiryDate.split('/');
    final month = int.parse(parts[0]);
    final year = int.parse(parts[1]) + 2000; // Convert YY to YYYY

    final now = DateTime.now();
    final expiryDateTime = DateTime(
      year,
      month + 1,
      0,
    ); // Last day of expiry month

    return expiryDateTime.isAfter(now);
  }

  // Validate CVV
  bool validateCVV(String cvv) {
    final regex = RegExp(r'^[0-9]{3,4}$');
    return regex.hasMatch(cvv);
  }

  // Format card number for display
  String formatCardNumber(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(RegExp(r'[^\d]'), '');
    final buffer = StringBuffer();

    for (int i = 0; i < cleanNumber.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(cleanNumber[i]);
    }

    return buffer.toString();
  }

  // Get card type based on card number
  String getCardType(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanNumber.startsWith('4')) {
      return 'Visa';
    } else if (cleanNumber.startsWith('5') || cleanNumber.startsWith('2')) {
      return 'Mastercard';
    } else if (cleanNumber.startsWith('3')) {
      return 'American Express';
    } else {
      return 'Unknown';
    }
  }
}
