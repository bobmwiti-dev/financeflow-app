import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logging/logging.dart';

/// Script to clean up all mock/test data from Firestore
/// Run this script to remove all generated test data from your Firebase project
Future<void> main() async {
  // Setup logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    stdout.writeln('${record.level.name}: ${record.message}');
  });
  
  final logger = Logger('MockDataCleanup');
  
  logger.info('🧹 Starting Firestore cleanup...');
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    
    // Get current user or use demo user ID
    final userId = auth.currentUser?.uid ?? 'demo_user';
    logger.info('📍 Cleaning data for user: $userId');
    
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
      
      // Query documents for the current user
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
    
    // Also clean up any demo user data
    if (userId != 'demo_user') {
      logger.info('🧹 Cleaning demo user data...');
      for (final collectionName in collections) {
        final demoQuery = firestore
            .collection(collectionName)
            .where('userId', isEqualTo: 'demo_user');
        
        final demoSnapshot = await demoQuery.get();
        if (demoSnapshot.docs.isNotEmpty) {
          final batch = firestore.batch();
          for (final doc in demoSnapshot.docs) {
            batch.delete(doc.reference);
            totalDeleted++;
          }
          await batch.commit();
          logger.info('   Deleted ${demoSnapshot.docs.length} demo documents from $collectionName');
        }
      }
    }
    
    logger.info('✅ Cleanup completed!');
    logger.info('📊 Total documents deleted: $totalDeleted');
    logger.info('🎉 Your Firestore database is now clean and ready for real data!');
    
  } catch (e) {
    logger.severe('❌ Error during cleanup: $e');
    exit(1);
  }
}
