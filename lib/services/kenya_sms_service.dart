import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// SMS service optimized for Kenya market (Safaricom & Airtel)
class KenyaSmsService {
  static const String _logName = 'KenyaSmsService';
  static final Logger _logger = Logger(_logName);
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // SMS Provider configurations for Kenya
  static const Map<String, SmsProviderConfig> _providers = {
    'africastalking': SmsProviderConfig(
      name: 'Africa\'s Talking',
      baseUrl: 'https://api.africastalking.com/version1/messaging',
      supportedNetworks: ['Safaricom', 'Airtel', 'Telkom'],
      costPerSms: 0.8, // KES
      reliability: 0.95,
    ),
    'twilio': SmsProviderConfig(
      name: 'Twilio',
      baseUrl: 'https://api.twilio.com/2010-04-01/Accounts',
      supportedNetworks: ['Safaricom', 'Airtel'],
      costPerSms: 2.5, // KES
      reliability: 0.98,
    ),
    'safaricom': SmsProviderConfig(
      name: 'Safaricom SMS API',
      baseUrl: 'https://api.safaricom.co.ke/mpesa/sms/v1',
      supportedNetworks: ['Safaricom'],
      costPerSms: 0.5, // KES
      reliability: 0.99,
    ),
  };

  /// Send SMS notification with Kenya-optimized routing
  static Future<SmsResult> sendSmsNotification({
    required String phoneNumber,
    required String message,
    required String notificationType,
    String? preferredProvider,
  }) async {
    try {
      // Validate and format Kenyan phone number
      final formattedNumber = _formatKenyanPhoneNumber(phoneNumber);
      if (formattedNumber == null) {
        return SmsResult.failure('Invalid Kenyan phone number format');
      }

      // Detect network provider
      final networkProvider = _detectNetworkProvider(formattedNumber);
      
      // Select best SMS provider for this network
      final smsProvider = _selectOptimalProvider(networkProvider, preferredProvider);
      
      // Send SMS using selected provider
      final result = await _sendViProvider(
        provider: smsProvider,
        phoneNumber: formattedNumber,
        message: message,
        notificationType: notificationType,
      );

      // Log SMS for analytics and compliance
      await _logSmsTransaction(
        phoneNumber: formattedNumber,
        message: message,
        provider: smsProvider,
        result: result,
        notificationType: notificationType,
      );

      return result;
    } catch (e) {
      _logger.severe('Error sending SMS notification: $e');
      return SmsResult.failure('Failed to send SMS: $e');
    }
  }

  /// Format phone number to Kenyan standard (+254XXXXXXXXX)
  static String? _formatKenyanPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // Handle different Kenyan phone number formats
    if (cleaned.startsWith('254') && cleaned.length == 12) {
      return '+$cleaned'; // Already in international format
    } else if (cleaned.startsWith('0') && cleaned.length == 10) {
      return '+254${cleaned.substring(1)}'; // Convert from local format
    } else if (cleaned.length == 9) {
      return '+254$cleaned'; // Missing leading zero
    }
    
    return null; // Invalid format
  }

  /// Detect network provider from phone number
  static KenyanNetworkProvider _detectNetworkProvider(String phoneNumber) {
    // Extract the network prefix (after +254)
    final prefix = phoneNumber.substring(4, 7);
    
    // Safaricom prefixes
    if (['701', '702', '703', '704', '705', '706', '707', '708', '709', 
         '710', '711', '712', '713', '714', '715', '716', '717', '718', '719',
         '720', '721', '722', '723', '724', '725', '726', '727', '728', '729'].contains(prefix)) {
      return KenyanNetworkProvider.safaricom;
    }
    
    // Airtel prefixes
    if (['730', '731', '732', '733', '734', '735', '736', '737', '738', '739',
         '750', '751', '752', '753', '754', '755', '756', '757', '758', '759'].contains(prefix)) {
      return KenyanNetworkProvider.airtel;
    }
    
    // Telkom prefixes
    if (['770', '771', '772', '773', '774', '775', '776', '777', '778', '779'].contains(prefix)) {
      return KenyanNetworkProvider.telkom;
    }
    
    return KenyanNetworkProvider.unknown;
  }

  /// Select optimal SMS provider based on network and preferences
  static String _selectOptimalProvider(KenyanNetworkProvider network, String? preferredProvider) {
    // Use preferred provider if specified and supports the network
    if (preferredProvider != null && _providers.containsKey(preferredProvider)) {
      final provider = _providers[preferredProvider]!;
      if (provider.supportsNetwork(network)) {
        return preferredProvider;
      }
    }
    
    // Select best provider based on network
    switch (network) {
      case KenyanNetworkProvider.safaricom:
        // Prefer Safaricom's own API for best delivery rates
        return 'safaricom';
      case KenyanNetworkProvider.airtel:
        // Africa's Talking has good Airtel coverage
        return 'africastalking';
      case KenyanNetworkProvider.telkom:
        // Africa's Talking supports Telkom
        return 'africastalking';
      default:
        // Default to most reliable provider
        return 'africastalking';
    }
  }

  /// Send SMS via specific provider
  static Future<SmsResult> _sendViProvider({
    required String provider,
    required String phoneNumber,
    required String message,
    required String notificationType,
  }) async {
    switch (provider) {
      case 'africastalking':
        return await _sendViaAfricasTalking(phoneNumber, message);
      case 'twilio':
        return await _sendViaTwilio(phoneNumber, message);
      case 'safaricom':
        return await _sendViaSafaricom(phoneNumber, message);
      default:
        return SmsResult.failure('Unknown SMS provider: $provider');
    }
  }

  /// Send SMS via Africa's Talking (Popular in Kenya)
  static Future<SmsResult> _sendViaAfricasTalking(String phoneNumber, String message) async {
    try {
      // Get API credentials from environment or Firebase config
      final apiKey = await _getApiKey('africastalking_api_key');
      final username = await _getApiKey('africastalking_username');
      
      if (apiKey == null || username == null) {
        return SmsResult.failure('Africa\'s Talking API credentials not configured');
      }

      final response = await http.post(
        Uri.parse(_providers['africastalking']!.baseUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
          'apiKey': apiKey,
        },
        body: {
          'username': username,
          'to': phoneNumber,
          'message': message,
          'from': 'FinanceFlow', // Your app name (max 11 chars)
        },
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        final smsData = responseData['SMSMessageData'];
        
        if (smsData['Recipients'] != null && smsData['Recipients'].isNotEmpty) {
          final recipient = smsData['Recipients'][0];
          if (recipient['status'] == 'Success') {
            return SmsResult.success(
              messageId: recipient['messageId'],
              cost: recipient['cost'],
              provider: 'Africa\'s Talking',
            );
          }
        }
      }
      
      return SmsResult.failure('Failed to send via Africa\'s Talking: ${response.body}');
    } catch (e) {
      return SmsResult.failure('Africa\'s Talking error: $e');
    }
  }

  /// Send SMS via Twilio (International reliability)
  static Future<SmsResult> _sendViaTwilio(String phoneNumber, String message) async {
    try {
      final accountSid = await _getApiKey('twilio_account_sid');
      final authToken = await _getApiKey('twilio_auth_token');
      final fromNumber = await _getApiKey('twilio_from_number');
      
      if (accountSid == null || authToken == null || fromNumber == null) {
        return SmsResult.failure('Twilio API credentials not configured');
      }

      final credentials = base64Encode(utf8.encode('$accountSid:$authToken'));
      
      final response = await http.post(
        Uri.parse('${_providers['twilio']!.baseUrl}/$accountSid/Messages.json'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'From': fromNumber,
          'To': phoneNumber,
          'Body': message,
        },
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return SmsResult.success(
          messageId: responseData['sid'],
          cost: responseData['price'] ?? '0',
          provider: 'Twilio',
        );
      }
      
      return SmsResult.failure('Failed to send via Twilio: ${response.body}');
    } catch (e) {
      return SmsResult.failure('Twilio error: $e');
    }
  }

  /// Send SMS via Safaricom SMS API (Best for Safaricom numbers)
  static Future<SmsResult> _sendViaSafaricom(String phoneNumber, String message) async {
    try {
      // Note: This requires Safaricom developer account and approval
      final accessToken = await _getSafaricomAccessToken();
      if (accessToken == null) {
        return SmsResult.failure('Safaricom API access token not available');
      }

      final response = await http.post(
        Uri.parse('${_providers['safaricom']!.baseUrl}/send'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'to': phoneNumber,
          'message': message,
          'sender_id': 'FinanceFlow',
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return SmsResult.success(
          messageId: responseData['message_id'],
          cost: '0.50', // Safaricom rate
          provider: 'Safaricom',
        );
      }
      
      return SmsResult.failure('Failed to send via Safaricom: ${response.body}');
    } catch (e) {
      return SmsResult.failure('Safaricom error: $e');
    }
  }

  /// Get Safaricom access token (OAuth)
  static Future<String?> _getSafaricomAccessToken() async {
    try {
      final consumerKey = await _getApiKey('safaricom_consumer_key');
      final consumerSecret = await _getApiKey('safaricom_consumer_secret');
      
      if (consumerKey == null || consumerSecret == null) return null;

      final credentials = base64Encode(utf8.encode('$consumerKey:$consumerSecret'));
      
      final response = await http.get(
        Uri.parse('https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials'),
        headers: {
          'Authorization': 'Basic $credentials',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['access_token'];
      }
      
      return null;
    } catch (e) {
      _logger.warning('Failed to get Safaricom access token: $e');
      return null;
    }
  }

  /// Get API key from secure storage (Firebase Remote Config or Firestore)
  static Future<String?> _getApiKey(String keyName) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      // In production, use Firebase Remote Config or secure environment variables
      // For now, using Firestore (ensure proper security rules)
      final doc = await _firestore
          .collection('app_config')
          .doc('sms_credentials')
          .get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data[keyName] as String?;
      }
      
      return null;
    } catch (e) {
      _logger.warning('Failed to get API key $keyName: $e');
      return null;
    }
  }

  /// Log SMS transaction for analytics and compliance
  static Future<void> _logSmsTransaction({
    required String phoneNumber,
    required String message,
    required String provider,
    required SmsResult result,
    required String notificationType,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('sms_logs')
          .add({
            'phoneNumber': phoneNumber,
            'messageLength': message.length,
            'provider': provider,
            'success': result.success,
            'messageId': result.messageId,
            'cost': result.cost,
            'notificationType': notificationType,
            'timestamp': FieldValue.serverTimestamp(),
            'errorMessage': result.errorMessage,
          });
    } catch (e) {
      _logger.warning('Failed to log SMS transaction: $e');
    }
  }

  /// Get SMS delivery status (for supported providers)
  static Future<SmsDeliveryStatus> getDeliveryStatus(String messageId, String provider) async {
    // Implementation depends on provider's delivery receipt API
    // This is a placeholder for future enhancement
    return SmsDeliveryStatus.unknown;
  }

  /// Get SMS sending statistics for analytics
  static Future<Map<String, dynamic>> getSmsStatistics() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return {};

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('sms_logs')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 30))
          ))
          .get();

      final logs = snapshot.docs.map((doc) => doc.data()).toList();
      
      return {
        'totalSent': logs.length,
        'successRate': logs.where((log) => log['success'] == true).length / logs.length,
        'totalCost': logs.fold<double>(0.0, (total, log) => 
          total + (double.tryParse(log['cost']?.toString() ?? '0') ?? 0.0)),
        'providerBreakdown': _calculateProviderBreakdown(logs),
        'notificationTypeBreakdown': _calculateNotificationTypeBreakdown(logs),
      };
    } catch (e) {
      _logger.warning('Failed to get SMS statistics: $e');
      return {};
    }
  }

  static Map<String, int> _calculateProviderBreakdown(List<Map<String, dynamic>> logs) {
    final breakdown = <String, int>{};
    for (final log in logs) {
      final provider = log['provider'] as String? ?? 'unknown';
      breakdown[provider] = (breakdown[provider] ?? 0) + 1;
    }
    return breakdown;
  }

  static Map<String, int> _calculateNotificationTypeBreakdown(List<Map<String, dynamic>> logs) {
    final breakdown = <String, int>{};
    for (final log in logs) {
      final type = log['notificationType'] as String? ?? 'unknown';
      breakdown[type] = (breakdown[type] ?? 0) + 1;
    }
    return breakdown;
  }
}

/// SMS provider configuration
class SmsProviderConfig {
  final String name;
  final String baseUrl;
  final List<String> supportedNetworks;
  final double costPerSms;
  final double reliability;

  const SmsProviderConfig({
    required this.name,
    required this.baseUrl,
    required this.supportedNetworks,
    required this.costPerSms,
    required this.reliability,
  });

  bool supportsNetwork(KenyanNetworkProvider network) {
    switch (network) {
      case KenyanNetworkProvider.safaricom:
        return supportedNetworks.contains('Safaricom');
      case KenyanNetworkProvider.airtel:
        return supportedNetworks.contains('Airtel');
      case KenyanNetworkProvider.telkom:
        return supportedNetworks.contains('Telkom');
      default:
        return false;
    }
  }
}

/// Kenyan mobile network providers
enum KenyanNetworkProvider {
  safaricom,
  airtel,
  telkom,
  unknown,
}

/// SMS sending result
class SmsResult {
  final bool success;
  final String? messageId;
  final String? cost;
  final String? provider;
  final String? errorMessage;

  SmsResult._({
    required this.success,
    this.messageId,
    this.cost,
    this.provider,
    this.errorMessage,
  });

  factory SmsResult.success({
    required String messageId,
    required String cost,
    required String provider,
  }) {
    return SmsResult._(
      success: true,
      messageId: messageId,
      cost: cost,
      provider: provider,
    );
  }

  factory SmsResult.failure(String errorMessage) {
    return SmsResult._(
      success: false,
      errorMessage: errorMessage,
    );
  }
}

/// SMS delivery status
enum SmsDeliveryStatus {
  delivered,
  pending,
  failed,
  unknown,
}
