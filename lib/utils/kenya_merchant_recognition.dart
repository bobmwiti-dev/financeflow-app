import 'package:flutter/material.dart';

class KenyaMerchantRecognition {
  static const Map<String, MerchantInfo> _kenyanMerchants = {
    // Supermarkets & Retail
    'nakumatt': MerchantInfo('Nakumatt', Icons.shopping_cart, Colors.red, 'Shopping'),
    'tuskys': MerchantInfo('Tuskys', Icons.shopping_cart, Colors.blue, 'Shopping'),
    'carrefour': MerchantInfo('Carrefour', Icons.shopping_cart, Colors.green, 'Shopping'),
    'naivas': MerchantInfo('Naivas', Icons.shopping_cart, Colors.orange, 'Shopping'),
    'quickmart': MerchantInfo('QuickMart', Icons.shopping_cart, Colors.purple, 'Shopping'),
    
    // Restaurants & Food
    'java house': MerchantInfo('Java House', Icons.coffee, Colors.brown, 'Food & Dining'),
    'kfc': MerchantInfo('KFC', Icons.fastfood, Colors.red, 'Food & Dining'),
    'pizza inn': MerchantInfo('Pizza Inn', Icons.local_pizza, Colors.orange, 'Food & Dining'),
    'artcaffe': MerchantInfo('ArtCaffe', Icons.coffee, Colors.green, 'Food & Dining'),
    'dormans': MerchantInfo('Dormans Coffee', Icons.coffee, Colors.brown, 'Food & Dining'),
    'chicken inn': MerchantInfo('Chicken Inn', Icons.fastfood, Colors.yellow, 'Food & Dining'),
    
    // Fuel Stations
    'shell': MerchantInfo('Shell', Icons.local_gas_station, Colors.red, 'Transport'),
    'total': MerchantInfo('Total Energies', Icons.local_gas_station, Colors.blue, 'Transport'),
    'kenol': MerchantInfo('Kenol Kobil', Icons.local_gas_station, Colors.green, 'Transport'),
    'rubis': MerchantInfo('Rubis', Icons.local_gas_station, Colors.orange, 'Transport'),
    
    // Banks
    'equity': MerchantInfo('Equity Bank', Icons.account_balance, Colors.red, 'Banking'),
    'kcb': MerchantInfo('KCB Bank', Icons.account_balance, Colors.blue, 'Banking'),
    'cooperative': MerchantInfo('Co-operative Bank', Icons.account_balance, Colors.orange, 'Banking'),
    'standard chartered': MerchantInfo('Standard Chartered', Icons.account_balance, Colors.blue, 'Banking'),
    'barclays': MerchantInfo('Absa Bank', Icons.account_balance, Colors.red, 'Banking'),
    
    // Utilities
    'kplc': MerchantInfo('Kenya Power', Icons.electrical_services, Colors.blue, 'Utilities'),
    'nairobi water': MerchantInfo('Nairobi Water', Icons.water_drop, Colors.blue, 'Utilities'),
    'safaricom': MerchantInfo('Safaricom', Icons.phone, Colors.green, 'Utilities'),
    'airtel': MerchantInfo('Airtel', Icons.phone, Colors.red, 'Utilities'),
    'telkom': MerchantInfo('Telkom', Icons.phone, Colors.orange, 'Utilities'),
    
    // Transport
    'uber': MerchantInfo('Uber', Icons.local_taxi, Colors.black, 'Transport'),
    'bolt': MerchantInfo('Bolt', Icons.local_taxi, Colors.green, 'Transport'),
    'little cab': MerchantInfo('Little Cab', Icons.local_taxi, Colors.yellow, 'Transport'),
    'matatu': MerchantInfo('Matatu', Icons.directions_bus, Colors.blue, 'Transport'),
    
    // Entertainment
    'imax': MerchantInfo('IMAX Cinema', Icons.movie, Colors.purple, 'Entertainment'),
    'century cinemax': MerchantInfo('Century Cinemax', Icons.movie, Colors.red, 'Entertainment'),
    'prestige plaza': MerchantInfo('Prestige Plaza', Icons.movie, Colors.blue, 'Entertainment'),
    
    // Education
    'university of nairobi': MerchantInfo('University of Nairobi', Icons.school, Colors.blue, 'Education'),
    'kenyatta university': MerchantInfo('Kenyatta University', Icons.school, Colors.green, 'Education'),
    'strathmore': MerchantInfo('Strathmore University', Icons.school, Colors.red, 'Education'),
    
    // Healthcare
    'aga khan': MerchantInfo('Aga Khan Hospital', Icons.local_hospital, Colors.green, 'Healthcare'),
    'nairobi hospital': MerchantInfo('Nairobi Hospital', Icons.local_hospital, Colors.blue, 'Healthcare'),
    'kenyatta hospital': MerchantInfo('Kenyatta Hospital', Icons.local_hospital, Colors.red, 'Healthcare'),
    
    // Shopping Malls
    'westgate': MerchantInfo('Westgate Mall', Icons.shopping_bag, Colors.blue, 'Shopping'),
    'sarit centre': MerchantInfo('Sarit Centre', Icons.shopping_bag, Colors.green, 'Shopping'),
    'village market': MerchantInfo('Village Market', Icons.shopping_bag, Colors.orange, 'Shopping'),
    'two rivers': MerchantInfo('Two Rivers Mall', Icons.shopping_bag, Colors.purple, 'Shopping'),
    
    // Government Services
    'kra': MerchantInfo('Kenya Revenue Authority', Icons.account_balance, Colors.green, 'Government'),
    'huduma centre': MerchantInfo('Huduma Centre', Icons.business, Colors.blue, 'Government'),
    'ntsa': MerchantInfo('NTSA', Icons.directions_car, Colors.orange, 'Government'),
  };

  static MerchantInfo? recognizeMerchant(String description) {
    final lowerDescription = description.toLowerCase();
    
    // Direct match first
    for (final entry in _kenyanMerchants.entries) {
      if (lowerDescription.contains(entry.key)) {
        return entry.value;
      }
    }
    
    // Pattern matching for common M-Pesa formats
    if (lowerDescription.contains('paybill') || lowerDescription.contains('buy goods')) {
      return _recognizeFromMPesaFormat(lowerDescription);
    }
    
    return null;
  }
  
  static MerchantInfo? _recognizeFromMPesaFormat(String description) {
    // Common M-Pesa paybill numbers and their merchants
    final paybillMerchants = {
      '888880': MerchantInfo('Kenya Power (KPLC)', Icons.electrical_services, Colors.blue, 'Utilities'),
      '300300': MerchantInfo('Equity Bank', Icons.account_balance, Colors.red, 'Banking'),
      '522522': MerchantInfo('KCB Bank', Icons.account_balance, Colors.blue, 'Banking'),
      '400200': MerchantInfo('Co-operative Bank', Icons.account_balance, Colors.orange, 'Banking'),
      '329329': MerchantInfo('Safaricom', Icons.phone, Colors.green, 'Utilities'),
      '100100': MerchantInfo('Airtel Money', Icons.phone, Colors.red, 'Utilities'),
    };
    
    for (final entry in paybillMerchants.entries) {
      if (description.contains(entry.key)) {
        return entry.value;
      }
    }
    
    return null;
  }
  
  static List<String> getPopularKenyanCategories() {
    return [
      'M-Pesa Transfer',
      'Matatu/Transport',
      'School Fees',
      'KPLC/Utilities',
      'Safaricom Airtime',
      'Grocery Shopping',
      'Fuel/Petrol',
      'Medical/Hospital',
      'Rent Payment',
      'Chama Contribution',
      'SACCO Savings',
      'Insurance Premium',
      'Government Services',
      'Church Offering',
      'Food & Dining',
      'Entertainment',
    ];
  }
  
  static String suggestCategory(String description) {
    final lowerDescription = description.toLowerCase();
    
    // Transport related
    if (lowerDescription.contains('matatu') || 
        lowerDescription.contains('uber') || 
        lowerDescription.contains('bolt') ||
        lowerDescription.contains('fuel') ||
        lowerDescription.contains('petrol')) {
      return 'Transport';
    }
    
    // Utilities
    if (lowerDescription.contains('kplc') || 
        lowerDescription.contains('safaricom') ||
        lowerDescription.contains('airtel') ||
        lowerDescription.contains('water')) {
      return 'Utilities';
    }
    
    // Education
    if (lowerDescription.contains('school') || 
        lowerDescription.contains('university') ||
        lowerDescription.contains('college') ||
        lowerDescription.contains('fees')) {
      return 'Education';
    }
    
    // Healthcare
    if (lowerDescription.contains('hospital') || 
        lowerDescription.contains('clinic') ||
        lowerDescription.contains('medical') ||
        lowerDescription.contains('pharmacy')) {
      return 'Healthcare';
    }
    
    // Food & Dining
    if (lowerDescription.contains('restaurant') || 
        lowerDescription.contains('cafe') ||
        lowerDescription.contains('food') ||
        lowerDescription.contains('java') ||
        lowerDescription.contains('kfc')) {
      return 'Food & Dining';
    }
    
    // Shopping
    if (lowerDescription.contains('nakumatt') || 
        lowerDescription.contains('tuskys') ||
        lowerDescription.contains('carrefour') ||
        lowerDescription.contains('shopping') ||
        lowerDescription.contains('mall')) {
      return 'Shopping';
    }
    
    return 'Other';
  }
}

class MerchantInfo {
  final String displayName;
  final IconData icon;
  final Color color;
  final String category;
  
  const MerchantInfo(this.displayName, this.icon, this.color, this.category);
}
