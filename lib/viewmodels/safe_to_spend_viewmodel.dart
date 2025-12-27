import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/safe_to_spend_service.dart';

class SafeToSpendViewModel extends ChangeNotifier {
  double _safeToSpendAmount = 0.0;
  double get safeToSpendAmount => _safeToSpendAmount;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  final SafeToSpendService _service;

  SafeToSpendViewModel() : _service = SafeToSpendService(uid: FirebaseAuth.instance.currentUser!.uid);

  Future<void> fetchSafeToSpendAmount() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _safeToSpendAmount = await _service.calculateSafeToSpend();
    } catch (e) {
      _error = 'Failed to calculate Safe-to-Spend amount.';
      debugPrint(e.toString());
    }

    _isLoading = false;
    notifyListeners();
  }
}
