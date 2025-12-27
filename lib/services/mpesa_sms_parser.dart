import 'dart:developer' as developer;
import 'package:intl/intl.dart';
import '../models/mpesa_sms_model.dart';

/// Service for parsing M-Pesa SMS messages into structured transaction data
class MpesaSmsParser {
  static const String _logName = 'MpesaSmsParser';

  /// Known M-Pesa sender numbers
  static const List<String> mpesaSenders = [
    'MPESA',
    'M-PESA',
    '+254722000000', // Common M-Pesa number
    'SAFARICOM',
  ];

  /// Parse M-Pesa SMS message into structured transaction
  static MpesaSmsTransaction? parseSms(String smsBody, String sender, DateTime smsDate) {
    try {
      developer.log('Parsing SMS from $sender: ${smsBody.substring(0, smsBody.length > 100 ? 100 : smsBody.length)}...', name: _logName);

      // Check if SMS is from M-Pesa
      if (!_isMpesaSms(sender, smsBody)) {
        developer.log('SMS not from M-Pesa, skipping', name: _logName);
        return null;
      }

      // Clean the SMS text
      String cleanSms = _cleanSmsText(smsBody);

      // Try different parsing patterns
      MpesaSmsTransaction? transaction;
      
      transaction ??= _parseSentMoney(cleanSms, smsDate);
      transaction ??= _parseReceivedMoney(cleanSms, smsDate);
      transaction ??= _parseWithdrawal(cleanSms, smsDate);
      transaction ??= _parseDeposit(cleanSms, smsDate);
      transaction ??= _parsePaybill(cleanSms, smsDate);
      transaction ??= _parseBuyGoods(cleanSms, smsDate);
      transaction ??= _parseAirtime(cleanSms, smsDate);
      transaction ??= _parseReversal(cleanSms, smsDate);

      if (transaction != null) {
        developer.log('Successfully parsed ${transaction.type} transaction: ${transaction.mpesaCode}', name: _logName);
        return transaction.copyWith(originalSms: smsBody, smsDate: smsDate);
      } else {
        developer.log('Could not parse SMS: $cleanSms', name: _logName);
        return null;
      }
    } catch (e) {
      developer.log('Error parsing SMS: $e', name: _logName);
      return null;
    }
  }

  /// Check if SMS is from M-Pesa
  static bool _isMpesaSms(String sender, String smsBody) {
    // Check sender
    for (String mpesaSender in mpesaSenders) {
      if (sender.toUpperCase().contains(mpesaSender)) {
        return true;
      }
    }

    // Check SMS content for M-Pesa keywords
    String upperBody = smsBody.toUpperCase();
    return upperBody.contains('MPESA') || 
           upperBody.contains('M-PESA') || 
           upperBody.contains('SAFARICOM') ||
           upperBody.contains('CONFIRMED');
  }

  /// Clean SMS text for parsing
  static String _cleanSmsText(String sms) {
    return sms
        .replaceAll(RegExp(r'\s+'), ' ') // Multiple spaces to single
        .replaceAll(RegExp(r'[^\w\s\.\-\+\(\)\/:]'), ' ') // Remove special chars except common ones
        .trim();
  }

  /// Parse sent money SMS
  /// Example: "QH12345678 Confirmed. Ksh2,500.00 sent to JOHN DOE 0722123456 on 15/1/25 at 2:30 PM. M-PESA balance is Ksh15,000.00."
  static MpesaSmsTransaction? _parseSentMoney(String sms, DateTime smsDate) {
    final patterns = [
      // Standard sent money pattern
      RegExp(r'(\w+)\s+Confirmed\.?\s*Ksh?([\d,]+\.?\d*)\s+sent\s+to\s+([^0-9]+)\s*(\d+)?\s+on\s+([\d\/]+)\s+at\s+([\d:]+\s*[AP]M).*?balance\s+is\s+Ksh?([\d,]+\.?\d*)', caseSensitive: false),
      // Alternative pattern
      RegExp(r'(\w+)\s+Confirmed\.?\s*You\s+have\s+sent\s+Ksh?([\d,]+\.?\d*)\s+to\s+([^0-9]+)\s*(\d+)?.*?balance\s+is\s+Ksh?([\d,]+\.?\d*)', caseSensitive: false),
    ];

    for (RegExp pattern in patterns) {
      final match = pattern.firstMatch(sms);
      if (match != null) {
        try {
          String mpesaCode = match.group(1)!;
          double amount = _parseAmount(match.group(2)!);
          String recipient = match.group(3)!.trim();
          String? phoneNumber = match.group(4);
          double balance = _parseAmount(match.group(match.groupCount)!);

          DateTime transactionDate = _parseTransactionDate(sms, smsDate);

          return MpesaSmsTransaction(
            originalSms: sms,
            mpesaCode: mpesaCode,
            type: MpesaTransactionType.sent,
            amount: amount,
            recipient: recipient,
            balance: balance,
            transactionDate: transactionDate,
            smsDate: smsDate,
            metadata: {
              'recipientPhone': phoneNumber,
            },
          );
        } catch (e) {
          developer.log('Error parsing sent money: $e', name: _logName);
        }
      }
    }
    return null;
  }

  /// Parse received money SMS
  /// Example: "QH12345678 Confirmed. You have received Ksh1,000.00 from JANE DOE 0733123456 on 15/1/25 at 3:45 PM. M-PESA balance is Ksh16,000.00."
  static MpesaSmsTransaction? _parseReceivedMoney(String sms, DateTime smsDate) {
    final patterns = [
      RegExp(r'(\w+)\s+Confirmed\.?\s*You\s+have\s+received\s+Ksh?([\d,]+\.?\d*)\s+from\s+([^0-9]+)\s*(\d+)?\s+on\s+([\d\/]+)\s+at\s+([\d:]+\s*[AP]M).*?balance\s+is\s+Ksh?([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'(\w+)\s+Confirmed\.?\s*Ksh?([\d,]+\.?\d*)\s+received\s+from\s+([^0-9]+)\s*(\d+)?.*?balance\s+is\s+Ksh?([\d,]+\.?\d*)', caseSensitive: false),
    ];

    for (RegExp pattern in patterns) {
      final match = pattern.firstMatch(sms);
      if (match != null) {
        try {
          String mpesaCode = match.group(1)!;
          double amount = _parseAmount(match.group(2)!);
          String sender = match.group(3)!.trim();
          String? phoneNumber = match.group(4);
          double balance = _parseAmount(match.group(match.groupCount)!);

          DateTime transactionDate = _parseTransactionDate(sms, smsDate);

          return MpesaSmsTransaction(
            originalSms: sms,
            mpesaCode: mpesaCode,
            type: MpesaTransactionType.received,
            amount: amount,
            sender: sender,
            balance: balance,
            transactionDate: transactionDate,
            smsDate: smsDate,
            metadata: {
              'senderPhone': phoneNumber,
            },
          );
        } catch (e) {
          developer.log('Error parsing received money: $e', name: _logName);
        }
      }
    }
    return null;
  }

  /// Parse withdrawal SMS
  /// Example: "QH12345678 Confirmed. Ksh3,000.00 withdrawn from agent JOHN'S SHOP - 12345 on 15/1/25 at 4:15 PM. M-PESA balance is Ksh13,000.00."
  static MpesaSmsTransaction? _parseWithdrawal(String sms, DateTime smsDate) {
    final patterns = [
      RegExp(r'(\w+)\s+Confirmed\.?\s*Ksh?([\d,]+\.?\d*)\s+withdrawn\s+from\s+agent\s+([^-]+)\s*-\s*(\d+)\s+on\s+([\d\/]+)\s+at\s+([\d:]+\s*[AP]M).*?balance\s+is\s+Ksh?([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'(\w+)\s+Confirmed\.?\s*You\s+have\s+withdrawn\s+Ksh?([\d,]+\.?\d*)\s+from\s+([^.]+).*?balance\s+is\s+Ksh?([\d,]+\.?\d*)', caseSensitive: false),
    ];

    for (RegExp pattern in patterns) {
      final match = pattern.firstMatch(sms);
      if (match != null) {
        try {
          String mpesaCode = match.group(1)!;
          double amount = _parseAmount(match.group(2)!);
          String agentName = match.group(3)!.trim();
          String? agentNumber = match.group(4);
          double balance = _parseAmount(match.group(match.groupCount)!);

          DateTime transactionDate = _parseTransactionDate(sms, smsDate);

          return MpesaSmsTransaction(
            originalSms: sms,
            mpesaCode: mpesaCode,
            type: MpesaTransactionType.withdrawal,
            amount: amount,
            recipient: agentName,
            agentNumber: agentNumber,
            balance: balance,
            transactionDate: transactionDate,
            smsDate: smsDate,
          );
        } catch (e) {
          developer.log('Error parsing withdrawal: $e', name: _logName);
        }
      }
    }
    return null;
  }

  /// Parse deposit SMS
  /// Example: "QH12345678 Confirmed. Ksh5,000.00 deposited to your account by agent MARY'S SHOP - 67890 on 15/1/25 at 5:30 PM. M-PESA balance is Ksh18,000.00."
  static MpesaSmsTransaction? _parseDeposit(String sms, DateTime smsDate) {
    final patterns = [
      RegExp(r'(\w+)\s+Confirmed\.?\s*Ksh?([\d,]+\.?\d*)\s+deposited\s+to\s+your\s+account\s+by\s+agent\s+([^-]+)\s*-\s*(\d+)\s+on\s+([\d\/]+)\s+at\s+([\d:]+\s*[AP]M).*?balance\s+is\s+Ksh?([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'(\w+)\s+Confirmed\.?\s*You\s+have\s+deposited\s+Ksh?([\d,]+\.?\d*)\s+at\s+([^.]+).*?balance\s+is\s+Ksh?([\d,]+\.?\d*)', caseSensitive: false),
    ];

    for (RegExp pattern in patterns) {
      final match = pattern.firstMatch(sms);
      if (match != null) {
        try {
          String mpesaCode = match.group(1)!;
          double amount = _parseAmount(match.group(2)!);
          String agentName = match.group(3)!.trim();
          String? agentNumber = match.group(4);
          double balance = _parseAmount(match.group(match.groupCount)!);

          DateTime transactionDate = _parseTransactionDate(sms, smsDate);

          return MpesaSmsTransaction(
            originalSms: sms,
            mpesaCode: mpesaCode,
            type: MpesaTransactionType.deposit,
            amount: amount,
            sender: agentName,
            agentNumber: agentNumber,
            balance: balance,
            transactionDate: transactionDate,
            smsDate: smsDate,
          );
        } catch (e) {
          developer.log('Error parsing deposit: $e', name: _logName);
        }
      }
    }
    return null;
  }

  /// Parse paybill SMS
  /// Example: "QH12345678 Confirmed. Ksh1,500.00 paid to KENYA POWER for account 123456789 on 15/1/25 at 6:00 PM. M-PESA balance is Ksh16,500.00."
  static MpesaSmsTransaction? _parsePaybill(String sms, DateTime smsDate) {
    final patterns = [
      RegExp(r'(\w+)\s+Confirmed\.?\s*Ksh?([\d,]+\.?\d*)\s+paid\s+to\s+([^f]+)\s+for\s+account\s+(\w+)\s+on\s+([\d\/]+)\s+at\s+([\d:]+\s*[AP]M).*?balance\s+is\s+Ksh?([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'(\w+)\s+Confirmed\.?\s*You\s+have\s+paid\s+Ksh?([\d,]+\.?\d*)\s+to\s+([^.]+).*?Account\s+(\w+).*?balance\s+is\s+Ksh?([\d,]+\.?\d*)', caseSensitive: false),
    ];

    for (RegExp pattern in patterns) {
      final match = pattern.firstMatch(sms);
      if (match != null) {
        try {
          String mpesaCode = match.group(1)!;
          double amount = _parseAmount(match.group(2)!);
          String paybillName = match.group(3)!.trim();
          String accountNumber = match.group(4)!;
          double balance = _parseAmount(match.group(match.groupCount)!);

          DateTime transactionDate = _parseTransactionDate(sms, smsDate);

          return MpesaSmsTransaction(
            originalSms: sms,
            mpesaCode: mpesaCode,
            type: MpesaTransactionType.paybill,
            amount: amount,
            recipient: paybillName,
            accountNumber: accountNumber,
            balance: balance,
            transactionDate: transactionDate,
            smsDate: smsDate,
          );
        } catch (e) {
          developer.log('Error parsing paybill: $e', name: _logName);
        }
      }
    }
    return null;
  }

  /// Parse buy goods SMS
  /// Example: "QH12345678 Confirmed. Ksh800.00 paid to JAVA HOUSE - 54321 on 15/1/25 at 7:30 PM. M-PESA balance is Ksh15,700.00."
  static MpesaSmsTransaction? _parseBuyGoods(String sms, DateTime smsDate) {
    final patterns = [
      RegExp(r'(\w+)\s+Confirmed\.?\s*Ksh?([\d,]+\.?\d*)\s+paid\s+to\s+([^-]+)\s*-\s*(\d+)\s+on\s+([\d\/]+)\s+at\s+([\d:]+\s*[AP]M).*?balance\s+is\s+Ksh?([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'(\w+)\s+Confirmed\.?\s*You\s+have\s+paid\s+Ksh?([\d,]+\.?\d*)\s+to\s+([^.]+).*?Till\s+(\d+).*?balance\s+is\s+Ksh?([\d,]+\.?\d*)', caseSensitive: false),
    ];

    for (RegExp pattern in patterns) {
      final match = pattern.firstMatch(sms);
      if (match != null) {
        try {
          String mpesaCode = match.group(1)!;
          double amount = _parseAmount(match.group(2)!);
          String merchantName = match.group(3)!.trim();
          String tillNumber = match.group(4)!;
          double balance = _parseAmount(match.group(match.groupCount)!);

          DateTime transactionDate = _parseTransactionDate(sms, smsDate);

          return MpesaSmsTransaction(
            originalSms: sms,
            mpesaCode: mpesaCode,
            type: MpesaTransactionType.buyGoods,
            amount: amount,
            recipient: merchantName,
            paybillNumber: tillNumber,
            balance: balance,
            transactionDate: transactionDate,
            smsDate: smsDate,
          );
        } catch (e) {
          developer.log('Error parsing buy goods: $e', name: _logName);
        }
      }
    }
    return null;
  }

  /// Parse airtime SMS
  /// Example: "QH12345678 Confirmed. Ksh100.00 airtime purchased for 0722123456 on 15/1/25 at 8:00 PM. M-PESA balance is Ksh15,600.00."
  static MpesaSmsTransaction? _parseAirtime(String sms, DateTime smsDate) {
    final patterns = [
      RegExp(r'(\w+)\s+Confirmed\.?\s*Ksh?([\d,]+\.?\d*)\s+airtime\s+purchased\s+for\s+(\d+)\s+on\s+([\d\/]+)\s+at\s+([\d:]+\s*[AP]M).*?balance\s+is\s+Ksh?([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'(\w+)\s+Confirmed\.?\s*You\s+have\s+bought\s+Ksh?([\d,]+\.?\d*)\s+airtime.*?balance\s+is\s+Ksh?([\d,]+\.?\d*)', caseSensitive: false),
    ];

    for (RegExp pattern in patterns) {
      final match = pattern.firstMatch(sms);
      if (match != null) {
        try {
          String mpesaCode = match.group(1)!;
          double amount = _parseAmount(match.group(2)!);
          String? phoneNumber = match.group(3);
          double balance = _parseAmount(match.group(match.groupCount)!);

          DateTime transactionDate = _parseTransactionDate(sms, smsDate);

          return MpesaSmsTransaction(
            originalSms: sms,
            mpesaCode: mpesaCode,
            type: MpesaTransactionType.airtime,
            amount: amount,
            recipient: 'Airtime',
            balance: balance,
            transactionDate: transactionDate,
            smsDate: smsDate,
            metadata: {
              'phoneNumber': phoneNumber,
            },
          );
        } catch (e) {
          developer.log('Error parsing airtime: $e', name: _logName);
        }
      }
    }
    return null;
  }

  /// Parse reversal SMS
  /// Example: "QH12345678 Confirmed. Transaction QH87654321 has been reversed. Ksh500.00 has been refunded. M-PESA balance is Ksh16,100.00."
  static MpesaSmsTransaction? _parseReversal(String sms, DateTime smsDate) {
    final patterns = [
      RegExp(r'(\w+)\s+Confirmed\.?\s*Transaction\s+(\w+)\s+has\s+been\s+reversed\.?\s*Ksh?([\d,]+\.?\d*)\s+has\s+been\s+refunded.*?balance\s+is\s+Ksh?([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'(\w+)\s+Confirmed\.?\s*Reversal.*?Ksh?([\d,]+\.?\d*).*?balance\s+is\s+Ksh?([\d,]+\.?\d*)', caseSensitive: false),
    ];

    for (RegExp pattern in patterns) {
      final match = pattern.firstMatch(sms);
      if (match != null) {
        try {
          String mpesaCode = match.group(1)!;
          String? originalTransactionCode = match.group(2);
          double amount = _parseAmount(match.group(3)!);
          double balance = _parseAmount(match.group(match.groupCount)!);

          DateTime transactionDate = _parseTransactionDate(sms, smsDate);

          return MpesaSmsTransaction(
            originalSms: sms,
            mpesaCode: mpesaCode,
            type: MpesaTransactionType.reversal,
            amount: amount,
            recipient: 'Reversal',
            balance: balance,
            transactionDate: transactionDate,
            smsDate: smsDate,
            metadata: {
              'originalTransactionCode': originalTransactionCode,
            },
          );
        } catch (e) {
          developer.log('Error parsing reversal: $e', name: _logName);
        }
      }
    }
    return null;
  }

  /// Parse amount from string (handles commas and currency symbols)
  static double _parseAmount(String amountStr) {
    String cleanAmount = amountStr
        .replaceAll('Ksh', '')
        .replaceAll('KSh', '')
        .replaceAll(',', '')
        .trim();
    return double.parse(cleanAmount);
  }

  /// Parse transaction date from SMS
  static DateTime _parseTransactionDate(String sms, DateTime smsDate) {
    try {
      // Try to extract date and time from SMS
      final dateTimePattern = RegExp(r'on\s+([\d\/]+)\s+at\s+([\d:]+\s*[AP]M)', caseSensitive: false);
      final match = dateTimePattern.firstMatch(sms);
      
      if (match != null) {
        String dateStr = match.group(1)!;
        String timeStr = match.group(2)!;
        
        // Parse date (format: dd/MM/yy or dd/MM/yyyy)
        List<String> dateParts = dateStr.split('/');
        if (dateParts.length == 3) {
          int day = int.parse(dateParts[0]);
          int month = int.parse(dateParts[1]);
          int year = int.parse(dateParts[2]);
          
          // Handle 2-digit years
          if (year < 100) {
            year += 2000;
          }
          
          // Parse time
          final timeFormat = DateFormat('h:mm a');
          DateTime time = timeFormat.parse(timeStr);
          
          return DateTime(year, month, day, time.hour, time.minute);
        }
      }
    } catch (e) {
      developer.log('Error parsing transaction date: $e', name: _logName);
    }
    
    // Fallback to SMS date
    return smsDate;
  }

  /// Get suggested category for M-Pesa transaction
  static String? suggestCategory(MpesaSmsTransaction transaction) {
    switch (transaction.type) {
      case MpesaTransactionType.paybill:
        return _categorizePaybill(transaction.recipient);
      case MpesaTransactionType.buyGoods:
        return _categorizeBuyGoods(transaction.recipient);
      case MpesaTransactionType.airtime:
        return 'Utilities';
      case MpesaTransactionType.withdrawal:
        return 'Cash Withdrawal';
      case MpesaTransactionType.sent:
        return 'Transfer';
      case MpesaTransactionType.received:
        return 'Income';
      case MpesaTransactionType.deposit:
        return 'Cash Deposit';
      default:
        return null;
    }
  }

  /// Categorize paybill transactions
  static String _categorizePaybill(String? recipient) {
    if (recipient == null) return 'Bills';
    
    String upperRecipient = recipient.toUpperCase();
    
    if (upperRecipient.contains('KENYA POWER') || upperRecipient.contains('KPLC')) {
      return 'Utilities';
    } else if (upperRecipient.contains('WATER') || upperRecipient.contains('NAIROBI WATER')) {
      return 'Utilities';
    } else if (upperRecipient.contains('SCHOOL') || upperRecipient.contains('UNIVERSITY') || upperRecipient.contains('COLLEGE')) {
      return 'Education';
    } else if (upperRecipient.contains('HOSPITAL') || upperRecipient.contains('CLINIC') || upperRecipient.contains('MEDICAL')) {
      return 'Healthcare';
    } else if (upperRecipient.contains('INSURANCE')) {
      return 'Insurance';
    } else if (upperRecipient.contains('RENT') || upperRecipient.contains('HOUSING')) {
      return 'Housing';
    } else {
      return 'Bills';
    }
  }

  /// Categorize buy goods transactions
  static String _categorizeBuyGoods(String? recipient) {
    if (recipient == null) return 'Shopping';
    
    String upperRecipient = recipient.toUpperCase();
    
    if (upperRecipient.contains('JAVA') || upperRecipient.contains('CAFE') || upperRecipient.contains('RESTAURANT')) {
      return 'Food & Dining';
    } else if (upperRecipient.contains('SUPERMARKET') || upperRecipient.contains('TUSKYS') || upperRecipient.contains('NAIVAS')) {
      return 'Groceries';
    } else if (upperRecipient.contains('PETROL') || upperRecipient.contains('FUEL') || upperRecipient.contains('SHELL') || upperRecipient.contains('TOTAL')) {
      return 'Transport';
    } else if (upperRecipient.contains('PHARMACY') || upperRecipient.contains('CHEMIST')) {
      return 'Healthcare';
    } else if (upperRecipient.contains('MATATU') || upperRecipient.contains('BUS') || upperRecipient.contains('UBER')) {
      return 'Transport';
    } else {
      return 'Shopping';
    }
  }
}
