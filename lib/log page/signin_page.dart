import 'package:flutter/material.dart';
import '../widgets/theme_toggle_button.dart';
import '../auth_service.dart'; // Add this import

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
    return Scaffold(
      appBar: AppBar(
        title: Text('Authentication'),
        actions: [ThemeToggleButton()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Sign In',
                    style: Theme.of(context).textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30),
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your username';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (bool? value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                          ),
                          Text('Keep me logged in'),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          // Forgot password logic
                        },
                        child: Text(
                          'Forgot password?',
                          style: TextStyle(color: Colors.teal),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
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
                                  await _authService.setRememberMe(_rememberMe);

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
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Sign in successful!'),
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
                                        result['message'] ?? 'Login failed';
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(errorMessage),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  print('Login exception: ${e.toString()}');
                                  setState(() {
                                    _isLoading = false;
                                  });

                                  // Show detailed error message
                                  ScaffoldMessenger.of(context).showSnackBar(
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
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      disabledBackgroundColor: Colors.teal.withOpacity(0.5),
                    ),
                    child:
                        _isLoading
                            ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : Text('Sign In'),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account? "),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/signup');
                        },
                        child: Text(
                          'Sign Up',
                          style: TextStyle(color: Colors.teal),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
