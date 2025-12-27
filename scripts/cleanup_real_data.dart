import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logging/logging.dart';

/// Script to clean up ALL data for the current user from Firestore
/// This will delete all transactions, budgets, goals, etc. for a fresh start
Future<void> main() async {
  // Setup logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    stdout.writeln('${record.level.name}: ${record.message}');
  });
  
  final logger = Logger('FirestoreCleanup');
  
  logger.info('🧹 Starting COMPLETE Firestore cleanup for current user...');
  logger.warning('⚠️  WARNING: This will delete ALL your data!');
  logger.info('');
  
  // Ask for confirmation
  stdout.write('Are you sure you want to delete ALL data? Type "YES" to confirm: ');
  final confirmation = stdin.readLineSync();
  
  if (confirmation != 'YES') {
    logger.info('❌ Cleanup cancelled.');
    exit(0);
  }
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    
    final firestore = FirebaseFirestore.instance;
    
    // Use the specific user ID you found in Firestore
    final userId = 'J6IuuljCDydfafNnWYP8Qo3tnJ62';
    logger.info('📍 Cleaning ALL data for user: $userId');
    logger.info('');
    
    // Collections to clean
    final collections = [
      'transactions',
      'budgets', 
      'goals',
      'income_sources',
      'loans',
      'bills',
      'allowance_requests',
      'challenges',
      'family_members',
      'split_expenses',
      'scheduled_transactions',
    ];
    
    int totalDeleted = 0;
    
    for (final collectionName in collections) {
      logger.info('🗂️  Cleaning collection: $collectionName');
      
      // Query documents for the user
      final query = firestore
          .collection(collectionName)
          .where('userId', isEqualTo: userId);
      
      final snapshot = await query.get();
      
      if (snapshot.docs.isNotEmpty) {
        logger.info('   Found ${snapshot.docs.length} documents to delete');
        
        // Delete in batches to avoid timeout
        final batch = firestore.batch();
        int batchCount = 0;
        
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
          batchCount++;
          totalDeleted++;
          
          // Commit batch every 500 operations
          if (batchCount >= 500) {
            await batch.commit();
            logger.info('   Deleted batch of $batchCount documents');
            batchCount = 0;
          }
        }
        
        // Commit remaining documents
        if (batchCount > 0) {
          await batch.commit();
          logger.info('   Deleted final batch of $batchCount documents');
        }
      } else {
        logger.info('   No documents found');
      }
    }
    
    logger.info('');
    logger.info('✅ Complete cleanup finished!');
    logger.info('📊 Total documents deleted: $totalDeleted');
    logger.info('🎉 Your Firestore database is now completely clean!');
    logger.info('');
    logger.info('Next steps:');
    logger.info('1. Run your app to verify it starts with empty state');
    logger.info('2. Add your January 2025 sample data manually');
    logger.info('3. Test all features with real data');
    
  } catch (e) {
    logger.severe('❌ Error during cleanup: $e');
    exit(1);
  }
}
