import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/firebase_auth_service.dart';
import '../../themes/app_theme.dart';
import '../../utils/enhanced_animations.dart';
import 'sign_up_screen.dart';
import 'forgot_password_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _isTestMode = false;
  String? _verificationMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      final authService = FirebaseAuthService.instance;
      
      try {
        // Show loading state
        setState(() {
          _isLoading = true;
          _verificationMessage = null;
        });
        
        debugPrint('🔐 Starting user login process...');
        
        // Attempt to sign in with Firebase
        final UserCredential userCredential = await authService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
        
        debugPrint('✅ User logged in successfully with UID: ${userCredential.user?.uid}');
        
        if (_isTestMode && userCredential.user != null) {
          // In test mode, display success message instead of navigating
          setState(() {
            _isLoading = false;
            _verificationMessage = 'Login successful! User authenticated with Firebase.';
          });
          return;
        }
        
        if (mounted && !_isTestMode) {
          final navigator = Navigator.of(context);
          final prefs = await SharedPreferences.getInstance();
          final quickSetupCompleted = prefs.getBool('quick_setup_completed') ?? false;
          navigator.pushReplacementNamed(
            quickSetupCompleted ? '/dashboard' : '/quick_setup',
          );
        }
      } on FirebaseAuthException catch (e) {
        // Handle specific Firebase Auth errors with user-friendly messages
        String errorMessage = 'An error occurred during sign in';
        
        if (e.code == 'user-not-found') {
          errorMessage = 'No user found with this email';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'Incorrect password';
        } else if (e.code == 'invalid-credential') {
          errorMessage = 'Invalid email or password';
        } else if (e.code == 'user-disabled') {
          errorMessage = 'This account has been disabled';
        } else if (e.code == 'too-many-requests') {
          errorMessage = 'Too many attempts. Please try again later';
        } else if (e.code == 'network-request-failed') {
          errorMessage = 'Network error. Check your connection';
        }
        
        if (mounted) {
          // Show animated error message
          final snackBar = SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          );
          
          ScaffoldMessenger.of(context)
            .showSnackBar(snackBar);
        }
      } catch (e) {
        // Handle generic errors
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sign in failed: $e'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        // Reset loading state if widget is still mounted
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = FirebaseAuthService.instance;
    
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor.withAlpha(204), // 0.8 * 255 = 204
                  AppTheme.secondaryColor.withAlpha(230), // 0.9 * 255 = 230
                ],
              ),
            ),
          ),
          
          // Background pattern - removed problematic image
          // Using a simple container with a subtle pattern effect
          Opacity(
            opacity: 0.05,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                backgroundBlendMode: BlendMode.lighten,
              ),
            ),
          ),
          
          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo and title
                      _buildHeader(),
                      
                      const SizedBox(height: 40),
                      
                      // Form
                      _buildForm(authService),
                      
                      const SizedBox(height: 24),
                      
                      // Sign up link
                      _buildSignUpLink(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // App logo - using icon instead of image asset
        Icon(
          Icons.account_balance_wallet,
          size: 80,
          color: Colors.white,
        )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: -20, end: 0, curve: Curves.easeOutQuad),
        
        const SizedBox(height: 16),
        
        // Welcome text
        Text(
          'Welcome Back',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        )
        .animate()
        .fadeIn(delay: 300.ms, duration: 600.ms),
        
        const SizedBox(height: 8),
        
        Text(
          'Sign in to continue to FinanceFlow',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withAlpha(204), // 0.8 * 255 = 204
          ),
        )
        .animate()
        .fadeIn(delay: 500.ms, duration: 600.ms),
      ],
    );
  }

  Widget _buildForm(FirebaseAuthService authService) {
    return Form(
      key: _formKey,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Email field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              )
              .animate()
              .fadeIn(delay: 600.ms, duration: 600.ms)
              .moveX(begin: -20, end: 0),
              
              const SizedBox(height: 16),
              
              // Password field
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              )
              .animate()
              .fadeIn(delay: 800.ms, duration: 600.ms)
              .moveX(begin: 20, end: 0),
              
              const SizedBox(height: 8),
              
              // Remember me and forgot password
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Remember me
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                      ),
                      Text('Remember me'),
                    ],
                  ),
                  
                  // Forgot password
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: Text('Forgot Password?'),
                  ),
                ],
              )
              .animate()
              .fadeIn(delay: 1000.ms, duration: 600.ms),
              
              const SizedBox(height: 24),
              
              // Sign in button
              EnhancedAnimations.modernHoverEffect(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 50),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.0,
                          ),
                        )
                      : const Text(
                          'SIGN IN',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              )
              .animate()
              .fadeIn(delay: 1200.ms, duration: 600.ms)
              .moveY(begin: 20, end: 0),
              
              // Test mode toggle
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Test Mode', style: TextStyle(color: Colors.white70)),
                    Switch(
                      value: _isTestMode,
                      onChanged: (value) {
                        setState(() {
                          _isTestMode = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              
              // Verification message for test mode
              if (_verificationMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _verificationMessage!.contains('Error') 
                        ? Colors.red.withValues(alpha: 0.2) 
                        : Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _verificationMessage!.contains('Error') 
                          ? Colors.red 
                          : Colors.green,
                      ),
                    ),
                    child: Text(
                      _verificationMessage!,
                      style: TextStyle(
                        color: _verificationMessage!.contains('Error') 
                          ? Colors.red 
                          : Colors.green,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ).animate().fadeIn(duration: 300.ms),
              
              const SizedBox(height: 24),
              
              // Social sign in
              _buildSocialSignIn(),
            ],
          ),
        ),
      )
      .animate()
      .fadeIn(delay: 400.ms, duration: 800.ms)
      .scaleXY(begin: 0.9, end: 1.0),
    );
  }

  Widget _buildSocialSignIn() {
    return Column(
      children: [
        Text(
          'Or sign in with',
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 16),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _socialButton(
              icon: 'assets/icons/google.png',
              onTap: () {
                // Implement Google sign in
              },
            ),
            const SizedBox(width: 16),
            _socialButton(
              icon: 'assets/icons/apple.png',
              onTap: () {
                // Implement Apple sign in
              },
            ),
            const SizedBox(width: 16),
            _socialButton(
              icon: 'assets/icons/facebook.png',
              onTap: () {
                // Implement Facebook sign in
              },
            ),
          ],
        ),
      ],
    )
    .animate()
    .fadeIn(delay: 1400.ms, duration: 600.ms);
  }

  Widget _socialButton({required String icon, required VoidCallback onTap}) {
    // Map icon strings to Flutter icons
    IconData iconData = Icons.public;  // Default icon
    if (icon.contains('google')) {
      iconData = Icons.search;  // Representing Google
    } else if (icon.contains('apple')) {
      iconData = Icons.apple;  // Apple icon
    } else if (icon.contains('facebook')) {
      iconData = Icons.facebook;  // Facebook icon
    }
    
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Icon(
              iconData,
              size: 24,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

    

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: TextStyle(color: Colors.white),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SignUpScreen(),
              ),
            );
          },
          child: Text(
            'Sign Up',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    )
    .animate()
    .fadeIn(delay: 1600.ms, duration: 600.ms);
  }
}
