import 'dart:developer' as developer;
import 'package:permission_handler/permission_handler.dart';
import 'package:telephony/telephony.dart';
import '../models/mpesa_sms_model.dart';
import 'mpesa_sms_parser.dart';

/// Service for reading SMS messages from the device
class SmsReaderService {
  static const String _logName = 'SmsReaderService';
  static final Telephony _telephony = Telephony.instance;

  /// Check if SMS permission is granted
  static Future<bool> hasPermission() async {
    try {
      final status = await Permission.sms.status;
      developer.log('SMS permission status: $status', name: _logName);
      return status.isGranted;
    } catch (e) {
      developer.log('Error checking SMS permission: $e', name: _logName);
      return false;
    }
  }

  /// Request SMS permission from user
  static Future<bool> requestPermission() async {
    try {
      developer.log('Requesting SMS permission', name: _logName);
      final status = await Permission.sms.request();
      developer.log('SMS permission request result: $status', name: _logName);
      return status.isGranted;
    } catch (e) {
      developer.log('Error requesting SMS permission: $e', name: _logName);
      return false;
    }
  }

  /// Read all SMS messages from the device
  static Future<List<SmsMessage>> readAllSms({
    int? maxCount,
    DateTime? since,
  }) async {
    try {
      if (!await hasPermission()) {
        developer.log('No SMS permission, cannot read messages', name: _logName);
        return [];
      }

      developer.log('Reading SMS messages (maxCount: $maxCount, since: $since)', name: _logName);

      List<SmsMessage> messages = await _telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        sortOrder: [
          OrderBy(SmsColumn.DATE, sort: Sort.DESC),
        ],
      );

      // Filter by date if specified
      if (since != null) {
        messages = messages.where((msg) {
          DateTime msgDate = DateTime.fromMillisecondsSinceEpoch(msg.date ?? 0);
          return msgDate.isAfter(since);
        }).toList();
      }

      // Limit count if specified
      if (maxCount != null && messages.length > maxCount) {
        messages = messages.take(maxCount).toList();
      }

      developer.log('Read ${messages.length} SMS messages', name: _logName);
      return messages;
    } catch (e) {
      developer.log('Error reading SMS messages: $e', name: _logName);
      return [];
    }
  }

  /// Read only M-Pesa SMS messages
  static Future<List<SmsMessage>> readMpesaSms({
    int? maxCount,
    DateTime? since,
  }) async {
    try {
      List<SmsMessage> allMessages = await readAllSms(maxCount: maxCount, since: since);
      
      // Filter for M-Pesa messages
      List<SmsMessage> mpesaMessages = allMessages.where((msg) {
        String sender = msg.address ?? '';
        String body = msg.body ?? '';
        
        // Check if it's from M-Pesa
        for (String mpesaSender in MpesaSmsParser.mpesaSenders) {
          if (sender.toUpperCase().contains(mpesaSender)) {
            return true;
          }
        }
        
        // Check body for M-Pesa keywords
        String upperBody = body.toUpperCase();
        return upperBody.contains('MPESA') || 
               upperBody.contains('M-PESA') || 
               upperBody.contains('CONFIRMED');
      }).toList();

      developer.log('Found ${mpesaMessages.length} M-Pesa SMS messages', name: _logName);
      return mpesaMessages;
    } catch (e) {
      developer.log('Error reading M-Pesa SMS messages: $e', name: _logName);
      return [];
    }
  }

  /// Parse M-Pesa SMS messages into transactions
  static Future<List<MpesaSmsTransaction>> parseMpesaSms({
    int? maxCount,
    DateTime? since,
  }) async {
    try {
      List<SmsMessage> mpesaMessages = await readMpesaSms(maxCount: maxCount, since: since);
      List<MpesaSmsTransaction> transactions = [];

      for (SmsMessage message in mpesaMessages) {
        String sender = message.address ?? '';
        String body = message.body ?? '';
        DateTime smsDate = DateTime.fromMillisecondsSinceEpoch(message.date ?? 0);

        MpesaSmsTransaction? transaction = MpesaSmsParser.parseSms(body, sender, smsDate);
        if (transaction != null) {
          transactions.add(transaction);
        }
      }

      developer.log('Parsed ${transactions.length} M-Pesa transactions from ${mpesaMessages.length} SMS messages', name: _logName);
      return transactions;
    } catch (e) {
      developer.log('Error parsing M-Pesa SMS messages: $e', name: _logName);
      return [];
    }
  }

  /// Get SMS messages in date range
  static Future<List<SmsMessage>> getSmsInDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? fromAddress,
  }) async {
    try {
      if (!await hasPermission()) {
        developer.log('No SMS permission, cannot read messages', name: _logName);
        return [];
      }

      developer.log('Reading SMS messages from $startDate to $endDate', name: _logName);

      List<SmsMessage> messages = await _telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        filter: SmsFilter.where(SmsColumn.DATE)
            .greaterThanOrEqualTo(startDate.millisecondsSinceEpoch.toString())
            .and(SmsColumn.DATE)
            .lessThanOrEqualTo(endDate.millisecondsSinceEpoch.toString()),
        sortOrder: [
          OrderBy(SmsColumn.DATE, sort: Sort.DESC),
        ],
      );

      // Filter by sender if specified
      if (fromAddress != null) {
        messages = messages.where((msg) {
          String sender = msg.address ?? '';
          return sender.toUpperCase().contains(fromAddress.toUpperCase());
        }).toList();
      }

      developer.log('Found ${messages.length} SMS messages in date range', name: _logName);
      return messages;
    } catch (e) {
      developer.log('Error reading SMS messages in date range: $e', name: _logName);
      return [];
    }
  }

  /// Get latest M-Pesa SMS messages since last import
  static Future<List<MpesaSmsTransaction>> getLatestMpesaTransactions({
    DateTime? lastImportDate,
    int maxDays = 30,
  }) async {
    try {
      DateTime since = lastImportDate ?? DateTime.now().subtract(Duration(days: maxDays));
      
      developer.log('Getting latest M-Pesa transactions since $since', name: _logName);
      
      List<MpesaSmsTransaction> transactions = await parseMpesaSms(since: since);
      
      // Sort by transaction date (newest first)
      transactions.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
      
      developer.log('Found ${transactions.length} new M-Pesa transactions', name: _logName);
      return transactions;
    } catch (e) {
      developer.log('Error getting latest M-Pesa transactions: $e', name: _logName);
      return [];
    }
  }

  /// Check if device supports SMS reading
  static Future<bool> isSmsSupported() async {
    try {
      bool isSupported = await _telephony.isSmsCapable ?? false;
      developer.log('SMS capability: $isSupported', name: _logName);
      return isSupported;
    } catch (e) {
      developer.log('Error checking SMS capability: $e', name: _logName);
      return false;
    }
  }

  /// Get SMS statistics
  static Future<Map<String, dynamic>> getSmsStatistics({
    DateTime? since,
  }) async {
    try {
      List<SmsMessage> allMessages = await readAllSms(since: since);
      List<SmsMessage> mpesaMessages = allMessages.where((msg) {
        String sender = msg.address ?? '';
        String body = msg.body ?? '';
        
        for (String mpesaSender in MpesaSmsParser.mpesaSenders) {
          if (sender.toUpperCase().contains(mpesaSender)) {
            return true;
          }
        }
        
        String upperBody = body.toUpperCase();
        return upperBody.contains('MPESA') || upperBody.contains('M-PESA');
      }).toList();

      List<MpesaSmsTransaction> transactions = [];
      for (SmsMessage message in mpesaMessages) {
        String sender = message.address ?? '';
        String body = message.body ?? '';
        DateTime smsDate = DateTime.fromMillisecondsSinceEpoch(message.date ?? 0);

        MpesaSmsTransaction? transaction = MpesaSmsParser.parseSms(body, sender, smsDate);
        if (transaction != null) {
          transactions.add(transaction);
        }
      }

      Map<String, int> transactionTypes = {};
      double totalAmount = 0;
      int expenseCount = 0;
      int incomeCount = 0;

      for (MpesaSmsTransaction transaction in transactions) {
        String typeKey = transaction.type.toString().split('.').last;
        transactionTypes[typeKey] = (transactionTypes[typeKey] ?? 0) + 1;
        totalAmount += transaction.amount;
        
        if (transaction.isExpense) {
          expenseCount++;
        } else if (transaction.isIncome) {
          incomeCount++;
        }
      }

      return {
        'totalSmsMessages': allMessages.length,
        'mpesaSmsMessages': mpesaMessages.length,
        'parsedTransactions': transactions.length,
        'transactionTypes': transactionTypes,
        'totalAmount': totalAmount,
        'expenseTransactions': expenseCount,
        'incomeTransactions': incomeCount,
        'parseSuccessRate': mpesaMessages.isNotEmpty 
            ? '${(transactions.length / mpesaMessages.length * 100).toStringAsFixed(1)}%'
            : '0%',
      };
    } catch (e) {
      developer.log('Error getting SMS statistics: $e', name: _logName);
      return {};
    }
  }
}
