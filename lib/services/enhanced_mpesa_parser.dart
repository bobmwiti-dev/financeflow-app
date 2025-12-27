import 'dart:isolate';
import 'dart:math' as math;
import 'package:logging/logging.dart';
import '../models/mpesa_sms_model.dart';

/// High-performance M-Pesa SMS parser with machine learning and format adaptation
class EnhancedMpesaParser {
  static const String _logName = 'EnhancedMpesaParser';
  static final Logger _logger = Logger(_logName);

  // Cached compiled regex patterns for performance
  static final Map<String, List<RegExp>> _compiledPatterns = {};
  
  // Machine learning patterns learned from user corrections
  static final Map<String, double> _learnedPatterns = {};
  
  // Performance metrics
  static final Map<String, int> _performanceMetrics = {
    'totalParsed': 0,
    'successfulParsed': 0,
    'averageParseTime': 0,
  };

  /// Enhanced SMS parsing patterns with multiple language and format support
  static final Map<String, List<String>> _smsPatternTemplates = {
    'sent_english_v1': [
      r'Confirmed\. Ksh([\d,]+\.?\d*) sent to (.+?) on (\d+/\d+/\d+) at (\d+:\d+\s*[AP]M)\.? New M-PESA balance is Ksh([\d,]+\.?\d*)',
      r'([A-Z0-9]+) Confirmed\. Ksh([\d,]+\.?\d*) sent to (.+?) on (\d+/\d+/\d+) at (\d+:\d+\s*[AP]M)\. New balance is Ksh([\d,]+\.?\d*)',
    ],
    'sent_english_v2': [
      r'Confirmed\. You have sent Ksh([\d,]+\.?\d*) to (.+?) on (\d+/\d+/\d+)\. New balance: Ksh([\d,]+\.?\d*)',
      r'Transaction successful\. Ksh([\d,]+\.?\d*) sent to (.+?)\. Balance: Ksh([\d,]+\.?\d*)',
    ],
    'received_english_v1': [
      r'([A-Z0-9]+) Confirmed\. You have received Ksh([\d,]+\.?\d*) from (.+?) on (\d+/\d+/\d+) at (\d+:\d+\s*[AP]M)\. New M-PESA balance is Ksh([\d,]+\.?\d*)',
      r'Confirmed\. Ksh([\d,]+\.?\d*) received from (.+?) on (\d+/\d+/\d+) at (\d+:\d+\s*[AP]M)\. New balance is Ksh([\d,]+\.?\d*)',
    ],
    'received_english_v2': [
      r'You have received Ksh([\d,]+\.?\d*) from (.+?) on (\d+/\d+/\d+)\. New balance: Ksh([\d,]+\.?\d*)',
      r'Money received\. Ksh([\d,]+\.?\d*) from (.+?)\. Balance: Ksh([\d,]+\.?\d*)',
    ],
    'paybill_english_v1': [
      r'([A-Z0-9]+) Confirmed\. Ksh([\d,]+\.?\d*) paid to (.+?)\. on (\d+/\d+/\d+) at (\d+:\d+\s*[AP]M)\. New M-PESA balance is Ksh([\d,]+\.?\d*)',
      r'Confirmed\. Ksh([\d,]+\.?\d*) paid to (.+?) on (\d+/\d+/\d+)\. New balance is Ksh([\d,]+\.?\d*)',
    ],
    'paybill_english_v2': [
      r'Payment successful\. Ksh([\d,]+\.?\d*) to (.+?)\. Balance: Ksh([\d,]+\.?\d*)',
      r'Bill payment confirmed\. Ksh([\d,]+\.?\d*) paid to (.+?)\. New balance: Ksh([\d,]+\.?\d*)',
    ],
    'sent_swahili_v1': [
      r'Imethibitishwa\. Ksh([\d,]+\.?\d*) imetumwa kwa (.+?) tarehe (\d+/\d+/\d+) saa (\d+:\d+\s*[AP]M)\. Salio jipya la M-PESA ni Ksh([\d,]+\.?\d*)',
      r'([A-Z0-9]+) Imethibitishwa\. Ksh([\d,]+\.?\d*) imetumwa kwa (.+?) tarehe (\d+/\d+/\d+)',
    ],
    'received_swahili_v1': [
      r'Imethibitishwa\. Ksh([\d,]+\.?\d*) imepokewa kutoka kwa (.+?) tarehe (\d+/\d+/\d+) saa (\d+:\d+\s*[AP]M)\. Salio jipya la M-PESA ni Ksh([\d,]+\.?\d*)',
      r'([A-Z0-9]+) Imethibitishwa\. Ksh([\d,]+\.?\d*) imepokewa kutoka (.+?) tarehe (\d+/\d+/\d+)',
    ],
    // New formats that might appear
    'airtime_english': [
      r'Confirmed\. Ksh([\d,]+\.?\d*) airtime for (.+?) on (\d+/\d+/\d+)\. New balance is Ksh([\d,]+\.?\d*)',
      r'Airtime purchase successful\. Ksh([\d,]+\.?\d*) for (.+?)\. Balance: Ksh([\d,]+\.?\d*)',
    ],
    'withdraw_english': [
      r'Confirmed\. Ksh([\d,]+\.?\d*) withdrawn from (.+?) on (\d+/\d+/\d+)\. New balance is Ksh([\d,]+\.?\d*)',
      r'Cash withdrawal successful\. Ksh([\d,]+\.?\d*) from agent (.+?)\. Balance: Ksh([\d,]+\.?\d*)',
    ],
  };

  /// Initialize compiled patterns for better performance
  static void initializePatterns() {
    final stopwatch = Stopwatch()..start();
    
    for (final category in _smsPatternTemplates.keys) {
      _compiledPatterns[category] = _smsPatternTemplates[category]!
          .map((pattern) => RegExp(pattern, caseSensitive: false))
          .toList();
    }
    
    stopwatch.stop();
    _logger.info('Compiled ${_compiledPatterns.length} pattern categories in ${stopwatch.elapsedMilliseconds}ms');
  }

  /// High-performance batch SMS parsing using isolates for large datasets
  static Future<List<MpesaSmsTransaction>> parseBatchSms(
    List<Map<String, dynamic>> smsData,
    {bool useIsolate = true}
  ) async {
    if (smsData.isEmpty) return [];
    
    final stopwatch = Stopwatch()..start();
    
    try {
      List<MpesaSmsTransaction> results;
      
      if (useIsolate && smsData.length > 100) {
        // Use isolate for large batches to avoid blocking UI
        results = await _parseBatchInIsolate(smsData);
      } else {
        // Parse directly for smaller batches
        results = _parseBatchDirect(smsData);
      }
      
      stopwatch.stop();
      _updatePerformanceMetrics(smsData.length, results.length, stopwatch.elapsedMilliseconds);
      
      return results;
    } catch (e) {
      _logger.severe('Error in batch SMS parsing: $e');
      return [];
    }
  }

  /// Parse SMS batch in isolate for better performance
  static Future<List<MpesaSmsTransaction>> _parseBatchInIsolate(
    List<Map<String, dynamic>> smsData
  ) async {
    final receivePort = ReceivePort();
    
    await Isolate.spawn(_isolateEntryPoint, {
      'sendPort': receivePort.sendPort,
      'smsData': smsData,
      'patterns': _smsPatternTemplates,
    });
    
    final result = await receivePort.first as List<Map<String, dynamic>>;
    return result.map((data) => MpesaSmsTransaction.fromMap(data)).toList();
  }

  /// Isolate entry point for batch processing
  static void _isolateEntryPoint(Map<String, dynamic> args) {
    final sendPort = args['sendPort'] as SendPort;
    final smsData = args['smsData'] as List<Map<String, dynamic>>;
    final patterns = args['patterns'] as Map<String, List<String>>;
    
    // Compile patterns in isolate
    final compiledPatterns = <String, List<RegExp>>{};
    for (final category in patterns.keys) {
      compiledPatterns[category] = patterns[category]!
          .map((pattern) => RegExp(pattern, caseSensitive: false))
          .toList();
    }
    
    // Parse SMS messages
    final results = <Map<String, dynamic>>[];
    for (final sms in smsData) {
      final transaction = _parseSingleSms(
        sms['body'] as String,
        sms['sender'] as String,
        DateTime.parse(sms['timestamp'] as String),
        compiledPatterns,
      );
      
      if (transaction != null) {
        results.add(transaction.toMap());
      }
    }
    
    sendPort.send(results);
  }

  /// Parse SMS batch directly (for smaller batches)
  static List<MpesaSmsTransaction> _parseBatchDirect(List<Map<String, dynamic>> smsData) {
    if (_compiledPatterns.isEmpty) initializePatterns();
    
    final results = <MpesaSmsTransaction>[];
    
    for (final sms in smsData) {
      final transaction = _parseSingleSms(
        sms['body'] as String,
        sms['sender'] as String,
        DateTime.parse(sms['timestamp'] as String),
        _compiledPatterns,
      );
      
      if (transaction != null) {
        results.add(transaction);
      }
    }
    
    return results;
  }

  /// Parse a single SMS with enhanced pattern matching
  static MpesaSmsTransaction? _parseSingleSms(
    String smsBody,
    String sender,
    DateTime timestamp,
    Map<String, List<RegExp>> patterns,
  ) {
    // Clean and normalize SMS text
    final cleanSms = _cleanSmsText(smsBody);
    
    // Try parsing with different pattern categories
    for (final category in patterns.keys) {
      for (final pattern in patterns[category]!) {
        final match = pattern.firstMatch(cleanSms);
        if (match != null) {
          final transaction = _extractTransactionFromMatch(
            match, category, sender, timestamp, cleanSms
          );
          
          if (transaction != null) {
            // Apply machine learning enhancements
            return _applyMachineLearning(transaction);
          }
        }
      }
    }
    
    // Try adaptive parsing for unknown formats
    return _adaptiveParsing(cleanSms, sender, timestamp);
  }

  /// Clean and normalize SMS text for better parsing
  static String _cleanSmsText(String smsBody) {
    return smsBody
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .replaceAll(RegExp(r'[^\w\s.,:/()-]'), '') // Remove special chars
        .trim();
  }

  /// Extract transaction data from regex match
  static MpesaSmsTransaction? _extractTransactionFromMatch(
    RegExpMatch match,
    String category,
    String sender,
    DateTime timestamp,
    String originalSms,
  ) {
    try {
      String transactionId = _generateTransactionId();
      double amount = 0.0;
      String? recipient;
      String? senderName;
      double newBalance = 0.0;
      MpesaTransactionType type = MpesaTransactionType.unknown;
      
      // Extract based on category and match groups
      if (category.contains('sent')) {
        type = MpesaTransactionType.sent;
        if (match.groupCount >= 5) {
          if (match.group(1)?.contains(RegExp(r'^[A-Z0-9]+$')) == true) {
            // Has transaction ID
            transactionId = match.group(1) ?? transactionId;
            amount = _parseAmount(match.group(2) ?? '0');
            recipient = match.group(3);
            newBalance = _parseAmount(match.group(6) ?? '0');
          } else {
            // No transaction ID
            amount = _parseAmount(match.group(1) ?? '0');
            recipient = match.group(2);
            newBalance = _parseAmount(match.group(5) ?? '0');
          }
        }
      } else if (category.contains('received')) {
        type = MpesaTransactionType.received;
        if (match.groupCount >= 5) {
          if (match.group(1)?.contains(RegExp(r'^[A-Z0-9]+$')) == true) {
            transactionId = match.group(1) ?? transactionId;
            amount = _parseAmount(match.group(2) ?? '0');
            senderName = match.group(3);
            newBalance = _parseAmount(match.group(6) ?? '0');
          } else {
            amount = _parseAmount(match.group(1) ?? '0');
            senderName = match.group(2);
            newBalance = _parseAmount(match.group(4) ?? '0');
          }
        }
      } else if (category.contains('paybill')) {
        type = MpesaTransactionType.paybill;
        if (match.groupCount >= 5) {
          transactionId = match.group(1) ?? transactionId;
          amount = _parseAmount(match.group(2) ?? '0');
          recipient = match.group(3);
          newBalance = _parseAmount(match.group(6) ?? '0');
        }
      } else if (category.contains('airtime')) {
        type = MpesaTransactionType.airtime;
        amount = _parseAmount(match.group(1) ?? '0');
        recipient = match.group(2);
        newBalance = _parseAmount(match.group(4) ?? '0');
      } else if (category.contains('withdraw')) {
        type = MpesaTransactionType.withdrawal;
        amount = _parseAmount(match.group(1) ?? '0');
        recipient = match.group(2);
        newBalance = _parseAmount(match.group(4) ?? '0');
      }
      
      // Calculate confidence based on match quality
      final confidence = _calculateParsingConfidence(match, category);
      
      return MpesaSmsTransaction(
        mpesaCode: transactionId,
        originalSms: originalSms,
        type: type,
        amount: amount,
        recipient: recipient,
        sender: senderName,
        balance: newBalance,
        transactionDate: timestamp,
        smsDate: timestamp,
        confidence: confidence,
      );
    } catch (e) {
      _logger.warning('Error extracting transaction from match: $e');
      return null;
    }
  }

  /// Adaptive parsing for unknown SMS formats
  static MpesaSmsTransaction? _adaptiveParsing(
    String cleanSms,
    String sender,
    DateTime timestamp,
  ) {
    // Try to extract basic information using heuristics
    final amountMatch = RegExp(r'Ksh([\d,]+\.?\d*)').firstMatch(cleanSms);
    if (amountMatch == null) return null;
    
    final amount = _parseAmount(amountMatch.group(1) ?? '0');
    if (amount <= 0) return null;
    
    // Determine transaction type based on keywords
    MpesaTransactionType type = MpesaTransactionType.unknown;
    String? recipient;
    
    if (cleanSms.toUpperCase().contains('SENT TO')) {
      type = MpesaTransactionType.sent;
      final recipientMatch = RegExp(r'sent to (.+?)(?:\s+on|\s+\.|$)', caseSensitive: false)
          .firstMatch(cleanSms);
      recipient = recipientMatch?.group(1)?.trim();
    } else if (cleanSms.toUpperCase().contains('RECEIVED FROM')) {
      type = MpesaTransactionType.received;
      final senderMatch = RegExp(r'received from (.+?)(?:\s+on|\s+\.|$)', caseSensitive: false)
          .firstMatch(cleanSms);
      recipient = senderMatch?.group(1)?.trim();
    } else if (cleanSms.toUpperCase().contains('PAID TO')) {
      type = MpesaTransactionType.paybill;
      final merchantMatch = RegExp(r'paid to (.+?)(?:\s+on|\s+\.|$)', caseSensitive: false)
          .firstMatch(cleanSms);
      recipient = merchantMatch?.group(1)?.trim();
    }
    
    if (type == MpesaTransactionType.unknown) return null;
    
    // Extract balance if available
    final balanceMatch = RegExp(r'balance.*?Ksh([\d,]+\.?\d*)', caseSensitive: false)
        .firstMatch(cleanSms);
    final balance = balanceMatch != null ? _parseAmount(balanceMatch.group(1) ?? '0') : 0.0;
    
    return MpesaSmsTransaction(
      mpesaCode: _generateTransactionId(),
      originalSms: cleanSms,
      type: type,
      amount: amount,
      recipient: recipient,
      balance: balance,
      transactionDate: timestamp,
      smsDate: timestamp,
      confidence: 0.6, // Lower confidence for adaptive parsing
    );
  }

  /// Apply machine learning enhancements to parsed transaction
  static MpesaSmsTransaction _applyMachineLearning(MpesaSmsTransaction transaction) {
    // Check learned patterns for category enhancement
    String? learnedCategory = _findLearnedCategory(transaction);
    
    if (learnedCategory != null) {
      return transaction.copyWith(
        category: learnedCategory,
        confidence: math.min(transaction.confidence + 0.15, 1.0),
        isValidated: true,
      );
    }
    
    return transaction;
  }

  /// Find learned category from machine learning patterns
  static String? _findLearnedCategory(MpesaSmsTransaction transaction) {
    final recipient = transaction.recipient?.toUpperCase() ?? '';
    final smsWords = transaction.originalSms.toUpperCase().split(RegExp(r'\s+'));
    
    double bestScore = 0.0;
    String? bestCategory;
    
    for (final pattern in _learnedPatterns.entries) {
      final patternWords = pattern.key.split('|');
      double score = 0.0;
      
      for (final word in patternWords) {
        if (recipient.contains(word) || smsWords.contains(word)) {
          score += pattern.value;
        }
      }
      
      if (score > bestScore) {
        bestScore = score;
        bestCategory = patternWords.last; // Last word is typically the category
      }
    }
    
    return bestScore > 0.7 ? bestCategory : null;
  }

  /// Calculate parsing confidence based on match quality
  static double _calculateParsingConfidence(RegExpMatch match, String category) {
    double confidence = 0.8; // Base confidence
    
    // Higher confidence for more complete matches
    if (match.groupCount >= 6) confidence += 0.1;
    if (match.groupCount >= 4) confidence += 0.05;
    
    // Higher confidence for English patterns (more standardized)
    if (category.contains('english')) confidence += 0.05;
    
    // Higher confidence for newer format versions
    if (category.contains('v2')) confidence += 0.03;
    
    // Higher confidence for paybill (more structured)
    if (category.contains('paybill')) confidence += 0.05;
    
    return math.min(confidence, 1.0);
  }

  /// Parse amount from string, handling commas and decimals
  static double _parseAmount(String amountStr) {
    try {
      final cleanAmount = amountStr.replaceAll(',', '').trim();
      return double.parse(cleanAmount);
    } catch (e) {
      _logger.warning('Failed to parse amount: $amountStr');
      return 0.0;
    }
  }

  /// Generate unique transaction ID
  static String _generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = math.Random().nextInt(9999);
    return 'MPESA_${timestamp}_$random';
  }

  /// Update performance metrics
  static void _updatePerformanceMetrics(int total, int successful, int timeMs) {
    _performanceMetrics['totalParsed'] = (_performanceMetrics['totalParsed'] ?? 0) + total;
    _performanceMetrics['successfulParsed'] = (_performanceMetrics['successfulParsed'] ?? 0) + successful;
    
    final currentAvg = _performanceMetrics['averageParseTime'] ?? 0;
    final newAvg = (currentAvg + timeMs) ~/ 2;
    _performanceMetrics['averageParseTime'] = newAvg;
  }

  /// Get performance metrics
  static Map<String, int> getPerformanceMetrics() => Map.from(_performanceMetrics);

  /// Learn from user correction
  static void learnFromCorrection(MpesaSmsTransaction originalTransaction, MpesaSmsTransaction correctedTransaction) {
    if (correctedTransaction.category == null) return;
    
    final recipient = originalTransaction.recipient?.toUpperCase() ?? '';
    final smsWords = originalTransaction.originalSms.toUpperCase().split(RegExp(r'\s+'));
    
    // Create learning pattern
    final keyWords = <String>[];
    if (recipient.isNotEmpty) keyWords.add(recipient);
    keyWords.addAll(smsWords.where((word) => word.length > 3));
    keyWords.add(correctedTransaction.category!);
    
    final patternKey = keyWords.join('|');
    _learnedPatterns[patternKey] = (_learnedPatterns[patternKey] ?? 0.0) + 0.1;
    
    _logger.info('Learned pattern: $patternKey');
  }

  /// Handle new SMS format by creating adaptive patterns
  static void handleNewSmsFormat(String smsBody, MpesaSmsTransaction? expectedResult) {
    if (expectedResult == null) return;
    
    // Analyze the SMS structure and create new pattern
    final words = smsBody.split(RegExp(r'\s+'));
    final amountIndex = words.indexWhere((word) => word.contains('Ksh'));
    final balanceIndex = words.indexWhere((word) => word.toLowerCase().contains('balance'));
    
    if (amountIndex != -1 && balanceIndex != -1) {
      // Create new pattern template
      final patternTemplate = _createPatternFromStructure(words, amountIndex, balanceIndex, expectedResult.type);
      
      // Add to appropriate category
      final category = '${expectedResult.type.toString().split('.').last}_adaptive';
      if (!_smsPatternTemplates.containsKey(category)) {
        _smsPatternTemplates[category] = [];
      }
      _smsPatternTemplates[category]!.add(patternTemplate);
      
      // Recompile patterns
      _compiledPatterns[category] = [RegExp(patternTemplate, caseSensitive: false)];
      
      _logger.info('Created new adaptive pattern for category: $category');
    }
  }

  /// Create pattern template from SMS structure analysis
  static String _createPatternFromStructure(
    List<String> words,
    int amountIndex,
    int balanceIndex,
    MpesaTransactionType type,
  ) {
    final pattern = StringBuffer();
    
    for (int i = 0; i < words.length; i++) {
      if (i == amountIndex) {
        pattern.write(r'Ksh([\d,]+\.?\d*)');
      } else if (i == balanceIndex) {
        pattern.write(r'balance.*?Ksh([\d,]+\.?\d*)');
      } else if (words[i].contains(RegExp(r'\d+/\d+/\d+'))) {
        pattern.write(r'(\d+/\d+/\d+)');
      } else if (words[i].contains(RegExp(r'\d+:\d+'))) {
        pattern.write(r'(\d+:\d+\s*[AP]M)');
      } else if (type == MpesaTransactionType.sent && 
                 (words[i].toLowerCase() == 'to' || words[i].toLowerCase() == 'kwa')) {
        pattern.write('${words[i]} (.+?)');
        i++; // Skip the next word as it's captured in the group
      } else if (type == MpesaTransactionType.received && 
                 (words[i].toLowerCase() == 'from' || words[i].toLowerCase() == 'kutoka')) {
        pattern.write('${words[i]} (.+?)');
        i++; // Skip the next word as it's captured in the group
      } else {
        pattern.write(RegExp.escape(words[i]));
      }
      
      if (i < words.length - 1) pattern.write(r'\s+');
    }
    
    return pattern.toString();
  }

  /// Clear learned patterns (for testing or reset)
  static void clearLearnedPatterns() {
    _learnedPatterns.clear();
    _logger.info('Cleared all learned patterns');
  }

  /// Export learned patterns for backup
  static Map<String, double> exportLearnedPatterns() => Map.from(_learnedPatterns);

  /// Import learned patterns from backup
  static void importLearnedPatterns(Map<String, double> patterns) {
    _learnedPatterns.clear();
    _learnedPatterns.addAll(patterns);
    _logger.info('Imported ${patterns.length} learned patterns');
  }
}
