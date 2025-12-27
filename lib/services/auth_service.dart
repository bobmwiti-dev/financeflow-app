import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';
import '../models/user_model.dart';
import 'database_service.dart';
import 'firebase_auth_service.dart';

/// Authentication service for the FinanceFlow app
/// Handles user registration, login, and session management
class AuthService with ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  static AuthService get instance => _instance;
  
  final Logger _logger = Logger('AuthService');
  final DatabaseService _databaseService = DatabaseService.instance;
  
  User? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;
  
  // Getters
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  AuthService._internal();
  
  /// Initialize the auth service and check for existing session
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Load user session for all platforms
      await _loadUserSession();
    } catch (e) {
      _logger.warning('Error initializing auth service: $e');
      _error = 'Failed to initialize authentication service';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Register a new user
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Check if user already exists
      final existingUser = await _getUserByEmail(email);
      if (existingUser != null) {
        _error = 'Email already in use';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      // Create new user
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch, // Generate a unique ID
        email: email,
        name: name,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        preferences: {},
      );
      
      // Store user in database
      _logger.info('Registering new user: $email');
      await _databaseService.insertUser(user, password);
      
      // Auto login after registration
      return await login(email: email, password: password);
    } catch (e) {
      _logger.warning('Registration error: $e');
      _error = 'Registration failed. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /* Duplicate erroneous block commented out
/// Login with email and password
    try {
      final updatedUser = User(
        id: _currentUser!.id,
        email: email,
        name: name,
        createdAt: _currentUser!.createdAt,
        lastLogin: DateTime.now(),
        preferences: _currentUser!.preferences,
      );
      await _databaseService.updateUser(updatedUser);
      _currentUser = updatedUser;
      _logger.info('Local profile updated');
      return true;
    } catch (e) {
      _logger.warning('Error updating profile: $e');
      _error = 'Failed to update profile';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  */
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _logger.info('Login attempt: $email');
      final user = await _authenticateUser(email, password);
      
      if (user != null) {
        _currentUser = user;
        _isAuthenticated = true;
        
        await _saveUserSession(user);
        _logger.info('Login successful: $email');
        
        return true;
      } else {
        _error = 'Invalid email or password';
        _logger.warning('Login failed: Invalid credentials for $email');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _logger.warning('Login error: $e');
      _error = 'Login failed. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Logout current user
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Sign out from Firebase
      await FirebaseAuthService.instance.signOut();

      // Clear local session
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clear all shared preferences for logout
      
      _currentUser = null;
      _isAuthenticated = false;
      _logger.info('User logged out from both Firebase and local session.');
    } catch (e) {
      _logger.warning('Logout error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Reset password for a user
  Future<bool> resetPassword({required String email}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final user = await _getUserByEmail(email);
      
      if (user == null) {
        _error = 'Email not found';
        return false;
      }
      
      // In a real app, send password reset email
      // For this demo, we'll just log it
      _logger.info('Password reset requested for: $email');
      
      return true;
    } catch (e) {
      _logger.warning('Password reset error: $e');
      _error = 'Password reset failed. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Update user profile
  Future<bool> updateProfile({
    required String name,
    String? email,
    String? currentPassword,
    String? newPassword,
    String? phoneNumber,
    String? address,
    String? occupation,
    DateTime? dateOfBirth,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedUser = _currentUser!.copyWith(
        name: name,
        email: email,
        phoneNumber: phoneNumber,
        address: address,
        occupation: occupation,
        dateOfBirth: dateOfBirth,
      );
      
      // Update password if provided
      if (currentPassword != null && newPassword != null) {
        final isPasswordValid = await _validatePassword(_currentUser!.email, currentPassword);
        
        if (!isPasswordValid) {
          _error = 'Current password is incorrect';
          return false;
        }
        
        await _databaseService.updateUserPassword(_currentUser!.id, newPassword);
      }
      
      // Update user in database
      await _databaseService.updateUser(updatedUser);
      
      // Update current user
      _currentUser = updatedUser;
      
      // Update session
      await _saveUserSession(updatedUser);
      
      return true;
    } catch (e) {
      _logger.warning('Profile update error: $e');
      _error = 'Profile update failed. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Private methods
  
  Future<User?> _getUserByEmail(String email) async {
    try {
      _logger.info('Getting user by email: $email');
      return await _databaseService.getUserByEmail(email);
    } catch (e) {
      _logger.warning('Error getting user by email: $e');
      return null;
    }
  }
  
  Future<User?> _authenticateUser(String email, String password) async {
    try {
      _logger.info('Authenticating user: $email');
      final user = await _databaseService.authenticateUser(email, password);
      
      if (user != null) {
        _logger.info('Authentication successful for: $email');
        // Update last login
        final updatedUser = User(
          id: user.id,
          email: user.email,
          name: user.name,
          createdAt: user.createdAt,
          lastLogin: DateTime.now(),
          preferences: user.preferences,
        );
        
        await _databaseService.updateUser(updatedUser);
        return updatedUser;
      }
      
      return null;
    } catch (e) {
      _logger.warning('Authentication error: $e');
      return null;
    }
  }
  
  Future<bool> _validatePassword(String email, String password) async {
    try {
      final user = await _databaseService.authenticateUser(email, password);
      return user != null;
    } catch (e) {
      _logger.warning('Password validation error: $e');
      return false;
    }
  }
  
  Future<void> _saveUserSession(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_id', user.id);
      await prefs.setString('user_email', user.email);
      await prefs.setString('user_name', user.name);
      await prefs.setString('session_token', _generateSessionToken());
    } catch (e) {
      _logger.warning('Error saving user session: $e');
    }
  }
  
  Future<void> _loadUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      
      if (userId != null) {
        final user = await _databaseService.getUserById(userId);
        
        if (user != null) {
          _currentUser = user;
          _isAuthenticated = true;
        } else {
          // Clear invalid session
          await prefs.remove('user_id');
          await prefs.remove('user_email');
          await prefs.remove('user_name');
          await prefs.remove('session_token');
        }
      }
    } catch (e) {
      _logger.warning('Error loading user session: $e');
    }
  }
  
  String _generateSessionToken() {
    // In a real app, use a more secure method
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
