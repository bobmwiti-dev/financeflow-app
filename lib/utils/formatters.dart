import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'currency_extensions.dart';

class Formatters {
  static String formatCurrency(double amount, BuildContext context, {String? symbol}) {
    // Using CurrencyService for consistent currency formatting
    return amount.toCurrency();
  }

  static String formatDate(DateTime date, {String format = 'MMM d, yyyy'}) {
    return DateFormat(format).format(date);
  }

  // Add other formatters as needed
}
