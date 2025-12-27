import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logging/logging.dart';

/// Script to clean up the remaining 3 collections: budgets, income_sources, transactions
/// This will delete all documents with your user ID from these collections
Future<void> main() async {
  // Setup logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    stdout.writeln('${record.level.name}: ${record.message}');
  });
  
  final logger = Logger('RemainingCollectionsCleanup');
  
  logger.info('🧹 Cleaning up remaining collections...');
  logger.info('📍 Target collections: budgets, income_sources, transactions');
  logger.info('👤 User ID: J6IuuljCDydfafNnWYP8Qo3tnJ62');
  logger.info('');
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    
    final firestore = FirebaseFirestore.instance;
    
    // Your specific user ID
    final userId = 'J6IuuljCDydfafNnWYP8Qo3tnJ62';
    
    // Only the remaining collections to clean
    final collections = [
      'budgets',
      'income_sources', 
      'transactions',
    ];
    
    int totalDeleted = 0;
    
    for (final collectionName in collections) {
      logger.info('🗂️  Cleaning collection: $collectionName');
      
      // Query documents for your user ID
      final query = firestore
          .collection(collectionName)
          .where('userId', isEqualTo: userId);
      
      final snapshot = await query.get();
      
      if (snapshot.docs.isNotEmpty) {
        logger.info('   📄 Found ${snapshot.docs.length} documents to delete');
        
        // Delete in batches
        final batch = firestore.batch();
        int batchCount = 0;
        
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
          batchCount++;
          totalDeleted++;
          
          // Show progress for large collections
          if (batchCount % 10 == 0) {
            logger.info('   ⏳ Queued $batchCount documents for deletion...');
          }
          
          // Commit batch every 500 operations (Firestore limit)
          if (batchCount >= 500) {
            await batch.commit();
            logger.info('   ✅ Deleted batch of $batchCount documents');
            batchCount = 0;
          }
        }
        
        // Commit remaining documents
        if (batchCount > 0) {
          await batch.commit();
          logger.info('   ✅ Deleted final batch of $batchCount documents');
        }
        
        logger.info('   🎯 Collection $collectionName cleaned successfully!');
      } else {
        logger.info('   ℹ️  No documents found in $collectionName');
      }
      logger.info('');
    }
    
    logger.info('🎉 CLEANUP COMPLETED!');
    logger.info('📊 Total documents deleted: $totalDeleted');
    logger.info('');
    logger.info('✅ All remaining collections are now clean:');
    logger.info('   - budgets: cleaned');
    logger.info('   - income_sources: cleaned');
    logger.info('   - transactions: cleaned');
    logger.info('');
    logger.info('🚀 Your Firestore database is now completely empty!');
    logger.info('📱 Next: Run your app to see clean empty states');
    
  } catch (e) {
    logger.severe('❌ Error during cleanup: $e');
    logger.info('💡 Make sure your Firebase project is properly configured');
    exit(1);
  }
}
