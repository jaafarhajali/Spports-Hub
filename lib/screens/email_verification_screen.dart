import 'package:flutter/material.dart';
import '../auth_service.dart';
import '../widgets/theme_toggle_button.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String? token;
  
  const EmailVerificationScreen({
    super.key, 
    required this.email,
    this.token,
  });

  @override
  _EmailVerificationScreenState createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _authService = AuthService();
  bool _isLoading = false;
  bool _emailSent = false;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    // If token is provided, automatically verify
    if (widget.token != null) {
      _verifyEmail();
    } else {
      // No token provided, check if user is already verified
      _checkIfAlreadyVerified();
    }
  }

  Future<void> _checkIfAlreadyVerified() async {
    try {
      final isVerified = await _authService.isEmailVerified();
      if (isVerified) {
        setState(() {
          _emailSent = true; // Show success state
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Your email is already verified!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error checking verification status: $e');
    }
  }

  Future<void> _sendVerificationEmail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get user email from stored data if not provided
      String emailToUse = widget.email;
      if (emailToUse.isEmpty) {
        final userData = await _authService.getUserData();
        emailToUse = userData['email'] ?? '';
      }
      
      final result = await _authService.sendVerificationEmail(emailToUse);
      
      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        setState(() {
          _emailSent = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text((result['message'] != null) ? result['message'] : 'Verification email sent! Please check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text((result['message'] != null) ? result['message'] : 'Failed to send verification email'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _verifyEmail() async {
    if (widget.token == null) {
      // No token provided, check if user is already verified
      final isVerified = await _authService.isEmailVerified();
      if (isVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Your email is already verified! You can use all features.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        await Future.delayed(Duration(seconds: 1));
        
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/sports_hub',
          (route) => false,
        );
      }
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      print('Verifying email with token: ${widget.token}');
      final result = await _authService.verifyEmail(widget.token!);
      
      print('Email verification result: $result');
      
      setState(() {
        _isVerifying = false;
      });

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email verified successfully! You can now use all features.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Wait a moment for the snackbar to show, then navigate
        await Future.delayed(Duration(seconds: 1));
        
        // Navigate to home screen and clear all previous routes
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/sports_hub',
          (route) => false,
        );
      } else {
        // Check if the error is about already verified user or token expired but user is verified
        final errorMessage = (result['message'] != null) ? result['message'] : 'Email verification failed';
        final lowerMessage = errorMessage.toLowerCase();
        
        if (lowerMessage.contains('already verified') || 
            lowerMessage.contains('user is already verified') ||
            lowerMessage.contains('email verified successfully')) {
          // User is already verified, show success and navigate
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Your email is already verified! You can use all features.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          
          await Future.delayed(Duration(seconds: 1));
          
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/sports_hub',
            (route) => false,
          );
        } else if (lowerMessage.contains('expired') || lowerMessage.contains('invalid')) {
          // Token expired or invalid, but check if user is already verified
          final isVerified = await _authService.isEmailVerified();
          if (isVerified) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Your email is already verified! You can use all features.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
            
            await Future.delayed(Duration(seconds: 1));
            
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/sports_hub',
              (route) => false,
            );
          } else {
            // Show the actual error
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Verification link expired. Please request a new one from your profile.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 5),
              ),
            );
          }
        } else {
          // Show the actual error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isVerifying = false;
      });
      
      print('Email verification error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? Color(0xFF121212) : Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? Colors.white : Color(0xFF1A1A1A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: ThemeToggleButton(),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Color(0xFF2196F3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Icon(
                    _isVerifying
                        ? Icons.hourglass_empty
                        : _emailSent || widget.token != null
                            ? Icons.mark_email_read
                            : Icons.mark_email_unread,
                    size: 40,
                    color: Color(0xFF2196F3),
                  ),
                ),
                SizedBox(height: 24),
                
                // Title
                Text(
                  _isVerifying
                      ? 'Verifying Email...'
                      : _emailSent
                          ? 'Verification Email Sent!'
                          : widget.token != null
                              ? 'Email Verification'
                              : 'Verify Your Email',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode ? Colors.white : Color(0xFF1A1A1A),
                  ),
                ),
                SizedBox(height: 8),
                
                // Subtitle
                Text(
                  _isVerifying
                      ? 'Please wait while we verify your email address...'
                      : _emailSent 
                          ? 'We\'ve sent a verification link to ${widget.email}. Please check your inbox and click the link to verify your account.'
                          : widget.token != null
                              ? 'Verifying your email address...'
                              : 'To complete your registration, we need to verify your email address. Click the button below to send a verification email to ${widget.email}.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Color(0xFF9E9E9E) : Color(0xFF666666),
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 48),
                
                if (_isVerifying) ...[
                  // Verification in progress
                  Container(
                    constraints: BoxConstraints(maxWidth: 400),
                    child: Column(
                      children: [
                        CircularProgressIndicator(
                          color: Color(0xFF2196F3),
                          strokeWidth: 3,
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Verifying your email...',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode ? Color(0xFF9E9E9E) : Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (!_emailSent && widget.token == null) ...[
                  // Send verification email button
                  Container(
                    constraints: BoxConstraints(maxWidth: 400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          onPressed: _isLoading ? null : _sendVerificationEmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF2196F3),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            disabledBackgroundColor: Color(0xFF2196F3).withOpacity(0.5),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  'Send Verification Email',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ] else if (_emailSent) ...[
                  // Email sent - options
                  Container(
                    constraints: BoxConstraints(maxWidth: 400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _emailSent = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF2196F3),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                          ),
                          child: Text(
                            'Resend Verification Email',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextButton(
                          onPressed: () => Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/sports_hub',
                            (route) => false,
                          ),
                          child: Text(
                            'I\'ll Verify Later',
                            style: TextStyle(
                              color: Color(0xFF2196F3),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                SizedBox(height: 32),
                
                // Additional options
                if (!_isVerifying) ...[
                  TextButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/sports_hub',
                      (route) => false,
                    ),
                    child: Text(
                      'Go to App',
                      style: TextStyle(
                        color: Color(0xFF2196F3),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                
                SizedBox(height: 16),
                
                // Help text
                if (!_isVerifying)
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Color(0xFF1E1E1E) : Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFF2196F3),
                          size: 24,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Didn\'t receive the email?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Color(0xFF1A1A1A),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Check your spam/junk folder or try resending the verification email.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDarkMode ? Color(0xFF9E9E9E) : Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}