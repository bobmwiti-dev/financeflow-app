import 'package:flutter_test/flutter_test.dart';
import 'package:financeflow_app/services/database_service.dart';
import 'package:financeflow_app/models/user_model.dart';
import 'package:logging/logging.dart';

void main() {
  // Set up logging for tests
  final logger = Logger('DatabaseTests');
  
  // Configure logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // This will only log during tests, not production
    // ignore: avoid_print
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  
  group('Database Service Tests', () {
    late DatabaseService databaseService;
    
    setUp(() {
      databaseService = DatabaseService.instance;
    });
    
    test('User Registration Test', () async {
      // Create a test user
      final testUser = User(
        id: DateTime.now().millisecondsSinceEpoch,
        email: 'test_user_${DateTime.now().millisecondsSinceEpoch}@example.com',
        name: 'Test User',
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        preferences: {},
      );
      
      // Test inserting the user
      try {
        final result = await databaseService.insertUser(testUser, 'password123');
        logger.info('User inserted with result: $result');
        expect(result, isNotNull);
        expect(result > 0, true);
      } catch (e) {
        fail('User insertion failed with error: $e');
      }
      
      // Test retrieving the user
      try {
        final retrievedUser = await databaseService.getUserByEmail(testUser.email);
        logger.info('Retrieved user: ${retrievedUser?.name}');
        expect(retrievedUser, isNotNull);
        expect(retrievedUser?.email, equals(testUser.email));
        expect(retrievedUser?.name, equals(testUser.name));
      } catch (e) {
        fail('User retrieval failed with error: $e');
      }
    });
  });
}
