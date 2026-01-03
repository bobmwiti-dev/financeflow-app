import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/account_model.dart';
import '../../viewmodels/account_viewmodel.dart';

/// Account setup screen for onboarding new users
class AccountSetupScreen extends StatefulWidget {
  final bool isOnboarding;
  final VoidCallback? onComplete;

  const AccountSetupScreen({
    super.key,
    this.isOnboarding = true,
    this.onComplete,
  });

  @override
  State<AccountSetupScreen> createState() => _AccountSetupScreenState();
}

class _AccountSetupScreenState extends State<AccountSetupScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  // Form controllers
  final _accountNameController = TextEditingController();
  final _startingBalanceController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  
  // Form state
  AccountType _selectedAccountType = AccountType.bank;
  DateTime _startingDate = DateTime.now();
  String _selectedCurrency = 'KES';
  String? _selectedBank;
  bool _isLoading = false;
  
  final List<String> _currencies = ['KES', 'USD', 'EUR', 'GBP'];
  
  @override
  void initState() {
    super.initState();
    _setDefaultAccountName();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _accountNameController.dispose();
    _startingBalanceController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  void _setDefaultAccountName() {
    switch (_selectedAccountType) {
      case AccountType.bank:
        _accountNameController.text = 'Main Bank Account';
        break;
      case AccountType.mpesa:
        _accountNameController.text = 'M-Pesa';
        break;
      case AccountType.cash:
        _accountNameController.text = 'Cash';
        break;
      case AccountType.savings:
        _accountNameController.text = 'Savings Account';
        break;
      case AccountType.investment:
        _accountNameController.text = 'Investment Account';
        break;
    }
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _createAccount();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _createAccount() async {
    if (!_validateForm()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final account = Account.create(
        name: _accountNameController.text.trim(),
        type: _selectedAccountType,
        startingBalance: double.parse(_startingBalanceController.text.replaceAll(',', '')),
        startingDate: _startingDate,
        currency: _selectedCurrency,
        bankName: _selectedAccountType.isBank ? (_selectedBank ?? _bankNameController.text.trim()) : null,
        accountNumber: _accountNumberController.text.trim().isNotEmpty 
            ? _accountNumberController.text.trim() 
            : null,
      );
      
      final accountVm = Provider.of<AccountViewModel>(context, listen: false);
      await accountVm.addAccount(account);
      
      if (mounted) {
        if (widget.isOnboarding) {
          // Show success and navigate to main app
          _showSuccessDialog();
        } else {
          // Just go back to previous screen
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _validateForm() {
    if (_accountNameController.text.trim().isEmpty) {
      _showError('Please enter an account name');
      return false;
    }
    
    if (_startingBalanceController.text.trim().isEmpty) {
      _showError('Please enter your starting balance');
      return false;
    }
    
    try {
      double.parse(_startingBalanceController.text.replaceAll(',', ''));
    } catch (e) {
      _showError('Please enter a valid balance amount');
      return false;
    }
    
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Account Created!'),
          ],
        ),
        content: const Text(
          'Your account has been set up successfully. You can now start tracking your finances with real balance information.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              if (widget.onComplete != null) {
                widget.onComplete!();
              } else if (widget.isOnboarding) {
                // After onboarding, go to sign in screen
                Navigator.of(context).pushReplacementNamed('/');
              } else {
                Navigator.of(context).pushReplacementNamed('/dashboard');
              }
            },
            child: const Text('Get Started'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isOnboarding ? 'Account Setup' : 'Add Account',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        leading: _currentPage > 0 
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  _previousPage();
                },
              )
            : (widget.isOnboarding ? null : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              )),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withValues(alpha: 0.04),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: Column(
          children: [
            // Progress indicator
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: List.generate(3, (index) {
                  final isActive = index <= _currentPage;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: 4,
                      margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                      decoration: BoxDecoration(
                        gradient: isActive
                            ? LinearGradient(
                                colors: [
                                  colorScheme.primary,
                                  colorScheme.primaryContainer,
                                ],
                              )
                            : null,
                        color: isActive
                            ? null
                            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildAccountTypePage(),
                  _buildAccountDetailsPage(),
                  _buildBalanceSetupPage(),
                ],
              ),
            ),
            
            // Bottom navigation
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          _previousPage();
                        },
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              HapticFeedback.selectionClick();
                              _nextPage();
                            },
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_currentPage == 2 ? 'Create Account' : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTypePage() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What type of account would you like to add?',
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the type that best matches your financial account.',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          
          Expanded(
            child: ListView(
              children: AccountType.values.map((type) {
                final isSelected = type == _selectedAccountType;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary.withValues(alpha: 0.08)
                        : colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary.withValues(alpha: 0.5)
                          : colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: RadioListTile<AccountType>(
                    value: type,
                    groupValue: _selectedAccountType,
                    activeColor: colorScheme.primary,
                    onChanged: (value) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedAccountType = value!;
                        _setDefaultAccountName();
                      });
                    },
                    title: Text(
                      type.displayName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      _getAccountTypeDescription(type),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    secondary: Icon(
                      _getAccountTypeIcon(type),
                      color: colorScheme.primary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountDetailsPage() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Details',
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Provide some basic information about your ${_selectedAccountType.displayName.toLowerCase()}.',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          
          Expanded(
            child: ListView(
              children: [
                // Account Name
                TextFormField(
                  controller: _accountNameController,
                  decoration: const InputDecoration(
                    labelText: 'Account Name',
                    hintText: 'e.g., Main Checking Account',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Currency Selection
                DropdownButtonFormField<String>(
                  value: _selectedCurrency,
                  decoration: const InputDecoration(
                    labelText: 'Currency',
                    border: OutlineInputBorder(),
                  ),
                  items: _currencies.map((currency) {
                    return DropdownMenuItem(
                      value: currency,
                      child: Text(currency),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedCurrency = value!);
                  },
                ),
                const SizedBox(height: 20),
                
                // Bank-specific fields
                if (_selectedAccountType.isBank) ...[
                  // Bank Selection
                  DropdownButtonFormField<String>(
                    value: _selectedBank,
                    decoration: const InputDecoration(
                      labelText: 'Bank',
                      border: OutlineInputBorder(),
                    ),
                    items: DefaultAccounts.kenyaBanks.map((bank) {
                      return DropdownMenuItem(
                        value: bank,
                        child: Text(bank),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedBank = value);
                      if (value == 'Other') {
                        _bankNameController.clear();
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Custom bank name if "Other" selected
                  if (_selectedBank == 'Other')
                    TextFormField(
                      controller: _bankNameController,
                      decoration: const InputDecoration(
                        labelText: 'Bank Name',
                        hintText: 'Enter bank name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  if (_selectedBank == 'Other') const SizedBox(height: 20),
                  
                  // Account Number (optional)
                  TextFormField(
                    controller: _accountNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Account Number (Optional)',
                      hintText: 'Last 4 digits will be shown',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceSetupPage() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Starting Balance',
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your current balance to start tracking from the right baseline.',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          
          Expanded(
            child: ListView(
              children: [
                // Starting Balance
                TextFormField(
                  controller: _startingBalanceController,
                  decoration: InputDecoration(
                    labelText: 'Current Balance',
                    hintText: '0.00',
                    prefixText: '$_selectedCurrency ',
                    border: const OutlineInputBorder(),
                    helperText: 'Enter the current balance in your account',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Starting Date
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startingDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _startingDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Starting Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      DateFormat('MMM dd, yyyy').format(_startingDate),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'How it works',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your current balance will be used as the starting point. All future transactions will be added or subtracted from this amount to show your real account balance.',
                        style: TextStyle(color: Colors.blue.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getAccountTypeDescription(AccountType type) {
    switch (type) {
      case AccountType.bank:
        return 'Traditional bank checking or current account';
      case AccountType.mpesa:
        return 'Safaricom M-Pesa mobile money account';
      case AccountType.cash:
        return 'Physical cash you keep on hand';
      case AccountType.savings:
        return 'Bank savings account or fixed deposit';
      case AccountType.investment:
        return 'Investment account or portfolio';
    }
  }

  IconData _getAccountTypeIcon(AccountType type) {
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
