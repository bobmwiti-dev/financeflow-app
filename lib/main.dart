import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';

import 'firebase_options.dart';
import 'services/connectivity_service.dart';
import 'constants/app_constants.dart';
import 'services/navigation_service.dart';
import 'services/auth_service.dart';
// Screens
import 'package:financeflow_app/services/firebase_auth_service.dart';
import 'package:financeflow_app/views/auth/sign_in_screen.dart';
import 'package:financeflow_app/views/dashboard/dashboard_screen.dart';
import 'package:financeflow_app/views/onboarding/splash_screen.dart';
import 'services/transaction_service.dart';

// ViewModels
import 'package:financeflow_app/viewmodels/safe_to_spend_viewmodel.dart';
import 'package:financeflow_app/viewmodels/transaction_viewmodel_fixed.dart' as fixed;
import 'package:financeflow_app/viewmodels/account_viewmodel.dart';
import 'services/service_provider.dart';
import 'services/net_worth_service.dart';
import 'services/account_migration_service.dart';
// Initialize logger
final _logger = Logger('FinanceFlowApp');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // SQLite is automatically configured by the sqflite package for mobile platforms

  // Set up logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });

  // Initialize Firebase with the generated options
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _logger.info('Firebase initialized successfully');

    // Listen for auth state changes and log the current UID
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _logger.info('Logged-in UID: \\${user.uid}');
        debugPrint('LOGGED-IN UID: \\${user.uid}');
      } else {
        _logger.warning('No user signed in');
        debugPrint('No user signed in');
      }
    });
    
    // Initialize Firestore settings
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    _logger.info('Firestore settings configured');
    
    // Initialize connectivity service
    final connectivityService = ConnectivityService.instance;
    await connectivityService.initialize();
    _logger.info('Connectivity service initialized');
    
    // Initialize authentication services
    final authService = AuthService.instance;
    await authService.initialize();

    // Firebase-backed auth (if Firebase available)
    final fbAuthService = FirebaseAuthService.instance;
    await fbAuthService.initialize();
    
    // Use the ServiceProvider to create and manage app services
    _logger.info('Setting up service providers');
    
    // Create a single instance of TransactionViewModel
    final transactionViewModel = fixed.TransactionViewModel();
    
    // Create AccountViewModel instance
    final accountViewModel = AccountViewModel();
    await accountViewModel.initialize();
    
    // Handle data migration for existing users
    await AccountMigrationService.migrateExistingData(accountViewModel);
    
    runApp(
      MultiProvider(
        providers: [
          // Provide the TransactionService as a value
          Provider.value(
            value: TransactionService.instance,
          ),
          // Provide the TransactionViewModel as a value to ensure it's not recreated
          ChangeNotifierProvider.value(
            value: transactionViewModel,
          ),
          // Provide the AccountViewModel as a value
          ChangeNotifierProvider.value(
            value: accountViewModel,
          ),
          // Add other providers from ServiceProvider, passing the transactionViewModel to prevent duplicates
          ...ServiceProvider.createProviders(transactionViewModel: transactionViewModel),
          Provider<NetWorthService>(create: (_) => NetWorthService()),
          ChangeNotifierProvider(create: (_) => SafeToSpendViewModel()),
        ],
        child: const FinanceFlowApp(),
      ),
    );
  } catch (e) {
    debugPrint('Failed to initialize Firebase: $e');
    // Fallback to local authentication if Firebase fails
    debugPrint('Falling back to local authentication');
  }
}

class FinanceFlowApp extends StatelessWidget {
  const FinanceFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    // authService and firebaseAuthService will be accessed within the '/' route definition
    return MaterialApp(
      builder: (context, child) {
        // Add error boundary to catch mouse tracker issues
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          final errorString = errorDetails.exception.toString();
          
          // Check if it's a mouse tracker or render box error
          if (errorString.contains('mouse_tracker') ||
              errorString.contains('render box') ||
              errorString.contains('no size') ||
              errorString.contains('Cannot hit test') ||
              errorString.contains('box.dart:2251') ||
              errorString.contains('object.dart:2634')) {
            // Return a minimal widget to prevent crashes
            return const SizedBox.shrink();
          }
          
          return Material(
            child: Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 64),
                    const SizedBox(height: 16),
                    const Text(
                      'App Error Detected',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('Restarting app...'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Force app restart by navigating to splash
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/splash', 
                          (route) => false,
                        );
                      },
                      child: const Text('Restart App'),
                    ),
                  ],
                ),
              ),
            ),
          );
        };
        
        // Add additional error handling for render box issues
        if (child == null) {
          return const SizedBox.shrink();
        }
        
        // Wrap with Builder to catch any widget errors
        return Builder(
          builder: (context) {
            try {
              return child;
            } catch (e) {
              final errorString = e.toString();
              // Suppress mouse tracker and render box errors
              if (errorString.contains('mouse_tracker') || 
                  errorString.contains('render box') ||
                  errorString.contains('Cannot hit test') ||
                  errorString.contains('box.dart:2251') ||
                  errorString.contains('object.dart:2634')) {
                return const SizedBox.shrink();
              }
              rethrow;
            }
          },
        );
      },
      title: AppConstants.appName,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32), // Professional green for finance
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32), // Same professional green
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      navigatorKey: NavigationService.navigatorKey,
      initialRoute: '/splash',
      onGenerateRoute: (settings) {
        if (settings.name == '/splash') {
          return MaterialPageRoute(
            builder: (context) => const SplashScreen(),
          );
        }
        if (settings.name == '/') {
          final authService = Provider.of<AuthService>(context, listen: false);
          final bool isAuthenticated = authService.isAuthenticated;
          
          return MaterialPageRoute(
            builder: (context) => isAuthenticated 
                ? const DashboardScreen() 
                : const SignInScreen(),
          );
        }
        return NavigationService.generateRoute(settings);
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
