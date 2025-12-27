import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import '../models/transaction_model.dart' as app_models;
import '../models/income_source_model.dart';
import '../models/mpesa_sms_model.dart';
import 'sms_reader_service.dart';
import 'mpesa_sms_parser.dart';
import 'firestore_service.dart';

/// Service for importing M-Pesa transactions from SMS
class MpesaImportService {
  static const String _logName = 'MpesaImportService';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Enhanced merchant categorization database
  static final Map<String, String> _merchantCategories = {
    // Retail & Shopping
    'NAIVAS': 'Groceries',
    'TUSKYS': 'Groceries',
    'CARREFOUR': 'Groceries',
    'QUICKMART': 'Groceries',
    
    // Dining & Food
    'JAVA HOUSE': 'Dining',
    'KFC': 'Dining',
    'PIZZA HUT': 'Dining',
    'SUBWAY': 'Dining',
    
    // Utilities
    'KPLC': 'Utilities',
    'NAIROBI WATER': 'Utilities',
    'GOTV': 'Entertainment',
    'DSTV': 'Entertainment',
    
    // Transport
    'UBER': 'Transport',
    'BOLT': 'Transport',
    'MATATU': 'Transport',
    
    // Education
    'SCHOOL FEES': 'Education',
    'UNIVERSITY': 'Education',
    
    // Healthcare
    'HOSPITAL': 'Healthcare',
    'PHARMACY': 'Healthcare',
    
    // Financial Services
    'EQUITY BANK': 'Banking',
    'KCB': 'Banking',
    'COOP BANK': 'Banking',
  };

  /// Import M-Pesa transactions from SMS
  static Future<MpesaImportResult> importTransactions({
    DateTime? since,
    int maxDays = 30,
    bool categorizeAutomatically = true,
    bool skipDuplicates = true,
  }) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      developer.log('Starting M-Pesa import for user: $userId', name: _logName);

      // Check SMS permission
      if (!await SmsReaderService.hasPermission()) {
        bool granted = await SmsReaderService.requestPermission();
        if (!granted) {
          throw Exception('SMS permission not granted');
        }
      }

      // Get latest M-Pesa transactions
      List<MpesaSmsTransaction> mpesaTransactions = await SmsReaderService.getLatestMpesaTransactions(
        lastImportDate: since,
        maxDays: maxDays,
      );

      developer.log('Found ${mpesaTransactions.length} M-Pesa transactions to process', name: _logName);

      if (mpesaTransactions.isEmpty) {
        return MpesaImportResult(
          success: true,
          message: 'No new M-Pesa transactions found',
          totalFound: 0,
          imported: 0,
          skipped: 0,
          failed: 0,
        );
      }

      // Remove duplicates if requested
      if (skipDuplicates) {
        mpesaTransactions = await _removeDuplicates(mpesaTransactions, userId);
      }

      int imported = 0;
      int skipped = 0;
      int failed = 0;
      List<String> errors = [];

      // Process each transaction
      for (MpesaSmsTransaction mpesaTransaction in mpesaTransactions) {
        try {
          bool success = await _importSingleTransaction(
            mpesaTransaction, 
            userId, 
            categorizeAutomatically,
          );
          
          if (success) {
            imported++;
          } else {
            skipped++;
          }
        } catch (e) {
          failed++;
          errors.add('Failed to import ${mpesaTransaction.mpesaCode}: $e');
          developer.log('Failed to import transaction ${mpesaTransaction.mpesaCode}: $e', name: _logName);
        }
      }

      // Update last import date
      await _updateLastImportDate(userId);

      developer.log('Import completed: $imported imported, $skipped skipped, $failed failed', name: _logName);

      return MpesaImportResult(
        success: true,
        message: 'Import completed successfully',
        totalFound: mpesaTransactions.length,
        imported: imported,
        skipped: skipped,
        failed: failed,
        errors: errors,
      );

    } catch (e) {
      developer.log('Error during M-Pesa import: $e', name: _logName);
      return MpesaImportResult(
        success: false,
        message: 'Import failed: $e',
        totalFound: 0,
        imported: 0,
        skipped: 0,
        failed: 0,
        errors: [e.toString()],
      );
    }
  }

  /// Import a single M-Pesa transaction
  static Future<bool> _importSingleTransaction(
    MpesaSmsTransaction mpesaTransaction,
    String userId,
    bool categorizeAutomatically,
  ) async {
    try {
      // Save M-Pesa transaction record
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('mpesa_transactions')
          .doc(mpesaTransaction.mpesaCode)
          .set(mpesaTransaction.toMap());

      // Convert to app transaction or income source
      if (mpesaTransaction.isExpense) {
        // Create expense transaction
        app_models.Transaction transaction = _convertToTransaction(mpesaTransaction, userId, accountId: 'default_mpesa_account');
        
        // Auto-categorize if enabled
        if (categorizeAutomatically) {
          String? suggestedCategory = MpesaSmsParser.suggestCategory(mpesaTransaction);
          if (suggestedCategory != null) {
            transaction = transaction.copyWith(category: suggestedCategory);
          }
        }

        // Save transaction
        await FirestoreService.instance.addTransaction(transaction);
        
        // Update M-Pesa record with imported transaction ID
        await _updateMpesaTransactionImported(mpesaTransaction.mpesaCode, userId, transaction.id);
        
        developer.log('Imported expense transaction: ${transaction.title}', name: _logName);
        
      } else if (mpesaTransaction.isIncome) {
        // Refine income classification
        final incomeDecision = await _classifyIncome(mpesaTransaction, userId);

        if (incomeDecision.action == _IncomeAction.skip) {
          developer.log('Skipping income import for ${mpesaTransaction.mpesaCode} (${incomeDecision.reason})', name: _logName);
          return true; // treated as processed but skipped
        }

        if (incomeDecision.action == _IncomeAction.transfer) {
          // Treat as transfer transaction, not income
          final transaction = app_models.Transaction(
            id: '',
            userId: userId,
            title: mpesaTransaction.description,
            amount: mpesaTransaction.amount,
            category: 'Transfer',
            date: mpesaTransaction.transactionDate,
            type: app_models.TransactionType.transfer,
            description: 'Imported from M-Pesa SMS (${mpesaTransaction.mpesaCode})',
            accountId: 'default_mpesa_account',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            notes: 'M-Pesa Code: ${mpesaTransaction.mpesaCode}${mpesaTransaction.sender != null ? ', From: ${mpesaTransaction.sender}' : ''}',
          );
          await FirestoreService.instance.addTransaction(transaction);
          await _updateMpesaTransactionImported(mpesaTransaction.mpesaCode, userId, transaction.id);
          developer.log('Imported transfer (self) transaction: ${transaction.title}', name: _logName);
          return true;
        }

        // Create income source with refined type
        final incomeType = incomeDecision.incomeTypeLabel ?? 'M-Pesa Transfer';
        IncomeSource incomeSource = _convertToIncomeSource(mpesaTransaction, userId, accountId: 'default_mpesa_account', overrideType: incomeType);
        await FirestoreService.instance.addIncomeSource(incomeSource);
        await _updateMpesaTransactionImported(mpesaTransaction.mpesaCode, userId, incomeSource.id);
        developer.log('Imported income source: ${incomeSource.name} [$incomeType]', name: _logName);
      }

      return true;
    } catch (e) {
      developer.log('Error importing single transaction: $e', name: _logName);
      return false;
    }
  }

  /// Convert M-Pesa transaction to app Transaction
  static app_models.Transaction _convertToTransaction(MpesaSmsTransaction mpesaTransaction, String userId, {String? accountId}) {
    return app_models.Transaction(
      id: '', // Will be generated by Firestore
      userId: userId,
      title: mpesaTransaction.description,
      amount: mpesaTransaction.amount,
      category: MpesaSmsParser.suggestCategory(mpesaTransaction) ?? 'Other',
      date: mpesaTransaction.transactionDate,
      type: app_models.TransactionType.expense,
      description: 'Imported from M-Pesa SMS (${mpesaTransaction.mpesaCode})',
      accountId: accountId ?? 'default_mpesa_account',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      notes: 'M-Pesa Code: ${mpesaTransaction.mpesaCode}${mpesaTransaction.recipient != null ? ', To: ${mpesaTransaction.recipient}' : ''}',
    );
  }

  /// Convert M-Pesa transaction to IncomeSource
  static IncomeSource _convertToIncomeSource(MpesaSmsTransaction mpesaTransaction, String userId, {String? accountId, String? overrideType}) {
    return IncomeSource(
      id: '', // Will be generated by Firestore
      name: mpesaTransaction.description,
      type: overrideType ?? 'M-Pesa Transfer',
      amount: mpesaTransaction.amount,
      date: mpesaTransaction.transactionDate,
      isRecurring: false,
      frequency: 'One-time',
      accountId: accountId ?? 'default_mpesa_account',
      notes: 'M-Pesa Code: ${mpesaTransaction.mpesaCode}${mpesaTransaction.sender != null ? ', From: ${mpesaTransaction.sender}' : ''}',
    );
  }

  /// Income refinement: decide if a received M-Pesa should be imported as income, transfer, or skipped
  static Future<_IncomeDecision> _classifyIncome(MpesaSmsTransaction t, String userId) async {
    // Reversal or deposit should not be counted as income
    if (t.type == MpesaTransactionType.reversal) {
      return _IncomeDecision.skip('Reversal');
    }
    if (t.type == MpesaTransactionType.deposit) {
      return _IncomeDecision.skip('Agent cash deposit');
    }

    final config = await _getImportConfig();
    final sms = t.originalSms.toLowerCase();

    // Check for loan/credit keywords (exclude from income)
    if (config.containsLoanKeywords(sms) ||
        config.containsExcludedKeywords(sms)) {
      return _IncomeDecision.skip('Loan/Credit');
    }

    // Check for salary keywords (mark as salary income)
    if (config.containsSalaryKeywords(sms)) {
      return _IncomeDecision.incomeType('Salary');
    }

    // Self-transfer exclusion using user-configured excluded/self numbers
    final senderPhone = (t.metadata?['senderPhone'] as String?) ?? t.sender ?? '';
    if (config.isNumberExcluded(senderPhone)) {
      return _IncomeDecision.transfer();
    }

    // Salary keywords
    const salaryKeywords = ['salary', 'payroll', 'wages', 'stipend'];
    if (salaryKeywords.any((k) => sms.contains(k))) {
      return _IncomeDecision.incomeType('Salary');
    }

    // Default: treat as normal M-Pesa transfer income
    return _IncomeDecision.incomeType('M-Pesa Transfer');
  }

  /// Get or create default M-Pesa import configuration
  static Future<MpesaImportConfig> _getImportConfig() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return MpesaImportConfig.defaultKenya();
      
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('mpesa_import')
          .get();
      
      if (doc.exists) {
        return MpesaImportConfig.fromMap(doc.data()!);
      } else {
        // Create default config
        final defaultConfig = MpesaImportConfig.defaultKenya();
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('settings')
            .doc('mpesa_import')
            .set(defaultConfig.toMap());
        return defaultConfig;
      }
    } catch (e) {
      Logger(_logName).warning('Failed to load import config: $e');
      return MpesaImportConfig.defaultKenya();
    }
  }

  /// Update M-Pesa transaction as imported
  static Future<void> _updateMpesaTransactionImported(String mpesaCode, String userId, String? importedId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('mpesa_transactions')
          .doc(mpesaCode)
          .update({
        'isImported': true,
        'importedTransactionId': importedId,
        'importedAt': Timestamp.now(),
      });
      
      developer.log('Updated M-Pesa transaction as imported: $mpesaCode', name: _logName);
    } catch (e) {
      developer.log('Error updating M-Pesa transaction: $e', name: _logName);
    }
  }

  /// Remove duplicate transactions
  static Future<List<MpesaSmsTransaction>> _removeDuplicates(
    List<MpesaSmsTransaction> transactions, 
    String userId,
  ) async {
    try {
      // Get existing M-Pesa codes from Firestore
      QuerySnapshot existingSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('mpesa_transactions')
          .get();

      Set<String> existingCodes = existingSnapshot.docs
          .map((doc) => doc.id)
          .toSet();

      // Filter out duplicates
      List<MpesaSmsTransaction> uniqueTransactions = transactions
          .where((transaction) => !existingCodes.contains(transaction.mpesaCode))
          .toList();

      int duplicatesRemoved = transactions.length - uniqueTransactions.length;
      if (duplicatesRemoved > 0) {
        developer.log('Removed $duplicatesRemoved duplicate transactions', name: _logName);
      }

      return uniqueTransactions;
    } catch (e) {
      developer.log('Error removing duplicates: $e', name: _logName);
      return transactions; // Return original list if error
    }
  }

  /// Update last import date
  static Future<void> _updateLastImportDate(String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('mpesa_import')
          .set({
        'lastImportDate': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));
      
      developer.log('Updated last import date', name: _logName);
    } catch (e) {
      developer.log('Error updating last import date: $e', name: _logName);
    }
  }

  /// Get M-Pesa import configuration
  static Future<MpesaImportConfig> getImportConfig() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        return MpesaImportConfig();
      }

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('mpesa_import')
          .get();

      if (doc.exists) {
        return MpesaImportConfig.fromMap(doc.data() as Map<String, dynamic>);
      } else {
        return MpesaImportConfig();
      }
    } catch (e) {
      developer.log('Error getting import config: $e', name: _logName);
      return MpesaImportConfig();
    }
  }

  /// Save M-Pesa import configuration
  static Future<void> saveImportConfig(MpesaImportConfig config) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('mpesa_import')
          .set(config.toMap(), SetOptions(merge: true));
      
      developer.log('Saved import config', name: _logName);
    } catch (e) {
      developer.log('Error saving import config: $e', name: _logName);
      rethrow;
    }
  }

  /// Get M-Pesa transaction history
  static Future<List<MpesaSmsTransaction>> getMpesaTransactionHistory({
    int limit = 50,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        return [];
      }

      Query query = _firestore
          .collection('users')
          .doc(userId)
          .collection('mpesa_transactions')
          .orderBy('transactionDate', descending: true);

      if (startDate != null) {
        query = query.where('transactionDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('transactionDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      QuerySnapshot snapshot = await query.limit(limit).get();

      return snapshot.docs
          .map((doc) => MpesaSmsTransaction.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      developer.log('Error getting M-Pesa transaction history: $e', name: _logName);
      return [];
    }
  }

  /// Get import statistics
  static Future<Map<String, dynamic>> getImportStatistics() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        return {};
      }

      // Get M-Pesa transactions
      QuerySnapshot mpesaSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('mpesa_transactions')
          .get();

      int totalMpesaTransactions = mpesaSnapshot.docs.length;
      int importedTransactions = mpesaSnapshot.docs
          .where((doc) => (doc.data() as Map<String, dynamic>)['isImported'] == true)
          .length;

      // Get transaction types
      Map<String, int> transactionTypes = {};
      double totalAmount = 0;

      for (QueryDocumentSnapshot doc in mpesaSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String type = data['type'] ?? 'unknown';
        double amount = (data['amount'] as num?)?.toDouble() ?? 0;
        
        transactionTypes[type] = (transactionTypes[type] ?? 0) + 1;
        totalAmount += amount;
      }

      // Get last import date
      DocumentSnapshot configDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('mpesa_import')
          .get();

      DateTime? lastImportDate;
      if (configDoc.exists) {
        Map<String, dynamic> configData = configDoc.data() as Map<String, dynamic>;
        Timestamp? lastImportTimestamp = configData['lastImportDate'] as Timestamp?;
        lastImportDate = lastImportTimestamp?.toDate();
      }

      return {
        'totalMpesaTransactions': totalMpesaTransactions,
        'importedTransactions': importedTransactions,
        'pendingTransactions': totalMpesaTransactions - importedTransactions,
        'transactionTypes': transactionTypes,
        'totalAmount': totalAmount,
        'lastImportDate': lastImportDate,
        'importSuccessRate': totalMpesaTransactions > 0 
            ? '${(importedTransactions / totalMpesaTransactions * 100).toStringAsFixed(1)}%'
            : '0%',
      };
    } catch (e) {
      developer.log('Error getting import statistics: $e', name: _logName);
      return {};
    }
  }

  /// Test SMS parsing without importing
  static Future<List<MpesaSmsTransaction>> testSmsImport({
    int maxCount = 10,
    DateTime? since,
  }) async {
    try {
      developer.log('Testing SMS import (maxCount: $maxCount)', name: _logName);

      // Check SMS permission
      if (!await SmsReaderService.hasPermission()) {
        bool granted = await SmsReaderService.requestPermission();
        if (!granted) {
          throw Exception('SMS permission not granted');
        }
      }

      // Get and parse M-Pesa SMS
      List<MpesaSmsTransaction> transactions = await SmsReaderService.parseMpesaSms(
        maxCount: maxCount,
        since: since,
      );

      developer.log('Test import found ${transactions.length} transactions', name: _logName);
      return transactions;
    } catch (e) {
      developer.log('Error testing SMS import: $e', name: _logName);
      return [];
    }
  }
  
  /// Get recent transactions with parsing feedback
  static Future<List<MpesaSmsTransaction>> getRecentTransactionsWithFeedback() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];
      
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('mpesa_transactions')
          .orderBy('smsDate', descending: true)
          .limit(50)
          .get();
      
      return snapshot.docs
          .map((doc) => MpesaSmsTransaction.fromMap(doc.data()))
          .toList();
    } catch (e) {
      developer.log('Error loading transactions with feedback: $e', name: _logName);
      return [];
    }
  }
  
  /// Get parsing statistics for analytics
  static Future<Map<String, dynamic>> getParsingStatistics() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return {};
      
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('mpesa_transactions')
          .get();
      
      final transactions = snapshot.docs
          .map((doc) => MpesaSmsTransaction.fromMap(doc.data()))
          .toList();
      
      return _calculateParsingStatistics(transactions);
    } catch (e) {
      developer.log('Error calculating parsing statistics: $e', name: _logName);
      return {};
    }
  }
  
  /// Calculate detailed parsing statistics
  static Map<String, dynamic> _calculateParsingStatistics(List<MpesaSmsTransaction> transactions) {
    if (transactions.isEmpty) return {};
    
    final stats = <String, dynamic>{};
    
    // Basic counts
    stats['totalTransactions'] = transactions.length;
    stats['successfulParsing'] = transactions.where((t) => t.confidence > 0.5).length;
    
    // Confidence distribution
    final highConfidence = transactions.where((t) => t.confidence >= 0.9).length;
    final mediumConfidence = transactions.where((t) => t.confidence >= 0.7 && t.confidence < 0.9).length;
    final lowConfidence = transactions.where((t) => t.confidence < 0.7).length;
    
    stats['highConfidenceCount'] = highConfidence;
    stats['mediumConfidenceCount'] = mediumConfidence;
    stats['lowConfidenceCount'] = lowConfidence;
    
    // Average confidence
    final totalConfidence = transactions.fold<double>(0.0, (total, t) => total + t.confidence);
    stats['averageConfidence'] = (totalConfidence / transactions.length) * 100;
    
    // Balance validation rate
    final validatedTransactions = transactions.where((t) => t.isBalanceConsistent).length;
    stats['balanceValidationRate'] = (validatedTransactions / transactions.length) * 100;
    
    // Merchant recognition
    final merchantTransactions = transactions.where((t) => t.category != null).length;
    stats['merchantsRecognized'] = merchantTransactions;
    stats['merchantRecognitionRate'] = (merchantTransactions / transactions.length) * 100;
    
    // Transaction types
    final typeStats = <String, int>{};
    for (final transaction in transactions) {
      final type = transaction.type.toString().split('.').last;
      typeStats[type] = (typeStats[type] ?? 0) + 1;
    }
    stats['transactionTypes'] = typeStats;
    
    // Merchant stats
    final merchantStats = <String, Map<String, dynamic>>{};
    for (final transaction in transactions) {
      if (transaction.category != null) {
        final merchant = transaction.recipient ?? 'Unknown';
        if (!merchantStats.containsKey(merchant)) {
          merchantStats[merchant] = {
            'count': 0,
            'totalAmount': 0.0,
            'category': transaction.category,
          };
        }
        merchantStats[merchant]!['count'] = (merchantStats[merchant]!['count'] as int) + 1;
        merchantStats[merchant]!['totalAmount'] = 
            (merchantStats[merchant]!['totalAmount'] as double) + transaction.amount;
      }
    }
    stats['merchantStats'] = merchantStats;
    
    // User corrections (placeholder - would be tracked separately)
    stats['userCorrections'] = 0;
    stats['accuracyImprovement'] = 0.0;
    
    return stats;
  }
  
  /// Save user correction and update learning model
  static Future<void> saveTransactionCorrection(MpesaSmsTransaction correctedTransaction) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;
      
      // Save the corrected transaction
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('mpesa_transactions')
          .doc(correctedTransaction.mpesaCode)
          .update(correctedTransaction.toMap());
      
      // Save correction for learning
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('mpesa_corrections')
          .add({
            'originalTransaction': correctedTransaction.toMap(),
            'correctionDate': FieldValue.serverTimestamp(),
            'originalSms': correctedTransaction.originalSms,
            'userCorrections': {
              'category': correctedTransaction.category,
              'type': correctedTransaction.type.toString(),
              'recipient': correctedTransaction.recipient,
            },
          });
      
      developer.log('Transaction correction saved: ${correctedTransaction.mpesaCode}', name: _logName);
    } catch (e) {
      developer.log('Error saving transaction correction: $e', name: _logName);
      rethrow;
    }
  }
  
  /// Update machine learning model with user corrections
  static Future<void> updateMachineLearningModel(MpesaSmsTransaction correctedTransaction) async {
    try {
      // Extract learning patterns from the correction
      final patterns = _extractLearningPatterns(correctedTransaction);
      
      // Update merchant database with user corrections
      if (correctedTransaction.category != null && correctedTransaction.recipient != null) {
        _merchantCategories[correctedTransaction.recipient!.toUpperCase()] = 
            correctedTransaction.category!;
      }
      
      // Save learning patterns for future use
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('learning_patterns')
            .add({
              'patterns': patterns,
              'timestamp': FieldValue.serverTimestamp(),
              'transactionType': correctedTransaction.type.toString(),
              'category': correctedTransaction.category,
            });
      }
      
      developer.log('Machine learning model updated with correction', name: _logName);
    } catch (e) {
      developer.log('Error updating ML model: $e', name: _logName);
    }
  }
  
  /// Extract learning patterns from corrected transaction
  static Map<String, dynamic> _extractLearningPatterns(MpesaSmsTransaction transaction) {
    final patterns = <String, dynamic>{};
    
    // Extract keywords from SMS
    final smsWords = transaction.originalSms.toUpperCase().split(RegExp(r'\s+'));
    patterns['keywords'] = smsWords;
    
    // Extract merchant patterns
    if (transaction.recipient != null) {
      patterns['merchantKeywords'] = transaction.recipient!.toUpperCase().split(RegExp(r'\s+'));
    }
    
    // Extract amount patterns
    patterns['amountRange'] = _getAmountRange(transaction.amount);
    
    // Extract transaction type patterns
    patterns['transactionType'] = transaction.type.toString();
    
    return patterns;
  }
  
  /// Get amount range for pattern matching
  static String _getAmountRange(double amount) {
    if (amount < 100) return 'micro';
    if (amount < 1000) return 'small';
    if (amount < 10000) return 'medium';
    if (amount < 50000) return 'large';
    return 'very_large';
  }
  
  
}

/// Result of M-Pesa import operation
class MpesaImportResult {
  final bool success;
  final String message;
  final int totalFound;
  final int imported;
  final int skipped;
  final int failed;
  final List<String> errors;

  MpesaImportResult({
    required this.success,
    required this.message,
    required this.totalFound,
    required this.imported,
    required this.skipped,
    required this.failed,
    this.errors = const [],
  });

  @override
  String toString() {
    return 'MpesaImportResult(success: $success, message: $message, '
           'totalFound: $totalFound, imported: $imported, skipped: $skipped, failed: $failed)';
  }
}

// Helper types for income refinement decisions
enum _IncomeAction { income, transfer, skip }

class _IncomeDecision {
  final _IncomeAction action;
  final String? incomeTypeLabel;
  final String? reason;

  _IncomeDecision(this.action, {this.incomeTypeLabel, this.reason});

  factory _IncomeDecision.incomeType(String label) => _IncomeDecision(_IncomeAction.income, incomeTypeLabel: label);
  factory _IncomeDecision.transfer() => _IncomeDecision(_IncomeAction.transfer);
  factory _IncomeDecision.skip(String reason) => _IncomeDecision(_IncomeAction.skip, reason: reason);
}
