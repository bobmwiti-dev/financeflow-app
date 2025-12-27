import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logging/logging.dart';

// Import the generated Firebase options
import '../firebase_options.dart';

/// Main Firebase service class for FinanceFlow app
/// Manages Firebase initialization and provides access to Firebase services
class FirebaseService {
  // Singleton pattern
  static final FirebaseService _instance = FirebaseService._internal();
  static FirebaseService get instance => _instance;
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final _logger = Logger('FirebaseService');
  bool _initialized = false;

  // Firebase service instances
  late FirebaseAuth _auth;
  late FirebaseFirestore _firestore;
  late FirebaseStorage _storage;

  // Getters for Firebase services
  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;
  FirebaseStorage get storage => _storage;
  bool get isInitialized => _initialized;

  /// Initialize Firebase services
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _logger.info('Initializing Firebase...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _storage = FirebaseStorage.instance;

      // Configure Firestore settings
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      _initialized = true;
      _logger.info('Firebase initialized successfully');
    } catch (e) {
      _logger.severe('Error initializing Firebase: $e');
      rethrow;
    }
  }
}
