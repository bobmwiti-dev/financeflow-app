import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_screen.dart';
import '../auth/sign_in_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../../themes/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with WidgetsBindingObserver {
  String _statusMessage = 'Initializing...';
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _isDisposed = true;
    }
  }

  Future<void> _initializeApp() async {
    try {
      // Use Timer instead of async/await to avoid context issues
      Timer(const Duration(milliseconds: 1500), () {
        if (!mounted || _isDisposed) return;
        _updateStatusAndContinue();
      });
    } catch (e) {
      // Fallback to onboarding on any error
      if (!mounted || _isDisposed) return;
      Timer(const Duration(milliseconds: 500), () {
        if (!mounted || _isDisposed) return;
        _navigateToOnboarding();
      });
    }
  }
  
  void _updateStatusAndContinue() {
    if (!mounted || _isDisposed) return;
    
    setState(() {
      _statusMessage = 'Checking authentication...';
    });
    
    // Use Timer for the next step to avoid async context issues
    Timer(const Duration(milliseconds: 500), () {
      if (!mounted || _isDisposed) return;
      _checkAuthenticationAndNavigate();
    });
  }
  
  void _checkAuthenticationAndNavigate() async {
    if (!mounted || _isDisposed) return;
    
    try {
      // Capture navigator before any async operations
      final navigator = Navigator.of(context);
      
      // Check if user is first time (simplified)
      final prefs = await SharedPreferences.getInstance();
      final isFirstTime = prefs.getBool('is_first_time') ?? true;
      
      if (!mounted || _isDisposed) return;
      
      if (isFirstTime) {
        // First time user - show onboarding
        await prefs.setBool('is_first_time', false);
        if (!mounted || _isDisposed) return;
        navigator.pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      } else {
        // Simplified: just check if user exists, skip complex auth logic
        final user = FirebaseAuth.instance.currentUser;
        if (!mounted || _isDisposed) return;
        
        if (user != null) {
          // User exists - go to dashboard
          navigator.pushReplacement(
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        } else {
          // No user - go to sign in
          navigator.pushReplacement(
            MaterialPageRoute(builder: (context) => const SignInScreen()),
          );
        }
      }
    } catch (e) {
      // Fallback to onboarding on any error
      if (!mounted || _isDisposed) return;
      _navigateToOnboarding();
    }
  }
  
  void _navigateToOnboarding() {
    if (!mounted || _isDisposed) return;
    
    final navigator = Navigator.of(context);
    navigator.pushReplacement(
      MaterialPageRoute(builder: (context) => const OnboardingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              AppTheme.primaryColor,
              AppTheme.secondaryColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Main content
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App logo (simplified, no animations)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.savings,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // App name (simplified, no animations)
                      const Text(
                        'FinanceFlow',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Tagline (simplified, no animations)
                      Text(
                        'Your Smart Finance Companion',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Loading indicator and status
              Padding(
                padding: const EdgeInsets.only(bottom: 48.0),
                child: Column(
                  children: [
                    // Loading indicator (simplified, no animations)
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Status message (simplified, no animations)
                    Text(
                      _statusMessage,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
