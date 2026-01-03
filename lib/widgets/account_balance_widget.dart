import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/account_model.dart';
import '../viewmodels/account_viewmodel.dart';
import '../viewmodels/transaction_viewmodel_fixed.dart' as fixed;
import '../viewmodels/income_viewmodel.dart';
import '../utils/currency_extensions.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer3<AccountViewModel, fixed.TransactionViewModel, IncomeViewModel>(
      builder: (context, accountVm, transactionVm, incomeVm, child) {
        if (accountVm.isLoading) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.98),
                  colorScheme.surface.withValues(alpha: 0.98),
                ],
              ),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator.adaptive(),
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

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.surfaceContainerHighest.withValues(alpha: 0.98),
                colorScheme.surface.withValues(alpha: 0.98),
              ],
            ),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Balances',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          showAllAccounts && accounts.length > 1
                              ? 'Across ${accounts.length} accounts'
                              : accounts.first.currency,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (showAddButton)
                      IconButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          (onAddAccount ?? () => _navigateToAccountSetup(context))();
                        },
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
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.12),
                        colorScheme.primaryContainer.withValues(alpha: 0.06),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Total Balance',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        accountVm
                            .getTotalBalance(
                              transactionVm.transactions,
                              incomeVm.incomeSources,
                            )
                            .toKenyaDualCurrency(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: colorScheme.onPrimaryContainer,
                          letterSpacing: -0.2,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.98),
            colorScheme.surface.withValues(alpha: 0.98),
          ],
        ),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No Accounts Set Up',
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first account to start tracking real balances',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                (onAddAccount ?? () => _navigateToAccountSetup(context))();
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Account'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(duration: 600.ms)
      .slideY(begin: 0.2, duration: 600.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildAccountTile(
    BuildContext context,
    Account account,
    AccountViewModel accountVm,
    fixed.TransactionViewModel transactionVm,
    IncomeViewModel incomeVm,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            account.type.displayName,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
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
                      ? colorScheme.primary 
                      : colorScheme.error,
                ),
                const SizedBox(width: 4),
                Text(
                  '${performance.isPositiveGrowth ? '+' : ''}${performance.monthlyChange.abs().toKenyaDualCurrency()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: performance.isPositiveGrowth 
                        ? colorScheme.primary 
                        : colorScheme.error,
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
            balance.toKenyaDualCurrency(),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: balance >= 0 ? colorScheme.primary : colorScheme.error,
            ),
          ),
          Text(
            account.currency,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      onTap: onAccountTap != null
          ? () {
              HapticFeedback.selectionClick();
              onAccountTap!(account);
            }
          : null,
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

  void _navigateToAccountSetup(BuildContext context) {
    Navigator.of(context).pushNamed('/account_setup');
  }
}
