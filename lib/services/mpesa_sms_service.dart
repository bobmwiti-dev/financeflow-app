import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logging/logging.dart';
import 'dart:async';

import '../models/transaction_model.dart' as models;
import '../models/account_model.dart';
import '../viewmodels/account_viewmodel.dart';
import 'transaction_service.dart';

class MpesaSmsService {
  // Singleton pattern
  static final MpesaSmsService _instance = MpesaSmsService._internal();
  static MpesaSmsService get instance => _instance;
  factory MpesaSmsService() => _instance;

  MpesaSmsService._internal();

  final SmsQuery _query = SmsQuery();
  final Logger _logger = Logger('MpesaSmsService');
  
  // Helper method to get M-Pesa account ID
  String _getMpesaAccountId(AccountViewModel? accountVm) {
    if (accountVm == null) return 'default_mpesa_account';
    
    // Try to find M-Pesa account
    final mpesaAccount = accountVm.accounts.firstWhere(
      (account) => account.type == AccountType.mpesa,
      orElse: () => accountVm.defaultAccount ?? accountVm.accounts.first,
    );
    
    return mpesaAccount.id;
  }

  // Define regex patterns for different M-Pesa SMS types
  final RegExp _mpesaReceivePattern = RegExp(
    r'([A-Z0-9]+) Confirmed\.\s+Ksh([0-9,.]+) received from ([A-Z ]+) ([0-9]+) on (\d{1,2}/\d{1,2}/\d{2,4}) at (\d{1,2}:\d{2} [APM]{2})',
    caseSensitive: false
  );

  final RegExp _mpesaPaymentPattern = RegExp(
    r'([A-Z0-9]+) Confirmed\.\s+Ksh([0-9,.]+) paid to ([A-Z ]+) on (\d{1,2}/\d{1,2}/\d{2,4}) at (\d{1,2}:\d{2} [APM]{2})',
    caseSensitive: false
  );

  final RegExp _mpesaSendPattern = RegExp(
    r'([A-Z0-9]+) Confirmed\.\s+Ksh([0-9,.]+) sent to ([A-Z ]+) ([0-9]+) on (\d{1,2}/\d{1,2}/\d{2,4}) at (\d{1,2}:\d{2} [APM]{2})',
    caseSensitive: false
  );

  final RegExp _mpesaWithdrawPattern = RegExp(
    r'([A-Z0-9]+) Confirmed\.\s+You have withdrawn Ksh([0-9,.]+) from ([A-Z0-9 ]+) ([A-Z0-9 ]+) on (\d{1,2}/\d{1,2}/\d{2,4}) at (\d{1,2}:\d{2} [APM]{2})',
    caseSensitive: false
  );

  // Check and request SMS permission
  Future<bool> requestSmsPermission() async {
    var status = await Permission.sms.status;
    if (!status.isGranted) {
      status = await Permission.sms.request();
    }
    return status.isGranted;
  }

  // Get all M-Pesa SMS messages
  Future<List<SmsMessage>> getMpesaSms() async {
    if (!await requestSmsPermission()) {
      _logger.warning('SMS permission not granted');
      return [];
    }

    try {
      final messages = await _query.querySms(
        kinds: [SmsQueryKind.inbox],
        address: 'MPESA', // Filter for M-Pesa messages only
      );
      
      _logger.info('Found ${messages.length} M-Pesa SMS messages');
      return messages;
    } catch (e) {
      _logger.severe('Error querying SMS: $e');
      return [];
    }
  }

  // Parse date from M-Pesa SMS
  DateTime _parseDate(String dateStr, String timeStr) {
    try {
      // Handle different date formats (e.g., 01/02/22 or 1/2/2022)
      final parts = dateStr.split('/');
      if (parts.length != 3) {
        return DateTime.now(); // Fallback
      }

      int day = int.parse(parts[0]);
      int month = int.parse(parts[1]);
      int year = int.parse(parts[2]);
      
      // Add century if year is just two digits
      if (year < 100) {
        year += 2000;
      }

      // Parse time (e.g., "2:30 PM")
      final timeParts = timeStr.split(':');
      int hour = int.parse(timeParts[0]);
      final minuteAndPeriod = timeParts[1].split(' ');
      int minute = int.parse(minuteAndPeriod[0]);
      String period = minuteAndPeriod[1];

      // Convert to 24-hour format
      if (period.toLowerCase() == 'pm' && hour < 12) {
        hour += 12;
      } else if (period.toLowerCase() == 'am' && hour == 12) {
        hour = 0;
      }

      return DateTime(year, month, day, hour, minute);
    } catch (e) {
      _logger.warning('Error parsing date: $e');
      return DateTime.now();
    }
  }

  // Clean amount string (remove "Ksh" and commas)
  double _parseAmount(String amountStr) {
    try {
      // Remove "Ksh", commas, and any other non-numeric characters except decimal point
      final cleanedStr = amountStr.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.parse(cleanedStr);
    } catch (e) {
      _logger.warning('Error parsing amount: $e');
      return 0.0;
    }
  }

  // Categorize transaction based on content
  String _categorizeTransaction(String body, bool isExpense) {
    final lowerBody = body.toLowerCase();
    
    // Basic categorization logic
    if (lowerBody.contains('withdraw') || 
        lowerBody.contains('agent') ||
        lowerBody.contains('atm')) {
      return 'Cash Withdrawal';
    } else if (lowerBody.contains('paybill')) {
      return 'Bills & Utilities';
    } else if (lowerBody.contains('buy goods') || 
               lowerBody.contains('till') ||
               lowerBody.contains('merchant')) {
      return 'Shopping';
    } else if (lowerBody.contains('airtime') || 
               lowerBody.contains('bundles')) {
      return 'Airtime & Data';
    } else if (lowerBody.contains('sent to') ||
               lowerBody.contains('sent money')) {
      return 'Transfer';
    } else if (lowerBody.contains('loan') ||
               lowerBody.contains('fuliza')) {
      return 'Loan';
    } else if (lowerBody.contains('salary') ||
               lowerBody.contains('payment received')) {
      return 'Income';
    } else if (!isExpense) {
      return 'Income';
    } else {
      return 'Other';
    }
  }

  // Parse a single SMS message
  models.Transaction? parseMpesaSms(SmsMessage message, {AccountViewModel? accountVm}) {
    try {
      final body = message.body ?? '';
      final userId = 'mpesa_user'; // This should be replaced with actual user ID
      
      // Check if this is an M-Pesa message
      if (message.address?.toUpperCase() != 'MPESA') {
        return null;
      }

      // Try to match different M-Pesa transaction patterns
      Match? match;
      String counterparty = '';
      String dateStr = '';
      String timeStr = '';
      String confirmationCode = '';
      double amount = 0.0;
      String? phoneNumber;

      // Check for money received
      match = _mpesaReceivePattern.firstMatch(body);
      if (match != null) {
        confirmationCode = match.group(1) ?? '';
        amount = _parseAmount(match.group(2) ?? '0');
        counterparty = match.group(3) ?? 'Unknown';
        phoneNumber = match.group(4);
        dateStr = match.group(5) ?? '';
        timeStr = match.group(6) ?? '';
        
        return models.Transaction(
          title: 'Received from $counterparty',
          amount: amount,
          date: _parseDate(dateStr, timeStr),
          category: 'Income',
          description: 'M-Pesa payment from $counterparty${phoneNumber != null ? ' ($phoneNumber)' : ''}',
          type: models.TransactionType.income,
          fromAccount: phoneNumber,
          userId: userId,
          accountId: _getMpesaAccountId(accountVm),
          notes: 'Imported from M-Pesa SMS. Confirmation: $confirmationCode',
          smsReference: message.id.toString(),
        );
      }

      // Check for payment made
      match = _mpesaPaymentPattern.firstMatch(body);
      if (match != null) {
        confirmationCode = match.group(1) ?? '';
        amount = _parseAmount(match.group(2) ?? '0');
        counterparty = match.group(3) ?? 'Unknown';
        dateStr = match.group(4) ?? '';
        timeStr = match.group(5) ?? '';
        
        final category = _categorizeTransaction(body, true);
        
        return models.Transaction(
          title: 'Paid to $counterparty',
          amount: amount,
          date: _parseDate(dateStr, timeStr),
          category: category,
          description: 'M-Pesa payment to $counterparty',
          type: models.TransactionType.expense,
          toAccount: counterparty,
          userId: userId,
          accountId: _getMpesaAccountId(accountVm),
          notes: 'Imported from M-Pesa SMS. Confirmation: $confirmationCode',
          smsReference: message.id.toString(),
        );
      }

      // Check for money sent
      match = _mpesaSendPattern.firstMatch(body);
      if (match != null) {
        confirmationCode = match.group(1) ?? '';
        amount = _parseAmount(match.group(2) ?? '0');
        counterparty = match.group(3) ?? 'Unknown';
        phoneNumber = match.group(4);
        dateStr = match.group(5) ?? '';
        timeStr = match.group(6) ?? '';
        
        return models.Transaction(
          title: 'Sent to $counterparty',
          amount: amount,
          date: _parseDate(dateStr, timeStr),
          category: 'Transfer',
          description: 'M-Pesa send money to $counterparty${phoneNumber != null ? ' ($phoneNumber)' : ''}',
          type: models.TransactionType.transfer,
          toAccount: phoneNumber ?? counterparty,
          userId: userId,
          accountId: _getMpesaAccountId(accountVm),
          notes: 'Imported from M-Pesa SMS. Confirmation: $confirmationCode',
          smsReference: message.id.toString(),
        );
      }

      // Check for withdrawal
      match = _mpesaWithdrawPattern.firstMatch(body);
      if (match != null) {
        confirmationCode = match.group(1) ?? '';
        amount = _parseAmount(match.group(2) ?? '0');
        final agent = match.group(3) ?? 'Unknown';
        final location = match.group(4) ?? '';
        dateStr = match.group(5) ?? '';
        timeStr = match.group(6) ?? '';
        
        return models.Transaction(
          title: 'Withdrawal at $agent',
          amount: amount,
          date: _parseDate(dateStr, timeStr),
          category: 'Cash Withdrawal',
          description: 'Cash withdrawal${location.isNotEmpty ? ' at $location' : ''}',
          type: models.TransactionType.expense,
          userId: userId,
          accountId: _getMpesaAccountId(accountVm),
          notes: 'Imported from M-Pesa SMS. Confirmation: $confirmationCode',
          smsReference: message.id.toString(),
        );
      }

      // No pattern matched
      return null;
    } catch (e) {
      _logger.severe('Error parsing M-Pesa SMS: $e');
      return null;
    }
  }

  // Import all M-Pesa transactions from SMS
  Future<List<models.Transaction>> importAllMpesaTransactions({AccountViewModel? accountVm}) async {
    final messages = await getMpesaSms();
    final importedTransactions = <models.Transaction>[];
    
    for (final message in messages) {
      final transaction = parseMpesaSms(message, accountVm: accountVm);
      if (transaction != null) {
        importedTransactions.add(transaction);
        
        // Save to database
        try {
          TransactionService.instance.addTransaction(transaction);
          _logger.info('Imported transaction: ${transaction.title}');
        } catch (e) {
          _logger.warning('Error saving transaction: $e');
          // Continue with next transaction
        }
      }
    }
    
    _logger.info('Imported ${importedTransactions.length} transactions');
    return importedTransactions;
  }
  
  // Get preview of transactions that would be imported
  Future<List<models.Transaction>> previewMpesaTransactions({AccountViewModel? accountVm}) async {
    final messages = await getMpesaSms();
    final previewTransactions = <models.Transaction>[];
    
    for (final message in messages) {
      final transaction = parseMpesaSms(message, accountVm: accountVm);
      if (transaction != null) {
        previewTransactions.add(transaction);
      }
    }
    
    return previewTransactions;
  }
}
