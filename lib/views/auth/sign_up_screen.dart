import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/firestore_service.dart';
import '../../themes/app_theme.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  bool _isLoading = false;
  bool _isTestMode = false;
  String? _verificationMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate() && _agreeToTerms) {
      final authService = FirebaseAuthService.instance;
      final firestoreService = FirestoreService.instance;
      
      try {
        // Show loading state
        setState(() {
          _isLoading = true;
          _verificationMessage = null;
        });
        
        debugPrint('🔐 Starting user registration process...');
        
        // Attempt to register with Firebase
        final UserCredential userCredential = await authService.registerWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );
        
        debugPrint('✅ User registered successfully with UID: ${userCredential.user?.uid}');
        
        // Verify user data was saved to Firestore
        if (userCredential.user != null) {
          debugPrint('🔍 Verifying user data in Firestore...');
          
          // Wait a moment for Firestore to update
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Check if user profile exists in Firestore
          final userDoc = await firestoreService.getUserProfile(userCredential.user!.uid);
          
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            debugPrint('📊 User data found in Firestore: ${userData.toString()}');
            
            if (_isTestMode) {
              // For testing - show verification message instead of navigating
              setState(() {
                _isLoading = false;
                _verificationMessage = 'Registration successful! User data verified in Firestore.';
              });
              return;
            }
          } else {
            debugPrint('❌ User document not found in Firestore');
            if (_isTestMode) {
              setState(() {
                _isLoading = false;
                _verificationMessage = 'Error: User registered but data not found in Firestore';
              });
              return;
            }
          }
        }
        
        if (mounted && !_isTestMode) {
          // Navigate to dashboard on success
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      } on FirebaseAuthException catch (e) {
        // Handle specific Firebase Auth errors with user-friendly messages
        String errorMessage = 'An error occurred during registration';
        
        if (e.code == 'email-already-in-use') {
          errorMessage = 'This email is already in use';
        } else if (e.code == 'weak-password') {
          errorMessage = 'Password is too weak. Use at least 6 characters';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'Invalid email format';
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
          
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      } catch (e) {
        // Handle generic errors
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registration failed: $e'),
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
    } else if (!_agreeToTerms && mounted) {
      // Show error if terms not agreed to
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please agree to the Terms and Conditions'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = FirebaseAuthService.instance;
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  AppTheme.secondaryColor.withValues(alpha: 0.9),
                  AppTheme.primaryColor.withValues(alpha: 0.8),
                ],
              ),
            ),
          ),
          
          // Background pattern
          Opacity(
            opacity: 0.05,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/pattern.png'),
                  repeat: ImageRepeat.repeat,
                ),
              ),
            ),
          ),
          
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 
                    MediaQuery.of(context).padding.top - 
                    MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo and title
                        _buildHeader(),
                        
                        const SizedBox(height: 24),
                        
                        // Form
                        _buildForm(authService),
                        
                        const SizedBox(height: 16),
                        
                        // Test mode toggle (moved outside form)
                        _buildTestModeToggle(),
                        
                        const SizedBox(height: 16),
                        
                        // Sign in link
                        _buildSignInLink(),
                        
                        // Add some bottom spacing
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Back button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
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
        // App logo
        Image.asset(
          'assets/images/logo.png',
          height: 60,
        )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: -20, end: 0, curve: Curves.easeOutQuad),
        
        const SizedBox(height: 12),
        
        // Welcome text
        Text(
          'Create Account',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        )
        .animate()
        .fadeIn(delay: 300.ms, duration: 600.ms),
        
        const SizedBox(height: 6),
        
        Text(
          'Sign up to start managing your finances',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.8),
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
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              )
              .animate()
              .fadeIn(delay: 600.ms, duration: 600.ms)
              .moveX(begin: -20, end: 0),
              
              const SizedBox(height: 16),
              
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
              .fadeIn(delay: 800.ms, duration: 600.ms)
              .moveX(begin: 20, end: 0),
              
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
                    return 'Please enter a password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  return null;
                },
              )
              .animate()
              .fadeIn(delay: 1000.ms, duration: 600.ms)
              .moveX(begin: -20, end: 0),
              
              const SizedBox(height: 16),
              
              // Confirm password field
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              )
              .animate()
              .fadeIn(delay: 1200.ms, duration: 600.ms)
              .moveX(begin: 20, end: 0),
              
              const SizedBox(height: 12),
              
              // Terms and conditions
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _agreeToTerms,
                    onChanged: (value) {
                      setState(() {
                        _agreeToTerms = value ?? false;
                      });
                    },
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Text(
                        'I agree to the Terms and Conditions and Privacy Policy',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              )
              .animate()
              .fadeIn(delay: 1400.ms, duration: 600.ms),
              
              const SizedBox(height: 20),
              
              // Sign up button
              ElevatedButton(
                onPressed: _isLoading ? null : _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              ),
              
            ],
          ),
        ),
      ).animate()
      .fadeIn(delay: 400.ms, duration: 800.ms)
      .scaleXY(begin: 0.9, end: 1.0),
    );
  }

  Widget _buildTestModeToggle() {
    return Column(
      children: [
        // Test mode toggle
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Test Mode', style: TextStyle(fontSize: 14)),
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
        ),
        
        // Verification message for test mode
        if (_verificationMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
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
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  // Social login methods removed as they're not currently used

  Widget _buildSignInLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account? ",
          style: TextStyle(color: Colors.white),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(
            'Sign In',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    )
    .animate()
    .fadeIn(delay: 2000.ms, duration: 600.ms);
  }
}
