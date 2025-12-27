import 'package:flutter/foundation.dart';
import '../models/account_model.dart';
import '../models/transaction_model.dart';
import '../models/income_source_model.dart';

/// Service for calculating real account balances based on starting balance + transactions
class BalanceService {
  static const String _logTag = 'BalanceService';

  /// Calculate current balance for a specific account
  static double calculateAccountBalance(
    Account account,
    List<Transaction> transactions,
    List<IncomeSource> incomeSources,
  ) {
    try {
      // Filter transactions for this account after starting date
      final accountTransactions = transactions
          .where((tx) => tx.accountId == account.id)
          .where((tx) => tx.date.isAfter(account.startingDate.subtract(const Duration(days: 1))))
          .toList();

      // Filter income sources for this account after starting date
      final accountIncome = incomeSources
          .where((income) => income.accountId == account.id)
          .where((income) => income.date.isAfter(account.startingDate.subtract(const Duration(days: 1))))
          .toList();

      // Calculate total income
      final totalIncome = accountIncome.fold<double>(
        0.0,
        (sum, income) => sum + income.amount,
      );

      // Calculate total expenses
      final totalExpenses = accountTransactions
          .where((tx) => tx.type == TransactionType.expense)
          .fold<double>(0.0, (sum, tx) => sum + tx.amount);

      // Calculate total income from transactions (if any)
      final incomeFromTransactions = accountTransactions
          .where((tx) => tx.type == TransactionType.income)
          .fold<double>(0.0, (sum, tx) => sum + tx.amount);

      final currentBalance = account.startingBalance + 
                           totalIncome + 
                           incomeFromTransactions - 
                           totalExpenses;

      debugPrint('$_logTag: Account ${account.name} balance calculation:');
      debugPrint('  Starting: ${account.startingBalance.toStringAsFixed(2)}');
      debugPrint('  Income Sources: ${totalIncome.toStringAsFixed(2)}');
      debugPrint('  Income Transactions: ${incomeFromTransactions.toStringAsFixed(2)}');
      debugPrint('  Expenses: ${totalExpenses.toStringAsFixed(2)}');
      debugPrint('  Current Balance: ${currentBalance.toStringAsFixed(2)}');

      return currentBalance;
    } catch (e) {
      debugPrint('$_logTag: Error calculating balance for account ${account.id}: $e');
      return account.startingBalance; // Fallback to starting balance
    }
  }

  /// Calculate total balance across all accounts
  static double calculateTotalBalance(
    List<Account> accounts,
    List<Transaction> transactions,
    List<IncomeSource> incomeSources,
  ) {
    return accounts
        .where((account) => account.isActive)
        .fold<double>(0.0, (total, account) {
      return total + calculateAccountBalance(account, transactions, incomeSources);
    });
  }

  /// Calculate balance for a specific time period
  static double calculateBalanceForPeriod(
    Account account,
    List<Transaction> transactions,
    List<IncomeSource> incomeSources,
    DateTime startDate,
    DateTime endDate,
  ) {
    try {
      // Use account starting balance if period starts before account creation
      double baseBalance = account.startingBalance;
      DateTime calculationStart = startDate;

      if (startDate.isBefore(account.startingDate)) {
        calculationStart = account.startingDate;
      } else {
        // Calculate balance up to the start date
        baseBalance = calculateAccountBalanceUpToDate(
          account,
          transactions,
          incomeSources,
          startDate,
        );
      }

      // Filter transactions for the period
      final periodTransactions = transactions
          .where((tx) => tx.accountId == account.id)
          .where((tx) => 
              tx.date.isAfter(calculationStart.subtract(const Duration(days: 1))) &&
              tx.date.isBefore(endDate.add(const Duration(days: 1))))
          .toList();

      final periodIncome = incomeSources
          .where((income) => income.accountId == account.id)
          .where((income) => 
              income.date.isAfter(calculationStart.subtract(const Duration(days: 1))) &&
              income.date.isBefore(endDate.add(const Duration(days: 1))))
          .toList();

      final totalIncome = periodIncome.fold<double>(0.0, (sum, income) => sum + income.amount);
      final totalExpenses = periodTransactions
          .where((tx) => tx.type == TransactionType.expense)
          .fold<double>(0.0, (sum, tx) => sum + tx.amount);
      final incomeFromTransactions = periodTransactions
          .where((tx) => tx.type == TransactionType.income)
          .fold<double>(0.0, (sum, tx) => sum + tx.amount);

      return baseBalance + totalIncome + incomeFromTransactions - totalExpenses;
    } catch (e) {
      debugPrint('$_logTag: Error calculating period balance: $e');
      return account.startingBalance;
    }
  }

  /// Calculate balance up to a specific date
  static double calculateAccountBalanceUpToDate(
    Account account,
    List<Transaction> transactions,
    List<IncomeSource> incomeSources,
    DateTime upToDate,
  ) {
    final relevantTransactions = transactions
        .where((tx) => tx.accountId == account.id)
        .where((tx) => 
            tx.date.isAfter(account.startingDate.subtract(const Duration(days: 1))) &&
            tx.date.isBefore(upToDate.add(const Duration(days: 1))))
        .toList();

    final relevantIncome = incomeSources
        .where((income) => income.accountId == account.id)
        .where((income) => 
            income.date.isAfter(account.startingDate.subtract(const Duration(days: 1))) &&
            income.date.isBefore(upToDate.add(const Duration(days: 1))))
        .toList();

    final totalIncome = relevantIncome.fold<double>(0.0, (sum, income) => sum + income.amount);
    final totalExpenses = relevantTransactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold<double>(0.0, (sum, tx) => sum + tx.amount);
    final incomeFromTransactions = relevantTransactions
        .where((tx) => tx.type == TransactionType.income)
        .fold<double>(0.0, (sum, tx) => sum + tx.amount);

    return account.startingBalance + totalIncome + incomeFromTransactions - totalExpenses;
  }

  /// Get balance history for charting
  static List<BalancePoint> getBalanceHistory(
    Account account,
    List<Transaction> transactions,
    List<IncomeSource> incomeSources,
    int monthsBack,
  ) {
    final now = DateTime.now();
    final points = <BalancePoint>[];
    
    for (int i = monthsBack; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final balance = calculateAccountBalanceUpToDate(
        account,
        transactions,
        incomeSources,
        date,
      );
      
      points.add(BalancePoint(
        date: date,
        balance: balance,
        accountId: account.id,
      ));
    }
    
    return points;
  }

  /// Calculate net worth (all accounts combined)
  static NetWorthSummary calculateNetWorth(
    List<Account> accounts,
    List<Transaction> transactions,
    List<IncomeSource> incomeSources,
  ) {
    final accountBalances = <String, double>{};
    double totalBalance = 0.0;
    
    for (final account in accounts.where((a) => a.isActive)) {
      final balance = calculateAccountBalance(account, transactions, incomeSources);
      accountBalances[account.id] = balance;
      totalBalance += balance;
    }
    
    return NetWorthSummary(
      totalBalance: totalBalance,
      accountBalances: accountBalances,
      calculatedAt: DateTime.now(),
    );
  }

  /// Get account performance metrics
  static AccountPerformance getAccountPerformance(
    Account account,
    List<Transaction> transactions,
    List<IncomeSource> incomeSources,
  ) {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    
    final currentBalance = calculateAccountBalance(account, transactions, incomeSources);
    final lastMonthBalance = calculateAccountBalanceUpToDate(
      account,
      transactions,
      incomeSources,
      lastMonth,
    );
    
    final monthlyChange = currentBalance - lastMonthBalance;
    final monthlyChangePercent = lastMonthBalance != 0 
        ? (monthlyChange / lastMonthBalance.abs()) * 100 
        : 0.0;
    
    return AccountPerformance(
      accountId: account.id,
      currentBalance: currentBalance,
      monthlyChange: monthlyChange,
      monthlyChangePercent: monthlyChangePercent,
      isPositiveGrowth: monthlyChange >= 0,
    );
  }
}

/// Data class for balance points in charts
class BalancePoint {
  final DateTime date;
  final double balance;
  final String accountId;

  const BalancePoint({
    required this.date,
    required this.balance,
    required this.accountId,
  });
}

/// Net worth summary across all accounts
class NetWorthSummary {
  final double totalBalance;
  final Map<String, double> accountBalances;
  final DateTime calculatedAt;

  const NetWorthSummary({
    required this.totalBalance,
    required this.accountBalances,
    required this.calculatedAt,
  });
}

/// Account performance metrics
class AccountPerformance {
  final String accountId;
  final double currentBalance;
  final double monthlyChange;
  final double monthlyChangePercent;
  final bool isPositiveGrowth;

  const AccountPerformance({
    required this.accountId,
    required this.currentBalance,
    required this.monthlyChange,
    required this.monthlyChangePercent,
    required this.isPositiveGrowth,
  });
}
