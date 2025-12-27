import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/account_model.dart';
import '../viewmodels/account_viewmodel.dart';
import '../services/transaction_service.dart';

/// Service to handle migration of existing data to the new account system
class AccountMigrationService {
  static const String _migrationKey = 'account_migration_completed';
  static const String _logTag = 'AccountMigrationService';

  /// Check if migration has been completed
  static Future<bool> isMigrationCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_migrationKey) ?? false;
  }

  /// Mark migration as completed
  static Future<void> markMigrationCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_migrationKey, true);
    debugPrint('$_logTag: Migration marked as completed');
  }

  /// Perform full migration of existing data to account system
  static Future<void> migrateExistingData(AccountViewModel accountVm) async {
    try {
      debugPrint('$_logTag: Starting data migration...');

      // Check if migration already completed
      if (await isMigrationCompleted()) {
        debugPrint('$_logTag: Migration already completed, skipping');
        return;
      }

      // Check if user already has accounts
      if (accountVm.hasAccounts) {
        debugPrint('$_logTag: User already has accounts, skipping migration');
        await markMigrationCompleted();
        return;
      }

      // Create default accounts for existing users
      await _createDefaultAccounts(accountVm);

      // Mark migration as completed
      await markMigrationCompleted();
      
      debugPrint('$_logTag: Migration completed successfully');
    } catch (e) {
      debugPrint('$_logTag: Migration failed: $e');
      // Don't mark as completed if migration fails
    }
  }

  /// Create default accounts for existing users
  static Future<void> _createDefaultAccounts(AccountViewModel accountVm) async {
    debugPrint('$_logTag: Creating default accounts...');

    final now = DateTime.now();
    
    // Create a default "Main Account" for existing users
    final defaultAccount = Account.create(
      name: 'Main Account',
      type: AccountType.bank,
      startingBalance: 0.0, // Start with 0, user can update later
      startingDate: now.subtract(const Duration(days: 30)), // 30 days ago
      currency: 'KES',
    );

    await accountVm.addAccount(defaultAccount);
    debugPrint('$_logTag: Created default main account');

    // Optionally create M-Pesa account for Kenyan users
    final mpesaAccount = Account.create(
      name: 'M-Pesa',
      type: AccountType.mpesa,
      startingBalance: 0.0,
      startingDate: now.subtract(const Duration(days: 30)),
      currency: 'KES',
    );

    await accountVm.addAccount(mpesaAccount);
    debugPrint('$_logTag: Created default M-Pesa account');

    // Create cash account
    final cashAccount = Account.create(
      name: 'Cash',
      type: AccountType.cash,
      startingBalance: 0.0,
      startingDate: now.subtract(const Duration(days: 30)),
      currency: 'KES',
    );

    await accountVm.addAccount(cashAccount);
    debugPrint('$_logTag: Created default cash account');
  }

  /// Update existing transactions to use default account
  /// Note: This is a conceptual method - actual implementation would depend on your data storage
  static Future<void> updateExistingTransactions(
    String defaultAccountId,
    TransactionService transactionService,
  ) async {
    try {
      debugPrint('$_logTag: Updating existing transactions with default account...');
      
      // This would need to be implemented based on your specific data storage
      // For now, we'll just log the intent
      debugPrint('$_logTag: Would update transactions to use account: $defaultAccountId');
      
      // Example implementation (you'd need to adapt this):
      // 1. Get all existing transactions
      // 2. Update each transaction to include the defaultAccountId
      // 3. Save updated transactions back to storage
      
    } catch (e) {
      debugPrint('$_logTag: Failed to update existing transactions: $e');
    }
  }

  /// Show migration welcome dialog to existing users
  static Future<void> showMigrationWelcome(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.upgrade, color: Colors.blue),
            SizedBox(width: 8),
            Text('Account System Upgrade'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to the new account system!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('We\'ve created default accounts for you:'),
            SizedBox(height: 8),
            Text('• Main Account (Bank)'),
            Text('• M-Pesa'),
            Text('• Cash'),
            SizedBox(height: 12),
            Text(
              'You can now track real balances and manage multiple accounts. '
              'Visit Settings > Accounts to customize your accounts and set starting balances.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/account_setup');
            },
            child: const Text('Set Up Now'),
          ),
        ],
      ),
    );
  }

  /// Check if user needs account setup guidance
  static Future<bool> shouldShowAccountSetupGuidance(AccountViewModel accountVm) async {
    // Show guidance if:
    // 1. Migration is completed (existing user)
    // 2. User has default accounts but hasn't customized them
    // 3. All accounts have 0 starting balance
    
    if (!await isMigrationCompleted()) {
      return false; // New user, normal onboarding
    }

    if (!accountVm.hasAccounts) {
      return true; // Something went wrong, needs setup
    }

    // Check if all accounts have default values (0 starting balance)
    final hasCustomizedAccounts = accountVm.accounts.any(
      (account) => account.startingBalance != 0.0,
    );

    return !hasCustomizedAccounts;
  }

  /// Get migration status for debugging
  static Future<Map<String, dynamic>> getMigrationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    
    return {
      'migrationCompleted': prefs.getBool(_migrationKey) ?? false,
      'migrationDate': prefs.getString('${_migrationKey}_date'),
    };
  }

  /// Reset migration status (for testing)
  static Future<void> resetMigrationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_migrationKey);
    await prefs.remove('${_migrationKey}_date');
    debugPrint('$_logTag: Migration status reset');
  }
}
