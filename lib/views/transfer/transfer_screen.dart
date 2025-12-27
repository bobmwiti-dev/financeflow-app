import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../services/transaction_service.dart';
import '../../models/transaction_model.dart';
import '../../viewmodels/account_viewmodel.dart';
import '../../models/account_model.dart';
import '../../themes/app_theme.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _fromAccountId;
  String? _toAccountId;
  DateTime _date = DateTime.now();
  bool _isSaving = false;
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: 'KES ', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    // Load accounts when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AccountViewModel>(context, listen: false).loadAccounts();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Money'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<AccountViewModel>(
        builder: (context, accountViewModel, child) {
          if (accountViewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!accountViewModel.hasAccounts || accountViewModel.accounts.length < 2) {
            return _buildInsufficientAccountsState();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Transfer Overview Card
                  _buildTransferOverviewCard(accountViewModel),
                  const SizedBox(height: 24),
                  
                  // From Account Selector
                  _buildAccountSelector(
                    label: 'From Account',
                    selectedAccountId: _fromAccountId,
                    accounts: accountViewModel.accounts,
                    onChanged: (accountId) {
                      setState(() {
                        _fromAccountId = accountId;
                        // Clear to account if same as from account
                        if (_toAccountId == accountId) {
                          _toAccountId = null;
                        }
                      });
                    },
                    excludeAccountId: _toAccountId,
                  ),
                  const SizedBox(height: 16),
                  
                  // To Account Selector
                  _buildAccountSelector(
                    label: 'To Account',
                    selectedAccountId: _toAccountId,
                    accounts: accountViewModel.accounts,
                    onChanged: (accountId) {
                      setState(() {
                        _toAccountId = accountId;
                        // Clear from account if same as to account
                        if (_fromAccountId == accountId) {
                          _fromAccountId = null;
                        }
                      });
                    },
                    excludeAccountId: _fromAccountId,
                  ),
                  const SizedBox(height: 16),
                  
                  // Amount Field
                  _buildAmountField(),
                  const SizedBox(height: 16),
                  
                  // Date Picker
                  _buildDatePicker(),
                  const SizedBox(height: 16),
                  
                  // Notes Field
                  _buildNotesField(),
                  const SizedBox(height: 32),
                  
                  // Transfer Button
                  _buildTransferButton(accountViewModel),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInsufficientAccountsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Need More Accounts',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You need at least 2 accounts to make transfers',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/account_setup'),
            icon: const Icon(Icons.add),
            label: const Text('Add Account'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferOverviewCard(AccountViewModel accountViewModel) {
    if (_fromAccountId == null || _toAccountId == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.swap_horiz,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                'Select accounts to see transfer preview',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final fromAccount = accountViewModel.accounts.firstWhere((a) => a.id == _fromAccountId);
    final toAccount = accountViewModel.accounts.firstWhere((a) => a.id == _toAccountId);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // From Account
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getAccountColor(fromAccount.type).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getAccountIcon(fromAccount.type),
                          color: _getAccountColor(fromAccount.type),
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        fromAccount.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        _currencyFormat.format(fromAccount.startingBalance),
                        style: TextStyle(
                          color: fromAccount.startingBalance >= 0 ? Colors.green[700] : Colors.red[700],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(
                    Icons.arrow_forward,
                    color: AppTheme.primaryColor,
                    size: 32,
                  ),
                ),
                // To Account
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getAccountColor(toAccount.type).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getAccountIcon(toAccount.type),
                          color: _getAccountColor(toAccount.type),
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        toAccount.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        _currencyFormat.format(toAccount.startingBalance),
                        style: TextStyle(
                          color: toAccount.startingBalance >= 0 ? Colors.green[700] : Colors.red[700],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSelector({
    required String label,
    required String? selectedAccountId,
    required List<Account> accounts,
    required Function(String?) onChanged,
    String? excludeAccountId,
  }) {
    final availableAccounts = accounts.where((account) => account.id != excludeAccountId).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<String>(
            value: selectedAccountId,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            hint: Text('Select $label'),
            items: availableAccounts.map((account) {
              return DropdownMenuItem<String>(
                value: account.id,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _getAccountColor(account.type).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        _getAccountIcon(account.type),
                        color: _getAccountColor(account.type),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            account.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            account.type.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              color: _getAccountColor(account.type),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Consumer<AccountViewModel>(
                      builder: (context, accountViewModel, child) {
                        return Text(
                          _currencyFormat.format(account.startingBalance),
                          style: TextStyle(
                            fontSize: 12,
                            color: account.startingBalance >= 0 ? Colors.green[700] : Colors.red[700],
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: onChanged,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select $label';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Amount',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          decoration: InputDecoration(
            hintText: 'Enter amount to transfer',
            prefixText: 'KES ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter an amount';
            }
            final amount = double.tryParse(value);
            if (amount == null || amount <= 0) {
              return 'Please enter a valid amount';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transfer Date',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Text(
                  DateFormat('MMM dd, yyyy').format(_date),
                  style: const TextStyle(fontSize: 16),
                ),
                const Spacer(),
                Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notes (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _noteController,
          decoration: InputDecoration(
            hintText: 'Add a note for this transfer',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildTransferButton(AccountViewModel accountViewModel) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : () => _performTransfer(accountViewModel),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Transfer Money',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
      });
    }
  }

  Future<void> _performTransfer(AccountViewModel accountViewModel) async {
    if (!_formKey.currentState!.validate()) return;

    if (_fromAccountId == null || _toAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both accounts'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = double.parse(_amountController.text);
    final fromAccount = accountViewModel.accounts.firstWhere((a) => a.id == _fromAccountId);
    final toAccount = accountViewModel.accounts.firstWhere((a) => a.id == _toAccountId);

    // Check if from account has sufficient balance
    final fromBalance = fromAccount.startingBalance;
    if (fromBalance < amount) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Insufficient balance in ${fromAccount.name}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final service = TransactionService.instance;

      // Create outgoing transaction (debit from source account)
      final outgoingTransaction = TransactionModel(
        title: 'Transfer to ${toAccount.name}',
        amount: -amount, // Negative for outgoing
        date: _date,
        category: 'Transfer',
        type: TransactionType.transfer,
        fromAccount: fromAccount.name,
        toAccount: toAccount.name,
        userId: userId,
        accountId: fromAccount.id, // Source account
        notes: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        isSynced: false,
        status: TransactionStatus.completed,
      );

      // Create incoming transaction (credit to destination account)
      final incomingTransaction = TransactionModel(
        title: 'Transfer from ${fromAccount.name}',
        amount: amount, // Positive for incoming
        date: _date,
        category: 'Transfer',
        type: TransactionType.transfer,
        fromAccount: fromAccount.name,
        toAccount: toAccount.name,
        userId: userId,
        accountId: toAccount.id, // Destination account
        notes: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        isSynced: false,
        status: TransactionStatus.completed,
      );

      // Execute both transactions
      final outgoingResult = await service.addTransaction(outgoingTransaction);
      final incomingResult = await service.addTransaction(incomingTransaction);

      if (outgoingResult != null && incomingResult != null) {
        // Refresh account balances
        await accountViewModel.loadAccounts();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Transfer of ${_currencyFormat.format(amount)} completed successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Failed to complete transfer');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transfer failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
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
