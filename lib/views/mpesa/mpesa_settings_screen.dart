import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:intl/intl.dart';

import '../../services/mpesa_import_service.dart';
import '../../services/sms_reader_service.dart';
import '../../models/mpesa_sms_model.dart';
import '../../widgets/animated_button.dart';

class MpesaSettingsScreen extends StatefulWidget {
  const MpesaSettingsScreen({super.key});

  @override
  State<MpesaSettingsScreen> createState() => _MpesaSettingsScreenState();
}

class _MpesaSettingsScreenState extends State<MpesaSettingsScreen> {
  final Logger _logger = Logger('MpesaSettingsScreen');
  
  bool _isLoading = false;
  MpesaImportConfig _config = MpesaImportConfig();
  Map<String, dynamic> _statistics = {};
  Map<String, dynamic> _importStats = {};

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
    _loadStatistics();
  }

  Future<void> _loadConfiguration() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final config = await MpesaImportService.getImportConfig();
      final importStats = await MpesaImportService.getImportStatistics();
      
      setState(() {
        _config = config;
        _importStats = importStats;
        _isLoading = false;
      });
    } catch (e) {
      _logger.severe('Error loading configuration: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStatistics() async {
    try {
      final stats = await SmsReaderService.getSmsStatistics(
        since: DateTime.now().subtract(const Duration(days: 90)),
      );
      
      setState(() {
        _statistics = stats;
      });
    } catch (e) {
      _logger.severe('Error loading statistics: $e');
    }
  }

  Future<void> _saveConfiguration() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await MpesaImportService.saveImportConfig(_config);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _logger.severe('Error saving configuration: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('M-Pesa Settings'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveConfiguration,
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImportSettingsCard(),
                  const SizedBox(height: 16),
                  _buildStatisticsCard(),
                  const SizedBox(height: 16),
                  _buildImportHistoryCard(),
                  const SizedBox(height: 16),
                  _buildActionsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildImportSettingsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Import Settings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Auto Import'),
              subtitle: const Text('Automatically import new M-Pesa transactions'),
              value: _config.autoImportEnabled,
              onChanged: (value) {
                setState(() {
                  _config = _config.copyWith(autoImportEnabled: value);
                });
              },
            ),
            SwitchListTile(
              title: const Text('Auto Categorize'),
              subtitle: const Text('Automatically categorize imported transactions'),
              value: _config.categorizeAutomatically,
              onChanged: (value) {
                setState(() {
                  _config = _config.copyWith(categorizeAutomatically: value);
                });
              },
            ),
            SwitchListTile(
              title: const Text('Skip Duplicates'),
              subtitle: const Text('Skip transactions that have already been imported'),
              value: _config.importOnlyNewSms,
              onChanged: (value) {
                setState(() {
                  _config = _config.copyWith(importOnlyNewSms: value);
                });
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Import Period'),
              subtitle: Text('Import transactions from last ${_config.maxDaysToImport} days'),
              trailing: DropdownButton<int>(
                value: _config.maxDaysToImport,
                items: [7, 14, 30, 60, 90].map((days) {
                  return DropdownMenuItem(
                    value: days,
                    child: Text('$days days'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _config = _config.copyWith(maxDaysToImport: value);
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'SMS Statistics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_statistics.isNotEmpty) ...[
              _buildStatRow('Total SMS Messages', '${_statistics['totalSmsMessages'] ?? 0}'),
              _buildStatRow('M-Pesa Messages', '${_statistics['mpesaSmsMessages'] ?? 0}'),
              _buildStatRow('Parsed Transactions', '${_statistics['parsedTransactions'] ?? 0}'),
              _buildStatRow('Parse Success Rate', '${_statistics['parseSuccessRate'] ?? '0%'}'),
              _buildStatRow('Total Amount', 'KSh ${(_statistics['totalAmount'] ?? 0.0).toStringAsFixed(2)}'),
            ] else
              const Text('Loading statistics...'),
          ],
        ),
      ),
    );
  }

  Widget _buildImportHistoryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Import History',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_importStats.isNotEmpty) ...[
              _buildStatRow('Total M-Pesa Records', '${_importStats['totalMpesaTransactions'] ?? 0}'),
              _buildStatRow('Imported Transactions', '${_importStats['importedTransactions'] ?? 0}'),
              _buildStatRow('Pending Import', '${_importStats['pendingTransactions'] ?? 0}'),
              _buildStatRow('Import Success Rate', '${_importStats['importSuccessRate'] ?? '0%'}'),
              if (_importStats['lastImportDate'] != null)
                _buildStatRow('Last Import', DateFormat('MMM d, yyyy h:mm a').format(_importStats['lastImportDate'])),
            ] else
              const Text('No import history available'),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Actions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AnimatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/mpesa_import');
              },
              text: 'Import M-Pesa Transactions',
              icon: Icons.download,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 12),
            AnimatedButton(
              onPressed: _testImport,
              text: 'Test SMS Parsing',
              icon: Icons.bug_report,
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            AnimatedButton(
              onPressed: _refreshStatistics,
              text: 'Refresh Statistics',
              icon: Icons.refresh,
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testImport() async {
    try {
      final transactions = await MpesaImportService.testSmsImport(maxCount: 5);
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Test Results'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Found ${transactions.length} M-Pesa transactions'),
                const SizedBox(height: 8),
                if (transactions.isNotEmpty) ...[
                  const Text('Sample transactions:'),
                  const SizedBox(height: 8),
                  ...transactions.take(3).map((tx) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      '• ${tx.description} - KSh ${tx.amount.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  )),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshStatistics() async {
    await _loadStatistics();
    await _loadConfiguration();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Statistics refreshed'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
