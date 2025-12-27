import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class SafeToSpendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _uid;

  SafeToSpendService({required String uid}) : _uid = uid;

  Future<double> calculateSafeToSpend() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      // 1. Calculate total income for the month
      final income = await _getMonthlyIncome(startOfMonth, endOfMonth);

      // 2. Calculate total bills for the month
      final billsTotal = await _getMonthlyBills(startOfMonth, endOfMonth);

      // 3. Calculate total discretionary spending for the month
      final spendingTotal = await _getMonthlySpending(startOfMonth, endOfMonth);

      // 4. Calculate Safe to Spend
      final safeToSpend = income - billsTotal - spendingTotal;

      return safeToSpend > 0 ? safeToSpend : 0;
    } catch (e) {
      debugPrint('Error calculating Safe-to-Spend: $e');
      return 0;
    }
  }

  Future<double> _getMonthlyIncome(DateTime start, DateTime end) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('transactions')
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end)
        .where('type', isEqualTo: 'TransactionType.income')
        .get();

    double total = 0;
    for (var doc in snapshot.docs) {
      total += (doc.data()['amount'] as num).toDouble();
    }
    return total;
  }

  Future<double> _getMonthlyBills(DateTime start, DateTime end) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('bills')
        .where('dueDate', isGreaterThanOrEqualTo: start)
        .where('dueDate', isLessThanOrEqualTo: end)
        .get();

    double total = 0;
    for (var doc in snapshot.docs) {
      total += (doc.data()['amount'] as num).toDouble();
    }
    return total;
  }

  Future<double> _getMonthlySpending(DateTime start, DateTime end) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('transactions')
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end)
        .where('type', isEqualTo: 'TransactionType.expense')
        .get();

    double total = 0;
    final billCategories = ['bills', 'rent', 'utilities', 'insurance', 'loan']; // Categories to exclude

    for (var doc in snapshot.docs) {
      final category = (doc.data()['category'] as String? ?? '').toLowerCase();
      if (!billCategories.contains(category)) {
        total += (doc.data()['amount'] as num).toDouble();
      }
    }
    return total;
  }


}
