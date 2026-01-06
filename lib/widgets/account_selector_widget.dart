import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/account_model.dart';
import '../viewmodels/account_viewmodel.dart';
import '../themes/app_theme.dart';

/// A reusable widget for selecting accounts in transaction forms
class AccountSelectorWidget extends StatelessWidget {
  final String? selectedAccountId;
  final Function(String?) onAccountSelected;
  final String label;
  final bool isRequired;
  final String? hintText;

  const AccountSelectorWidget({
    super.key,
    required this.selectedAccountId,
    required this.onAccountSelected,
    this.label = 'Account',
    this.isRequired = true,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountViewModel>(
      builder: (context, accountVm, child) {
        if (!accountVm.hasAccounts) {
          return _buildNoAccountsState(context);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label
            Row(
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (isRequired)
                  Text(
                    ' *',
                    style: TextStyle(
                      color: AppTheme.expenseColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Dropdown
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1.5,
                ),
                color: Colors.white,
              ),
              child: DropdownButtonFormField<String>(
                value: selectedAccountId,
                decoration: InputDecoration(
                  hintText: hintText ?? 'Select an account',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.grey.shade600,
                ),
                items: accountVm.accounts.map((account) {
                  return DropdownMenuItem<String>(
                    value: account.id,
                    child: _buildAccountItem(account),
                  );
                }).toList(),
                onChanged: onAccountSelected,
                validator: isRequired ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select an account';
                  }
                  return null;
                } : null,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAccountItem(Account account) {
    return IntrinsicHeight(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Account type icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getAccountColor(account.type).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getAccountIcon(account.type),
              color: _getAccountColor(account.type),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          
          // Account details
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  account.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${account.type.name.toUpperCase()} • ${account.currency}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Current balance
          Flexible(
            fit: FlexFit.loose,
            child: Text(
              'KES ${account.startingBalance.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: account.startingBalance >= 0 
                    ? AppTheme.incomeColor 
                    : AppTheme.expenseColor,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoAccountsState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            color: Colors.orange.shade600,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'No Accounts Available',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Please set up your accounts first',
            style: TextStyle(
              color: Colors.orange.shade600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/account_setup');
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Set Up Accounts'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Color _getAccountColor(AccountType type) {
    switch (type) {
      case AccountType.bank:
        return Colors.blue;
      case AccountType.mpesa:
        return Colors.green;
      case AccountType.cash:
        return Colors.amber;
      case AccountType.savings:
        return Colors.purple;
      case AccountType.investment:
        return Colors.teal;
    }
  }

  IconData _getAccountIcon(AccountType type) {
    switch (type) {
      case AccountType.bank:
        return Icons.account_balance;
      case AccountType.mpesa:
        return Icons.phone_android;
      case AccountType.cash:
        return Icons.payments;
      case AccountType.savings:
        return Icons.savings;
      case AccountType.investment:
        return Icons.trending_up;
    }
  }
}

/// A compact version of the account selector for smaller spaces
class CompactAccountSelector extends StatelessWidget {
  final String? selectedAccountId;
  final Function(String?) onAccountSelected;
  final bool showLabel;

  const CompactAccountSelector({
    super.key,
    required this.selectedAccountId,
    required this.onAccountSelected,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountViewModel>(
      builder: (context, accountVm, child) {
        if (!accountVm.hasAccounts) {
          return const SizedBox.shrink();
        }

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            color: Colors.white,
          ),
          child: DropdownButton<String>(
            value: selectedAccountId,
            hint: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  showLabel ? 'Account' : 'Select',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            underline: const SizedBox.shrink(),
            icon: Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Colors.grey.shade600,
            ),
            items: accountVm.accounts.map((account) {
              return DropdownMenuItem<String>(
                value: account.id,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getAccountIcon(account.type),
                      size: 16,
                      color: _getAccountColor(account.type),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      account.name,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: onAccountSelected,
          ),
        );
      },
    );
  }

  Color _getAccountColor(AccountType type) {
    switch (type) {
      case AccountType.bank:
        return Colors.blue;
      case AccountType.mpesa:
        return Colors.green;
      case AccountType.cash:
        return Colors.amber;
      case AccountType.savings:
        return Colors.purple;
      case AccountType.investment:
        return Colors.teal;
    }
  }

  IconData _getAccountIcon(AccountType type) {
    switch (type) {
      case AccountType.bank:
        return Icons.account_balance;
      case AccountType.mpesa:
        return Icons.phone_android;
      case AccountType.cash:
        return Icons.payments;
      case AccountType.savings:
        return Icons.savings;
      case AccountType.investment:
        return Icons.trending_up;
    }
  }
}
