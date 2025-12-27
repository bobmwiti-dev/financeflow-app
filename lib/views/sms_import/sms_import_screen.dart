import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/sms_import_service.dart';
import '../../widgets/app_navigation_drawer.dart';

class SmsImportScreen extends StatefulWidget {
  const SmsImportScreen({super.key});

  @override
  State<SmsImportScreen> createState() => _SmsImportScreenState();
}

class _SmsImportScreenState extends State<SmsImportScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isLoading = false;
  String? _errorMessage;
  int _importedCount = 0;
  bool _hasImported = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissionAndImport() async {
    final smsImportService = Provider.of<SmsImportService>(context, listen: false);
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final hasPermission = await smsImportService.requestPermission();
      if (!hasPermission) {
        setState(() {
          _errorMessage = 'SMS permission denied. Unable to import transactions.';
          _isLoading = false;
        });
        return;
      }

      final count = await smsImportService.importTransactions();
      setState(() {
        _importedCount = count;
        _hasImported = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error importing transactions: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import SMS Transactions'),
        elevation: 0,
      ),
      drawer: AppNavigationDrawer(
        selectedIndex: 5,
        onItemSelected: (index) => Navigator.pushReplacementNamed(
          context, 
          index == 0 ? '/dashboard' : '/settings'
        ),
      ),
      body: Consumer<SmsImportService>(
        builder: (context, smsImportService, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOut,
                  child: AnimatedSlide(
                    offset: const Offset(0, 0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOut,
                    child: _buildHeader(),
                  ),
                ),
                const SizedBox(height: 24),
                AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeInOut,
                  child: AnimatedSlide(
                    offset: const Offset(0, 0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOut,
                    child: AnimatedScale(
                      scale: 1.0,
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOut,
                      child: _buildInfoCard(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (_isLoading) ...[
                  _buildLoadingState(),
                ] else if (_hasImported) ...[
                  _buildSuccessState(),
                ] else ...[
                  _buildPermissionState(smsImportService),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _buildErrorMessage(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SMS Transaction Import',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Import your financial transactions from bank SMS messages automatically',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline,
              color: Colors.blue,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              'How it works',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            const Text(
              'This feature scans your SMS inbox for bank transaction notifications and automatically imports them into your FinanceFlow app.',
            ),
            const SizedBox(height: 12),
            const Text(
              'Supported banks:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildBankItem('M-PESA', 'Money transfers and payments'),
            _buildBankItem('KCB Bank', 'Deposits and withdrawals'),
            _buildBankItem('Equity Bank', 'Payments and transfers'),
            _buildBankItem('Stanbic Bank', 'Account transactions'),
          ],
        ),
      ),
    );
  }

  Widget _buildBankItem(String name, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade300,
                    Colors.blue.shade600,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha:0.3 + 0.1 * _animationController.value),
                    blurRadius: 20,
                    spreadRadius: 5 + 5 * _animationController.value,
                  ),
                ],
              ),
              child: const Icon(
                Icons.message,
                color: Colors.white,
                size: 40,
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        Text(
          'Scanning SMS messages...',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'Please wait while we process your bank messages and import transactions.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green.shade100,
          ),
          child: Icon(
            Icons.check_circle,
            color: Colors.green.shade600,
            size: 60,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Import Complete!',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Successfully imported $_importedCount transaction${_importedCount != 1 ? 's' : ''}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/dashboard');
          },
          icon: const Icon(Icons.dashboard),
          label: const Text('Go to Dashboard'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            setState(() {
              _hasImported = false;
            });
          },
          child: const Text('Import More Transactions'),
        ),
      ],
    );
  }

  Widget _buildPermissionState(SmsImportService smsImportService) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue.shade100,
          ),
          child: Icon(
            Icons.sms,
            color: Colors.blue.shade600,
            size: 50,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          smsImportService.hasPermission ? 'Ready to Import' : 'Permission Required',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          smsImportService.hasPermission
              ? 'We can now scan your SMS messages for bank transactions.'
              : 'FinanceFlow needs permission to read your SMS messages to import bank transactions.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _requestPermissionAndImport,
          icon: Icon(
            smsImportService.hasPermission ? Icons.sync : Icons.perm_device_information,
          ),
          label: Text(
            smsImportService.hasPermission ? 'Import Transactions' : 'Grant Permission & Import',
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(fontSize: 16),
            backgroundColor: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade700,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage ?? 'An error occurred',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
