import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'transaction_service.dart';
import 'sms_parser_service.dart';
import '../models/transaction_model.dart' as models;
import 'merchant_rule_service.dart';

/// Service to handle importing SMS transactions into the app database
class SmsImportService extends ChangeNotifier {
  final TransactionService _transactionService;
  final SmsParserService _smsParserService;
  
  bool _isImporting = false;
  bool _hasPermission = false;
  int _importedCount = 0;
  String? _errorMessage;
  
  SmsImportService({
    required TransactionService transactionService,
    required SmsParserService smsParserService,
  }) : _transactionService = transactionService,
       _smsParserService = smsParserService {
    _checkPermission();
  }
  
  bool get isImporting => _isImporting;
  bool get hasPermission => _hasPermission;
  int get importedCount => _importedCount;
  String? get errorMessage => _errorMessage;
  
  /// Check if the app has SMS permission
  Future<void> _checkPermission() async {
    try {
      _hasPermission = await _smsParserService.checkSmsPermission();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to check SMS permission: $e';
      notifyListeners();
    }
  }
  
  /// Request SMS permission from the user
  Future<bool> requestPermission() async {
    try {
      _hasPermission = await _smsParserService.requestSmsPermission();
      notifyListeners();
      return _hasPermission;
    } catch (e) {
      _errorMessage = 'Failed to request SMS permission: $e';
      notifyListeners();
      return false;
    }
  }
  
  /// Import transactions from SMS messages
  Future<int> importTransactions({bool ensurePermission = true}) async {
    if (ensurePermission && !_hasPermission) {
      final granted = await requestPermission();
      if (!granted) {
        throw Exception('SMS permission not granted');
      }
    }
    
    try {
      _isImporting = true;
      _errorMessage = null;
      _importedCount = 0;
      notifyListeners();
      
      final transactions = await _smsParserService.parseTransactionsFromSms();
      
      // Filter out transactions that might be duplicates (based on SMS reference)
      final uniqueTransactions = <models.Transaction>[];
      
      for (final transaction in transactions) {
        // Check if this transaction is already in the database
        final exists = await _transactionService.checkTransactionExistsBySmsReference(
          transaction.smsReference ?? '',
        );
        
        if (!exists && transaction.smsReference != null && transaction.smsReference!.isNotEmpty) {
          uniqueTransactions.add(transaction);
        }
      }
      
      // Save unique transactions to database
      for (final transaction in uniqueTransactions) {
        final learnedCategory = await MerchantRuleService.instance
            .findCategoryForText('${transaction.title} ${transaction.description ?? ''}');
        final txToSave = learnedCategory != null && learnedCategory.isNotEmpty
            ? transaction.copyWith(category: learnedCategory)
            : transaction;

        await TransactionService.instance.addTransaction(txToSave);
        _importedCount++;
      }
      
      _isImporting = false;
      notifyListeners();
      return _importedCount;
    } catch (e) {
      _isImporting = false;
      _errorMessage = 'Failed to import transactions: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Automatically import bank SMS transactions if enough time has passed
  /// since the last import. This is intended for background or on-start
  /// usage and will not request SMS permissions by itself.
  Future<int?> autoImportIfNeeded({
    Duration minInterval = const Duration(hours: 24),
  }) async {
    try {
      // Only proceed if SMS permission is already granted
      final permissionGranted = await _smsParserService.checkSmsPermission();
      if (!permissionGranted) {
        return null;
      }

      final prefs = await SharedPreferences.getInstance();
      const key = 'last_bank_sms_import';

      final now = DateTime.now();
      final lastMillis = prefs.getInt(key);
      if (lastMillis != null) {
        final lastImport = DateTime.fromMillisecondsSinceEpoch(lastMillis);
        if (now.difference(lastImport) < minInterval) {
          return null;
        }
      }

      // Mark permission as granted so importTransactions won't prompt
      _hasPermission = true;

      final imported = await importTransactions(ensurePermission: false);

      await prefs.setInt(key, now.millisecondsSinceEpoch);
      return imported;
    } catch (_) {
      return null;
    }
  }
  
  /// Start monitoring for new SMS messages
  void startMonitoring() {
    if (!_hasPermission) {
      requestPermission().then((granted) {
        if (granted) {
          _smsParserService.startListeningForSms();
          _listenForNewTransactions();
        }
      });
    } else {
      _smsParserService.startListeningForSms();
      _listenForNewTransactions();
    }
  }
  
  /// Listen for new transactions from the SMS parser
  void _listenForNewTransactions() {
    _smsParserService.transactionStream.listen((transaction) async {
      // Check if this transaction is already in the database
      final exists = await _transactionService.checkTransactionExistsBySmsReference(
        transaction.smsReference ?? '',
      );
      
      if (!exists && transaction.smsReference != null && transaction.smsReference!.isNotEmpty) {
        await TransactionService.instance.addTransaction(transaction);
        _importedCount++;
        notifyListeners();
      }
    });
  }
}
