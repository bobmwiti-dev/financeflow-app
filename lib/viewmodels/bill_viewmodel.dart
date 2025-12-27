import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/bill_model.dart';
import '../services/bill_service.dart';


class BillViewModel extends ChangeNotifier {
  final _billService = BillService.instance;
  final List<Bill> _bills = [];
  List<Bill> get bills => List.unmodifiable(_bills);

  double get totalRecurringBills {
    return _bills
        .where((bill) => bill.isRecurring)
        .fold(0.0, (total, bill) => total + bill.amount);
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadBills(String uid) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Listen to the bills stream and convert to Bill objects
      _billService.getUpcomingBills().listen((billsData) {
        _bills.clear();
        for (final billData in billsData) {
          try {
            final bill = Bill(
              id: billData['id'],
              name: billData['name'] ?? 'Unknown Bill',
              amount: (billData['amount'] as num?)?.toDouble() ?? 0.0,
              dueDate: (billData['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
              category: billData['category'],
              isRecurring: billData['isRecurring'] ?? false,
              frequency: billData['frequency'],
              autoPay: billData['autoPay'] ?? false,
            );
            _bills.add(bill);
          } catch (e) {
            debugPrint('Error parsing bill data: $e');
          }
        }
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error loading bills: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addBill(String uid, Bill bill) async {
    try {
      debugPrint('BillViewModel: Adding bill ${bill.name} for user $uid');
      
      final billId = await _billService.addBill(
        title: bill.name,
        amount: bill.amount,
        dueDate: bill.dueDate,
        category: bill.category ?? 'Other',
      );
      
      debugPrint('BillViewModel: BillService returned billId: $billId');
      
      if (billId != null) {
        debugPrint('BillViewModel: Bill added successfully, ID: $billId');
        // The bills will be automatically updated through the stream listener
        return true;
      }
      debugPrint('BillViewModel: Failed to add bill - billId is null');
      return false;
    } catch (e) {
      debugPrint('BillViewModel: Error adding bill: $e');
      return false;
    }
  }

  Future<List<Bill>> getUpcomingBills({int limit = 3}) async {
    try {
      // Get bills from the service stream and convert to Bill objects
      final billsData = await _billService.getUpcomingBills().first;
      final bills = <Bill>[];
      
      for (final billData in billsData.take(limit)) {
        try {
          final bill = Bill(
            id: billData['id'],
            name: billData['name'] ?? 'Unknown Bill',
            amount: (billData['amount'] as num?)?.toDouble() ?? 0.0,
            dueDate: (billData['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
            category: billData['category'],
            isRecurring: billData['isRecurring'] ?? false,
            frequency: billData['frequency'],
            autoPay: billData['autoPay'] ?? false,
          );
          bills.add(bill);
        } catch (e) {
          debugPrint('Error parsing bill data: $e');
        }
      }
      
      return bills;
    } catch (e) {
      debugPrint('Error fetching upcoming bills: $e');
      return [];
    }
  }
}
