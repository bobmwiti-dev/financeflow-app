import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import 'package:intl/intl.dart';

import '../../services/mpesa_import_service.dart';
import '../../services/sms_reader_service.dart';
import '../../models/mpesa_sms_model.dart';
import '../../viewmodels/transaction_viewmodel_fixed.dart';
import '../../widgets/animated_button.dart';
import '../../widgets/animated_list_item.dart';
import '../../widgets/error_widget.dart' as app_error;

class MpesaImportScreen extends StatefulWidget {
  const MpesaImportScreen({super.key});

  @override
  State<MpesaImportScreen> createState() => _MpesaImportScreenState();
}

class _MpesaImportScreenState extends State<MpesaImportScreen> {
  final Logger _logger = Logger('MpesaImportScreen');
  
  bool _isLoading = false;
  bool _permissionGranted = false;
  bool _hasCheckedPermission = false;
  List<MpesaSmsTransaction> _previewTransactions = [];
  MpesaImportResult? _importResult;
  String _errorMessage = '';
  Map<String, dynamic> _statistics = {};
  
  @override
  void initState() {
    super.initState();
    _checkPermission();
  }
  
  Future<void> _checkPermission() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      bool hasPermission = await SmsReaderService.hasPermission();
      if (!hasPermission) {
        hasPermission = await SmsReaderService.requestPermission();
      }
      
      setState(() {
        _permissionGranted = hasPermission;
        _hasCheckedPermission = true;
        _isLoading = false;
      });
      
      if (hasPermission) {
        _loadPreviewTransactions();
        _loadStatistics();
      }
    } catch (e) {
      _logger.severe('Error checking permission: $e');
      setState(() {
        _errorMessage = 'Could not check SMS permission: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadPreviewTransactions() async {
    if (!_permissionGranted) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final transactions = await MpesaImportService.testSmsImport(maxCount: 50);
      
      setState(() {
        _previewTransactions = transactions;
        _isLoading = false;
      });
      
      _logger.info('Loaded ${transactions.length} preview transactions');
    } catch (e) {
      _logger.severe('Error loading preview transactions: $e');
      setState(() {
        _errorMessage = 'Could not load M-Pesa transactions: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStatistics() async {
    try {
      final stats = await SmsReaderService.getSmsStatistics(
        since: DateTime.now().subtract(const Duration(days: 30)),
      );
      
      if (mounted) {
        setState(() {
          _statistics = stats;
        });
      }
      
      _logger.info('Loaded SMS statistics: $stats');
    } catch (e) {
      _logger.severe('Error loading statistics: $e');
    }
  }
  
  Future<void> _importTransactions() async {
    if (!_permissionGranted || _previewTransactions.isEmpty) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final result = await MpesaImportService.importTransactions(
        maxDays: 30,
        categorizeAutomatically: true,
        skipDuplicates: true,
      );
      
      setState(() {
        _importResult = result;
        _isLoading = false;
      });
      
      // Refresh transaction viewmodel
      if (mounted) {
        final viewModel = Provider.of<TransactionViewModel>(context, listen: false);
        viewModel.loadTransactionsByMonth(DateTime.now());
      }
      
      _logger.info('Import completed: $result');
      
      if (mounted && result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported ${result.imported} transactions'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      _logger.severe('Error importing transactions: $e');
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
        title: const Text('Import M-Pesa Transactions'),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }
  
  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }
    
    if (_errorMessage.isNotEmpty) {
      return _buildErrorState();
    }
    
    if (!_hasCheckedPermission || !_permissionGranted) {
      return _buildPermissionRequest();
    }
    
    if (_importResult != null && _importResult!.success) {
      return _buildImportResultView();
    }
    
    return _buildTransactionPreview();
  }
  
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator().animate().scale(),
          const SizedBox(height: 16),
          const Text('Processing M-Pesa transactions...')
              .animate().fadeIn(duration: 400.ms),
        ],
      ),
    );
  }
  
  Widget _buildErrorState() {
    return app_error.ErrorWidget(
      errorMessage: _errorMessage,
      onRetry: _checkPermission,
    );
  }
  
  Widget _buildPermissionRequest() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.message,
              size: 80,
              color: Theme.of(context).primaryColor,
            ).animate().scale(),
            const SizedBox(height: 24),
            Text(
              'SMS Permission Required',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ).animate().fadeIn(),
            const SizedBox(height: 16),
            Text(
              'To import your M-Pesa transactions, we need permission to read your SMS messages. '
              'We will only read messages from M-Pesa.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 32),
            AnimatedButton(
              onPressed: _checkPermission,
              text: 'Grant Permission',
              color: Theme.of(context).primaryColor,
              icon: Icons.check_circle,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTransactionPreview() {
    if (_previewTransactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox,
                size: 80,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 24),
              Text(
                'No M-Pesa SMS Found',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(
                'We couldn\'t find any M-Pesa transaction messages in your SMS inbox.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              AnimatedButton(
                onPressed: _loadPreviewTransactions,
                text: 'Refresh',
                color: Theme.of(context).primaryColor,
                icon: Icons.refresh,
              ),
            ],
          ),
        ),
      );
    }
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Found ${_previewTransactions.length} M-Pesa Transactions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'These transactions will be imported into your FinanceFlow app. '
                'Review them below before importing.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              if (_statistics.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Found ${_statistics['mpesaSmsMessages'] ?? 0} M-Pesa SMS messages with ${_statistics['parseSuccessRate'] ?? '0%'} parse success rate',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              AnimatedButton(
                onPressed: _importTransactions,
                text: 'Import All Transactions',
                color: Theme.of(context).primaryColor,
                icon: Icons.download,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _previewTransactions.length,
            itemBuilder: (context, index) {
              final transaction = _previewTransactions[index];
              return AnimatedListItem(
                index: index,
                child: _buildMpesaTransactionItem(transaction),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildImportResultView() {
    final result = _importResult!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Import Complete!',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildImportSummaryCard(result),
              const SizedBox(height: 16),
              AnimatedButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                text: 'Return to Dashboard',
                color: Theme.of(context).primaryColor,
                icon: Icons.home,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImportSummaryCard(MpesaImportResult result) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Import Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow('Total Found', '${result.totalFound}', Icons.search),
            _buildSummaryRow('Successfully Imported', '${result.imported}', Icons.check_circle, Colors.green),
            _buildSummaryRow('Skipped (Duplicates)', '${result.skipped}', Icons.skip_next, Colors.orange),
            if (result.failed > 0)
              _buildSummaryRow('Failed', '${result.failed}', Icons.error, Colors.red),
            if (result.errors.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Errors:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              ...result.errors.take(3).map((error) => Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                child: Text(
                  '• $error',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red.shade700,
                  ),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, IconData icon, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color ?? Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMpesaTransactionItem(MpesaSmsTransaction transaction) {
    final dateFormatter = DateFormat('MMM d, yyyy');
    final timeFormatter = DateFormat('h:mm a');
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    transaction.description,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'KSh ${transaction.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: transaction.isExpense ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getTransactionTypeColor(transaction.type).withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getTransactionTypeLabel(transaction.type),
                    style: TextStyle(
                      color: _getTransactionTypeColor(transaction.type),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  '${dateFormatter.format(transaction.transactionDate)} ${timeFormatter.format(transaction.transactionDate)}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.confirmation_number, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  transaction.mpesaCode,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontFamily: 'monospace',
                  ),
                ),
                const Spacer(),
                Text(
                  'Balance: KSh ${transaction.balance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTransactionTypeColor(MpesaTransactionType type) {
    switch (type) {
      case MpesaTransactionType.sent:
        return Colors.red;
      case MpesaTransactionType.received:
        return Colors.green;
      case MpesaTransactionType.withdrawal:
        return Colors.orange;
      case MpesaTransactionType.deposit:
        return Colors.blue;
      case MpesaTransactionType.paybill:
        return Colors.purple;
      case MpesaTransactionType.buyGoods:
        return Colors.teal;
      case MpesaTransactionType.airtime:
        return Colors.indigo;
      case MpesaTransactionType.reversal:
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String _getTransactionTypeLabel(MpesaTransactionType type) {
    switch (type) {
      case MpesaTransactionType.sent:
        return 'Sent';
      case MpesaTransactionType.received:
        return 'Received';
      case MpesaTransactionType.withdrawal:
        return 'Withdrawal';
      case MpesaTransactionType.deposit:
        return 'Deposit';
      case MpesaTransactionType.paybill:
        return 'Paybill';
      case MpesaTransactionType.buyGoods:
        return 'Buy Goods';
      case MpesaTransactionType.airtime:
        return 'Airtime';
      case MpesaTransactionType.reversal:
        return 'Reversal';
      default:
        return 'Unknown';
    }
  }
}
