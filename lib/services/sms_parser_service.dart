import 'dart:async';

import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logging/logging.dart';

import '../models/transaction_model.dart' as models;
import '../models/account_model.dart';
import '../viewmodels/account_viewmodel.dart';

class SmsParserService {
  final SmsQuery _smsQuery = SmsQuery();
  final Logger _logger = Logger('SmsParserService');
  final StreamController<models.Transaction> _transactionStreamController = 
      StreamController<models.Transaction>.broadcast();

  Stream<models.Transaction> get transactionStream => _transactionStreamController.stream;
  
  // Helper method to get appropriate account ID based on SMS sender
  String _getAccountIdForSender(String sender, {AccountViewModel? accountVm}) {
    if (accountVm == null) return 'default_account';
    
    // Try to match account type based on sender
    if (sender.toUpperCase().contains('MPESA') || sender.toUpperCase().contains('M-PESA')) {
      final mpesaAccount = accountVm.accounts.firstWhere(
        (account) => account.type == AccountType.mpesa,
        orElse: () => accountVm.defaultAccount ?? accountVm.accounts.first,
      );
      return mpesaAccount.id;
    }
    
    // For bank SMS, try to find bank account
    final bankAccount = accountVm.accounts.firstWhere(
      (account) => account.type == AccountType.bank,
      orElse: () => accountVm.defaultAccount ?? accountVm.accounts.first,
    );
    return bankAccount.id;
  }

  // Regular expressions for different banks
  final Map<String, RegExp> _bankPatterns = {
    'MPESA': RegExp(
      r'([A-Z0-9]+) Confirmed\.[\s\S]*You have received Ksh([0-9,.]+)[\s\S]*from ([A-Z0-9 ]+)[\s\S]*on (\d{1,2}/\d{1,2}/\d{2,4})[\s\S]*',
    ),
    'KCB': RegExp(
      r'KCB Transaction Alert[\s\S]*Ksh ([0-9,.]+) has been (credited to|debited from) your account[\s\S]*from ([A-Z0-9 ]+)[\s\S]*',
    ),
    'EQUITY': RegExp(
      r'Equity Bank[\s\S]*(Paid|Received) Ksh([0-9,.]+)[\s\S]*to/from ([A-Z0-9 ]+)[\s\S]*',
    ),
    'STANBIC': RegExp(
      r'Stanbic Bank[\s\S]*You have (received|paid) ([0-9,.]+)[\s\S]*to/from ([A-Z0-9 ]+)[\s\S]*',
    ),
    // Add more bank patterns as needed
  };

  /// Request SMS permission from the user
  Future<bool> requestSmsPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  /// Check if SMS permission is granted
  Future<bool> checkSmsPermission() async {
    return await Permission.sms.isGranted;
  }

  /// Parse SMS messages to extract transaction data
  Future<List<models.Transaction>> parseTransactionsFromSms({int limit = 100}) async {
    final hasPermission = await checkSmsPermission();
    if (!hasPermission) {
      final granted = await requestSmsPermission();
      if (!granted) {
        throw Exception('SMS permission not granted');
      }
    }

    // Get SMS messages
    final messages = await _smsQuery.querySms(
      kinds: [SmsQueryKind.inbox],
      count: limit,
    );

    final List<models.Transaction> transactions = [];

    for (final SmsMessage message in messages) {
      final models.Transaction? transaction = _parseMessageToTransaction(message);
      if (transaction != null) {
        transactions.add(transaction);
        _transactionStreamController.add(transaction);
      }
    }

    return transactions;
  }

  /// Parse a single SMS message to a Transaction object
  models.Transaction? _parseMessageToTransaction(SmsMessage message, {AccountViewModel? accountVm}) {
    String? bankName;
    RegExpMatch? match;
    final userId = 'sms_parser_user'; // This should be replaced with actual user ID

    // Find which bank pattern matches the message
    for (final entry in _bankPatterns.entries) {
      if (entry.value.hasMatch(message.body ?? '')) {
        bankName = entry.key;
        match = entry.value.firstMatch(message.body ?? '');
        break;
      }
    }

    if (match == null || bankName == null) {
      return null; // No pattern matched
    }

    try {
      // Different parsing logic based on bank
      switch (bankName) {
        case 'MPESA':
          final amount = double.parse(match.group(2)?.replaceAll(',', '') ?? '0');
          final payee = match.group(3)?.trim() ?? 'Unknown';
          final dateStr = match.group(4) ?? '';
          
          // Parse date (DD/MM/YY format)
          DateTime date;
          if (dateStr.isNotEmpty) {
            final dateParts = dateStr.split('/');
            date = DateTime(
              2000 + int.parse(dateParts[2]), // Year
              int.parse(dateParts[1]),        // Month
              int.parse(dateParts[0]),        // Day
            );
          } else {
            date = DateTime.now();
          }
          
          return models.Transaction(
            title: 'M-PESA Transfer from $payee',
            amount: amount,
            date: date,
            category: 'Transfer',
            description: payee,
            type: models.TransactionType.income,
            userId: userId,
            accountId: _getAccountIdForSender(message.address ?? 'MPESA', accountVm: accountVm),
            smsReference: message.id.toString(),
          );
          
        case 'KCB':
          final amount = double.parse(match.group(1)?.replaceAll(',', '') ?? '0');
          final isDebit = (match.group(2) ?? '').contains('debited');
          final payee = match.group(3)?.trim() ?? 'Unknown';
          
          return models.Transaction(
            title: isDebit ? 'KCB Payment to $payee' : 'KCB Deposit from $payee',
            amount: amount,
            date: DateTime.now(),
            category: isDebit ? 'Payment' : 'Deposit',
            description: payee,
            type: isDebit ? models.TransactionType.expense : models.TransactionType.income,
            userId: userId,
            accountId: _getAccountIdForSender(message.address ?? 'KCB', accountVm: accountVm),
            smsReference: message.id.toString(),
          );
          
        case 'EQUITY':
          final isExpense = (match.group(1) ?? '').contains('Paid');
          final amount = double.parse(match.group(2)?.replaceAll(',', '') ?? '0');
          final payee = match.group(3)?.trim() ?? 'Unknown';
          
          return models.Transaction(
            title: isExpense ? 'Equity Payment to $payee' : 'Equity Deposit from $payee',
            amount: amount,
            date: DateTime.now(),
            category: isExpense ? 'Payment' : 'Deposit',
            description: payee,
            type: isExpense ? models.TransactionType.expense : models.TransactionType.income,
            userId: userId,
            accountId: _getAccountIdForSender(message.address ?? 'EQUITY', accountVm: accountVm),
            smsReference: message.id.toString(),
          );
          
        case 'STANBIC':
          final isExpense = (match.group(1) ?? '').contains('paid');
          final amount = double.parse(match.group(2)?.replaceAll(',', '') ?? '0');
          final payee = match.group(3)?.trim() ?? 'Unknown';
          
          return models.Transaction(
            title: isExpense ? 'Stanbic Payment to $payee' : 'Stanbic Deposit from $payee',
            amount: amount,
            date: DateTime.now(),
            category: isExpense ? 'Payment' : 'Deposit',
            description: payee,
            type: isExpense ? models.TransactionType.expense : models.TransactionType.income,
            userId: userId,
            accountId: _getAccountIdForSender(message.address ?? 'STANBIC', accountVm: accountVm),
            smsReference: message.id.toString(),
          );
          
        default:
          return null;
      }
    } catch (e) {
      _logger.warning('Error parsing SMS: $e');
      return null;
    }
  }

  /// Start listening for new SMS messages
  void startListeningForSms() {
    // This would be implemented with background service or broadcast receiver
    // For demo purposes, we'll just parse existing messages periodically
    Timer.periodic(const Duration(minutes: 5), (timer) {
      parseTransactionsFromSms(limit: 10);
    });
  }

  /// Dispose the service
  void dispose() {
    _transactionStreamController.close();
  }
}
