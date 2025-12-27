import 'dart:async';
import 'package:flutter/material.dart';

import 'transaction_service.dart';
import 'sms_parser_service.dart';
import '../models/transaction_model.dart' as models;

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
  Future<int> importTransactions() async {
    if (!_hasPermission) {
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
        await TransactionService.instance.addTransaction(transaction);
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
