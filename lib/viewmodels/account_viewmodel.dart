import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/account_model.dart';
import '../models/transaction_model.dart';
import '../models/income_source_model.dart';
import '../services/balance_service.dart';

/// ViewModel for managing accounts and real balance calculations
class AccountViewModel extends ChangeNotifier {
  static const String _accountsKey = 'user_accounts';
  static const String _defaultAccountKey = 'default_account_id';
  
  List<Account> _accounts = [];
  String? _defaultAccountId;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Account> get accounts => List.unmodifiable(_accounts);
  List<Account> get activeAccounts => _accounts.where((a) => a.isActive).toList();
  String? get defaultAccountId => _defaultAccountId;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasAccounts => _accounts.isNotEmpty;
  
  Account? get defaultAccount {
    if (_defaultAccountId == null) return null;
    try {
      return _accounts.firstWhere((account) => account.id == _defaultAccountId);
    } catch (e) {
      return _accounts.isNotEmpty ? _accounts.first : null;
    }
  }

  /// Initialize accounts from storage
  Future<void> initialize() async {
    await loadAccounts();
  }

  /// Load accounts from SharedPreferences
  Future<void> loadAccounts() async {
    _setLoading(true);
    _clearError();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final accountsJson = prefs.getStringList(_accountsKey) ?? [];
      
      _accounts = accountsJson
          .map((json) => Account.fromJson(jsonDecode(json)))
          .toList();
      
      _defaultAccountId = prefs.getString(_defaultAccountKey);
      
      // If no default account but we have accounts, set first as default
      if (_defaultAccountId == null && _accounts.isNotEmpty) {
        _defaultAccountId = _accounts.first.id;
        await _saveDefaultAccount();
      }
      
      debugPrint('AccountViewModel: Loaded ${_accounts.length} accounts');
    } catch (e) {
      _setError('Failed to load accounts: $e');
      debugPrint('AccountViewModel: Error loading accounts: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Save accounts to SharedPreferences
  Future<void> _saveAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accountsJson = _accounts
          .map((account) => jsonEncode(account.toJson()))
          .toList();
      
      await prefs.setStringList(_accountsKey, accountsJson);
      debugPrint('AccountViewModel: Saved ${_accounts.length} accounts');
    } catch (e) {
      debugPrint('AccountViewModel: Error saving accounts: $e');
      throw Exception('Failed to save accounts: $e');
    }
  }

  /// Save default account ID
  Future<void> _saveDefaultAccount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_defaultAccountId != null) {
        await prefs.setString(_defaultAccountKey, _defaultAccountId!);
      } else {
        await prefs.remove(_defaultAccountKey);
      }
    } catch (e) {
      debugPrint('AccountViewModel: Error saving default account: $e');
    }
  }

  /// Add a new account
  Future<void> addAccount(Account account) async {
    _clearError();
    
    try {
      _accounts.add(account);
      
      // Set as default if it's the first account
      if (_accounts.length == 1) {
        _defaultAccountId = account.id;
        await _saveDefaultAccount();
      }
      
      await _saveAccounts();
      notifyListeners();
      
      debugPrint('AccountViewModel: Added account: ${account.name}');
    } catch (e) {
      _setError('Failed to add account: $e');
      debugPrint('AccountViewModel: Error adding account: $e');
    }
  }

  /// Update an existing account
  Future<void> updateAccount(Account updatedAccount) async {
    _clearError();
    
    try {
      final index = _accounts.indexWhere((a) => a.id == updatedAccount.id);
      if (index == -1) {
        throw Exception('Account not found');
      }
      
      _accounts[index] = updatedAccount;
      await _saveAccounts();
      notifyListeners();
      
      debugPrint('AccountViewModel: Updated account: ${updatedAccount.name}');
    } catch (e) {
      _setError('Failed to update account: $e');
      debugPrint('AccountViewModel: Error updating account: $e');
    }
  }

  /// Delete an account
  Future<void> deleteAccount(String accountId) async {
    _clearError();
    
    try {
      _accounts.removeWhere((account) => account.id == accountId);
      
      // Update default account if deleted
      if (_defaultAccountId == accountId) {
        _defaultAccountId = _accounts.isNotEmpty ? _accounts.first.id : null;
        await _saveDefaultAccount();
      }
      
      await _saveAccounts();
      notifyListeners();
      
      debugPrint('AccountViewModel: Deleted account: $accountId');
    } catch (e) {
      _setError('Failed to delete account: $e');
      debugPrint('AccountViewModel: Error deleting account: $e');
    }
  }

  /// Set default account
  Future<void> setDefaultAccount(String accountId) async {
    _clearError();
    
    try {
      if (!_accounts.any((account) => account.id == accountId)) {
        throw Exception('Account not found');
      }
      
      _defaultAccountId = accountId;
      await _saveDefaultAccount();
      notifyListeners();
      
      debugPrint('AccountViewModel: Set default account: $accountId');
    } catch (e) {
      _setError('Failed to set default account: $e');
      debugPrint('AccountViewModel: Error setting default account: $e');
    }
  }

  /// Get account by ID
  Account? getAccountById(String accountId) {
    try {
      return _accounts.firstWhere((account) => account.id == accountId);
    } catch (e) {
      return null;
    }
  }

  /// Calculate current balance for an account
  double getAccountBalance(
    String accountId,
    List<Transaction> transactions,
    List<IncomeSource> incomeSources,
  ) {
    final account = getAccountById(accountId);
    if (account == null) return 0.0;
    
    return BalanceService.calculateAccountBalance(
      account,
      transactions,
      incomeSources,
    );
  }

  /// Calculate total balance across all active accounts
  double getTotalBalance(
    List<Transaction> transactions,
    List<IncomeSource> incomeSources,
  ) {
    return BalanceService.calculateTotalBalance(
      activeAccounts,
      transactions,
      incomeSources,
    );
  }

  /// Get net worth summary
  NetWorthSummary getNetWorthSummary(
    List<Transaction> transactions,
    List<IncomeSource> incomeSources,
  ) {
    return BalanceService.calculateNetWorth(
      activeAccounts,
      transactions,
      incomeSources,
    );
  }

  /// Setup initial accounts (for onboarding)
  Future<void> setupInitialAccounts(List<Account> initialAccounts) async {
    _clearError();
    
    try {
      _accounts = initialAccounts;
      
      if (initialAccounts.isNotEmpty) {
        _defaultAccountId = initialAccounts.first.id;
        await _saveDefaultAccount();
      }
      
      await _saveAccounts();
      notifyListeners();
      
      debugPrint('AccountViewModel: Setup ${initialAccounts.length} initial accounts');
    } catch (e) {
      _setError('Failed to setup initial accounts: $e');
      debugPrint('AccountViewModel: Error setting up initial accounts: $e');
    }
  }

  /// Check if user has completed account setup
  bool get hasCompletedSetup => _accounts.isNotEmpty;

  /// Get accounts by type
  List<Account> getAccountsByType(AccountType type) {
    return _accounts.where((account) => account.type == type && account.isActive).toList();
  }

  /// Get account performance metrics
  AccountPerformance getAccountPerformance(
    String accountId,
    List<Transaction> transactions,
    List<IncomeSource> incomeSources,
  ) {
    final account = getAccountById(accountId);
    if (account == null) {
      return AccountPerformance(
        accountId: accountId,
        currentBalance: 0.0,
        monthlyChange: 0.0,
        monthlyChangePercent: 0.0,
        isPositiveGrowth: false,
      );
    }
    
    return BalanceService.getAccountPerformance(
      account,
      transactions,
      incomeSources,
    );
  }

  /// Clear all accounts (for testing/reset)
  Future<void> clearAllAccounts() async {
    _clearError();
    
    try {
      _accounts.clear();
      _defaultAccountId = null;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accountsKey);
      await prefs.remove(_defaultAccountKey);
      
      notifyListeners();
      debugPrint('AccountViewModel: Cleared all accounts');
    } catch (e) {
      _setError('Failed to clear accounts: $e');
      debugPrint('AccountViewModel: Error clearing accounts: $e');
    }
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
