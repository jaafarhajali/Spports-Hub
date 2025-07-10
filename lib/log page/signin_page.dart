import 'package:flutter/material.dart';
import '../widgets/theme_toggle_button.dart';
import '../auth_service.dart'; // Add this import
import '../utils/validation_utils.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  final _authService = AuthService(); // Add this
  bool _isLoading = false; // Add this
  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  // Check if user should be automatically logged in
  Future<void> _checkAutoLogin() async {
    final shouldStayLoggedIn = await _authService.shouldStayLoggedIn();
    if (shouldStayLoggedIn) {
      // User has valid token and remember me is enabled
      Navigator.pushReplacementNamed(context, '/sports_hub');
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Color(0xFF121212) : Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
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
                // App icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/icon/ic_launcher.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Color(0xFF2196F3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.sports_soccer,
                            size: 40,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // App name
                Text(
                  'SPORTS HUB',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: isDarkMode ? Colors.white : Color(0xFF1A1A1A),
                    letterSpacing: 2.0,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Sign in to your account',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Color(0xFF9E9E9E) : Color(0xFF666666),
                  ),
                ),
                SizedBox(height: 48),

                // Login form
                Container(
                  constraints: BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: Color(0xFF757575),
                              size: 20,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color:
                                    isDarkMode
                                        ? Color(0xFF333333)
                                        : Color(0xFFE0E0E0),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color:
                                    isDarkMode
                                        ? Color(0xFF333333)
                                        : Color(0xFFE0E0E0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Color(0xFF2196F3),
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor:
                                isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            // Validate email format
                            return ValidationUtils.validateEmail(value);
                          },
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: Color(0xFF757575),
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Color(0xFF757575),
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color:
                                    isDarkMode
                                        ? Color(0xFF333333)
                                        : Color(0xFFE0E0E0),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color:
                                    isDarkMode
                                        ? Color(0xFF333333)
                                        : Color(0xFFE0E0E0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Color(0xFF2196F3),
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor:
                                isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          validator:
                              (value) => ValidationUtils.validateRequired(
                                value,
                                'Password',
                              ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        _rememberMe = value ?? false;
                                      });
                                    },
                                    activeColor: Color(0xFF2196F3),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Remember me',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        isDarkMode
                                            ? Color(0xFF9E9E9E)
                                            : Color(0xFF666666),
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/forgot_password',
                                );
                              },
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF2196F3),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 32),
                        ElevatedButton(
                          onPressed:
                              _isLoading
                                  ? null
                                  : () async {
                                    if (_formKey.currentState!.validate()) {
                                      try {
                                        setState(() {
                                          _isLoading = true;
                                        });

                                        // Save remember me preference
                                        await _authService.setRememberMe(
                                          _rememberMe,
                                        );

                                        // Add logging to help debug
                                        print(
                                          'Attempting login with username: ${_usernameController.text}',
                                        );

                                        final result = await _authService.login(
                                          _usernameController.text,
                                          _passwordController.text,
                                        );

                                        print('Login result: $result');

                                        setState(() {
                                          _isLoading = false;
                                        });

                                        if (result['success'] == true ||
                                            result.containsKey('token')) {
                                          // Show success message
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Sign in successful!',
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );

                                          // Navigate to the home page
                                          Navigator.pushReplacementNamed(
                                            context,
                                            '/sports_hub',
                                          );
                                        } else {
                                          // Show error message
                                          final errorMessage =
                                              result['message'] ??
                                              'Login failed';
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(errorMessage),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        print(
                                          'Login exception: ${e.toString()}',
                                        );
                                        setState(() {
                                          _isLoading = false;
                                        });

                                        // Show detailed error message
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Connection error: ${e.toString()}',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
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
                            disabledBackgroundColor: Color(
                              0xFF2196F3,
                            ).withOpacity(0.5),
                          ),
                          child:
                              _isLoading
                                  ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                  : Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 32),

                // Sign up section
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        color:
                            isDarkMode ? Color(0xFF9E9E9E) : Color(0xFF666666),
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/signup');
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                      ),
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Color(0xFF2196F3),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
