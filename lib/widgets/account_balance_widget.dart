import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/account_model.dart';
import '../viewmodels/account_viewmodel.dart';
import '../viewmodels/transaction_viewmodel_fixed.dart' as fixed;
import '../viewmodels/income_viewmodel.dart';
import '../themes/app_theme.dart';

/// Widget to display account balances with real-time updates
class AccountBalanceWidget extends StatelessWidget {
  final bool showAllAccounts;
  final bool showAddButton;
  final VoidCallback? onAddAccount;
  final Function(Account)? onAccountTap;

  const AccountBalanceWidget({
    super.key,
    this.showAllAccounts = true,
    this.showAddButton = true,
    this.onAddAccount,
    this.onAccountTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer3<AccountViewModel, fixed.TransactionViewModel, IncomeViewModel>(
      builder: (context, accountVm, transactionVm, incomeVm, child) {
        if (accountVm.isLoading) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (!accountVm.hasAccounts) {
          return _buildNoAccountsCard(context);
        }

        final accounts = showAllAccounts 
            ? accountVm.activeAccounts 
            : [accountVm.defaultAccount].where((a) => a != null).cast<Account>().toList();

        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Account Balances',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (showAddButton)
                      IconButton(
                        onPressed: onAddAccount ?? () => _navigateToAccountSetup(context),
                        icon: const Icon(Icons.add),
                        tooltip: 'Add Account',
                      ),
                  ],
                ),
              ),
              
              // Total Balance (if showing all accounts)
              if (showAllAccounts && accounts.length > 1)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Total Balance',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatCurrency(
                          accountVm.getTotalBalance(
                            transactionVm.transactions,
                            incomeVm.incomeSources,
                          ),
                        ),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              
              if (showAllAccounts && accounts.length > 1)
                const SizedBox(height: 8),
              
              // Individual Account Balances
              ...accounts.map((account) => _buildAccountTile(
                context,
                account,
                accountVm,
                transactionVm,
                incomeVm,
              )),
              
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoAccountsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Accounts Set Up',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first account to start tracking real balances',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAddAccount ?? () => _navigateToAccountSetup(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Account'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTile(
    BuildContext context,
    Account account,
    AccountViewModel accountVm,
    fixed.TransactionViewModel transactionVm,
    IncomeViewModel incomeVm,
  ) {
    final balance = accountVm.getAccountBalance(
      account.id,
      transactionVm.transactions,
      incomeVm.incomeSources,
    );

    final performance = accountVm.getAccountPerformance(
      account.id,
      transactionVm.transactions,
      incomeVm.incomeSources,
    );

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getAccountColor(account.type).withValues(alpha: 0.2),
        child: Icon(
          _getAccountIcon(account.type),
          color: _getAccountColor(account.type),
        ),
      ),
      title: Text(
        account.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            account.type.displayName,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          if (performance.monthlyChange != 0)
            Row(
              children: [
                Icon(
                  performance.isPositiveGrowth 
                      ? Icons.trending_up 
                      : Icons.trending_down,
                  size: 14,
                  color: performance.isPositiveGrowth 
                      ? Colors.green 
                      : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  '${performance.isPositiveGrowth ? '+' : ''}${_formatCurrency(performance.monthlyChange)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: performance.isPositiveGrowth 
                        ? Colors.green 
                        : Colors.red,
                  ),
                ),
              ],
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatCurrency(balance),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: balance >= 0 ? Colors.green : Colors.red,
            ),
          ),
          Text(
            account.currency,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
      onTap: onAccountTap != null ? () => onAccountTap!(account) : null,
    );
  }

  Color _getAccountColor(AccountType type) {
    switch (type) {
      case AccountType.bank:
        return Colors.blue;
      case AccountType.mpesa:
        return Colors.green;
      case AccountType.cash:
        return Colors.orange;
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

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      symbol: 'KES ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  void _navigateToAccountSetup(BuildContext context) {
    Navigator.of(context).pushNamed('/account_setup');
  }
}
