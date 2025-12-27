import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logging/logging.dart';
import 'package:financeflow_app/firebase_options.dart';
import 'package:financeflow_app/services/mock_data_service.dart';

final logger = Logger('DataCleanupAndRegenerate');

void main() async {
  // Set up logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // Using print for script output - acceptable for standalone scripts
    // ignore: avoid_print
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    logger.info('Firebase initialized successfully');

    // Check if user is authenticated
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      logger.severe('No authenticated user found. Please sign in first.');
      exit(1);
    }

    logger.info('Authenticated user: ${user.uid}');
    
    // Clean up existing data
    await cleanupExistingData(user.uid);
    
    // Regenerate clean 2025 data
    await regenerate2025Data();
    
    logger.info('Data cleanup and regeneration completed successfully!');
    
  } catch (e) {
    logger.severe('Error during cleanup and regeneration: $e');
    exit(1);
  }
}

Future<void> cleanupExistingData(String userId) async {
  logger.info('Starting cleanup of existing inconsistent data...');
  
  final firestore = FirebaseFirestore.instance;
  final batch = firestore.batch();
  
  try {
    // Clean up budgets with mixed years
    final budgetsQuery = await firestore
        .collection('budgets')
        .where('userId', isEqualTo: userId)
        .get();
    
    logger.info('Found ${budgetsQuery.docs.length} budget documents to clean');
    
    for (final doc in budgetsQuery.docs) {
      batch.delete(doc.reference);
    }
    
    // Clean up transactions
    final transactionsQuery = await firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .get();
    
    logger.info('Found ${transactionsQuery.docs.length} transaction documents to clean');
    
    for (final doc in transactionsQuery.docs) {
      batch.delete(doc.reference);
    }
    
    // Clean up income sources
    final incomeQuery = await firestore
        .collection('income_sources')
        .where('userId', isEqualTo: userId)
        .get();
    
    logger.info('Found ${incomeQuery.docs.length} income documents to clean');
    
    for (final doc in incomeQuery.docs) {
      batch.delete(doc.reference);
    }
    
    // Clean up loans
    final loansQuery = await firestore
        .collection('loans')
        .where('userId', isEqualTo: userId)
        .get();
    
    logger.info('Found ${loansQuery.docs.length} loan documents to clean');
    
    for (final doc in loansQuery.docs) {
      batch.delete(doc.reference);
    }
    
    // Execute batch delete
    await batch.commit();
    logger.info('Successfully cleaned up existing data');
    
  } catch (e) {
    logger.severe('Error during cleanup: $e');
    rethrow;
  }
}

Future<void> regenerate2025Data() async {
  logger.info('Starting regeneration of clean 2025 mock data...');
  
  try {
    final success = await MockDataService.generateMockData();
    
    if (success) {
      logger.info('Successfully generated clean 2025 mock data');
    } else {
      logger.severe('Failed to generate mock data');
      throw Exception('Mock data generation failed');
    }
    
  } catch (e) {
    logger.severe('Error during data regeneration: $e');
    rethrow;
  }
}
