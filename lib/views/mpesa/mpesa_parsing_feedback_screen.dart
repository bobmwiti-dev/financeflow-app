import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/mpesa_sms_model.dart';
import '../../services/mpesa_import_service.dart';
import '../../utils/currency_extensions.dart';
import '../../themes/app_theme.dart';

/// Screen showing M-Pesa parsing feedback, statistics, and manual corrections
class MpesaParsingFeedbackScreen extends StatefulWidget {
  const MpesaParsingFeedbackScreen({super.key});

  @override
  State<MpesaParsingFeedbackScreen> createState() => _MpesaParsingFeedbackScreenState();
}

class _MpesaParsingFeedbackScreenState extends State<MpesaParsingFeedbackScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<MpesaSmsTransaction> _recentTransactions = [];
  Map<String, dynamic> _parsingStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load recent transactions with parsing feedback
      _recentTransactions = await MpesaImportService.getRecentTransactionsWithFeedback();
      
      // Load parsing statistics
      _parsingStats = await MpesaImportService.getParsingStatistics();
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('M-Pesa Parsing Intelligence'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: 'Statistics'),
            Tab(icon: Icon(Icons.feedback), text: 'Feedback'),
            Tab(icon: Icon(Icons.edit), text: 'Corrections'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildStatisticsTab(),
                _buildFeedbackTab(),
                _buildCorrectionsTab(),
              ],
            ),
    );
  }

  Widget _buildStatisticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsHeader(),
          const SizedBox(height: 20),
          _buildParsingAccuracyCard(),
          const SizedBox(height: 16),
          _buildMerchantRecognitionCard(),
          const SizedBox(height: 16),
          _buildTransactionTypesCard(),
          const SizedBox(height: 16),
          _buildConfidenceDistributionCard(),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    final totalTransactions = _parsingStats['totalTransactions'] ?? 0;
    final successfulParsing = _parsingStats['successfulParsing'] ?? 0;
    final accuracyRate = totalTransactions > 0 
        ? (successfulParsing / totalTransactions * 100) 
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.green.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'M-Pesa Parsing Intelligence',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Kenya Market Optimized',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Accuracy Rate',
                  '${accuracyRate.toStringAsFixed(1)}%',
                  Icons.check_circle,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Total Parsed',
                  '$totalTransactions',
                  Icons.sms,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Merchants Found',
                  '${_parsingStats['merchantsRecognized'] ?? 0}',
                  Icons.store,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 600.ms)
      .slideY(begin: 0.2, end: 0);
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildParsingAccuracyCard() {
    final highConfidence = _parsingStats['highConfidenceCount'] ?? 0;
    final mediumConfidence = _parsingStats['mediumConfidenceCount'] ?? 0;
    final lowConfidence = _parsingStats['lowConfidenceCount'] ?? 0;
    final total = highConfidence + mediumConfidence + lowConfidence;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.speed, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Parsing Confidence Distribution',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (total > 0) ...[
              _buildConfidenceBar('High (90%+)', highConfidence, total, Colors.green),
              const SizedBox(height: 8),
              _buildConfidenceBar('Medium (70-90%)', mediumConfidence, total, Colors.orange),
              const SizedBox(height: 8),
              _buildConfidenceBar('Low (<70%)', lowConfidence, total, Colors.red),
            ] else
              const Text('No parsing data available'),
          ],
        ),
      ),
    ).animate()
      .fadeIn(duration: 600.ms, delay: 200.ms)
      .slideX(begin: 0.2, end: 0);
  }

  Widget _buildConfidenceBar(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total) : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 14)),
            Text('$count (${(percentage * 100).toStringAsFixed(1)}%)',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
        ),
      ],
    );
  }

  Widget _buildMerchantRecognitionCard() {
    final merchantStats = _parsingStats['merchantStats'] as Map<String, dynamic>? ?? {};
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.store, color: Colors.purple.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Top Recognized Merchants',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (merchantStats.isNotEmpty)
              ...merchantStats.entries.take(5).map((entry) =>
                _buildMerchantItem(entry.key, entry.value))
            else
              const Text('No merchant data available'),
          ],
        ),
      ),
    ).animate()
      .fadeIn(duration: 600.ms, delay: 400.ms)
      .slideX(begin: -0.2, end: 0);
  }

  Widget _buildMerchantItem(String merchant, dynamic data) {
    final count = data['count'] ?? 0;
    final category = data['category'] ?? 'Unknown';
    final amount = (data['totalAmount'] ?? 0.0) as double;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(merchant, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(category, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: Text('$count txns', style: const TextStyle(fontSize: 12)),
          ),
          Text(amount.toKenyaDualCurrency(), 
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTransactionTypesCard() {
    final typeStats = _parsingStats['transactionTypes'] as Map<String, int>? ?? {};
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.category, color: Colors.teal.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Transaction Types',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (typeStats.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: typeStats.entries.map((entry) =>
                  Chip(
                    label: Text('${entry.key}: ${entry.value}'),
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  )).toList(),
              )
            else
              const Text('No transaction type data available'),
          ],
        ),
      ),
    ).animate()
      .fadeIn(duration: 600.ms, delay: 600.ms)
      .slideY(begin: 0.2, end: 0);
  }

  Widget _buildConfidenceDistributionCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: Colors.indigo.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Parsing Insights',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInsightItem(
              'Average Confidence',
              '${(_parsingStats['averageConfidence'] ?? 0.0).toStringAsFixed(1)}%',
              Icons.trending_up,
              Colors.green,
            ),
            _buildInsightItem(
              'Balance Validation',
              '${(_parsingStats['balanceValidationRate'] ?? 0.0).toStringAsFixed(1)}%',
              Icons.account_balance,
              Colors.blue,
            ),
            _buildInsightItem(
              'Merchant Recognition',
              '${(_parsingStats['merchantRecognitionRate'] ?? 0.0).toStringAsFixed(1)}%',
              Icons.store,
              Colors.purple,
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(duration: 600.ms, delay: 800.ms)
      .slideX(begin: 0.2, end: 0);
  }

  Widget _buildInsightItem(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFeedbackTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recentTransactions.length,
      itemBuilder: (context, index) {
        final transaction = _recentTransactions[index];
        return _buildTransactionFeedbackCard(transaction);
      },
    );
  }

  Widget _buildTransactionFeedbackCard(MpesaSmsTransaction transaction) {
    final confidenceColor = _getConfidenceColor(transaction.confidence);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: confidenceColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Confidence: ${(transaction.confidence * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: confidenceColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (transaction.isValidated)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Validated',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              transaction.description,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Amount: ${transaction.amount.toKenyaDualCurrency()}'),
                const Spacer(),
                if (transaction.category != null)
                  Chip(
                    label: Text(transaction.category!),
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  ),
              ],
            ),
            if (transaction.confidence < 0.8) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha:0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Low confidence parsing - please review',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showCorrectionDialog(transaction),
                      child: const Text('Correct'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate()
      .fadeIn(duration: 400.ms)
      .slideX(begin: 0.2, end: 0);
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.9) return Colors.green;
    if (confidence >= 0.7) return Colors.orange;
    return Colors.red;
  }

  Widget _buildCorrectionsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.school, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      const Text(
                        'Machine Learning Improvements',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your corrections help improve parsing accuracy for future transactions.',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCorrectionStat(
                          'Corrections Made',
                          '${_parsingStats['userCorrections'] ?? 0}',
                          Icons.edit,
                        ),
                      ),
                      Expanded(
                        child: _buildCorrectionStat(
                          'Accuracy Improved',
                          '+${(_parsingStats['accuracyImprovement'] ?? 0.0).toStringAsFixed(1)}%',
                          Icons.trending_up,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Recent Transactions Needing Review',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _recentTransactions.where((t) => t.confidence < 0.8).length,
              itemBuilder: (context, index) {
                final lowConfidenceTransactions = 
                    _recentTransactions.where((t) => t.confidence < 0.8).toList();
                if (index >= lowConfidenceTransactions.length) return const SizedBox();
                
                final transaction = lowConfidenceTransactions[index];
                return _buildCorrectionCard(transaction);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorrectionStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue.shade600),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCorrectionCard(MpesaSmsTransaction transaction) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getConfidenceColor(transaction.confidence).withValues(alpha: 0.2),
          child: Icon(
            Icons.warning,
            color: _getConfidenceColor(transaction.confidence),
          ),
        ),
        title: Text(transaction.description),
        subtitle: Text('Confidence: ${(transaction.confidence * 100).toStringAsFixed(0)}%'),
        trailing: ElevatedButton(
          onPressed: () => _showCorrectionDialog(transaction),
          child: const Text('Review'),
        ),
      ),
    );
  }

  void _showCorrectionDialog(MpesaSmsTransaction transaction) {
    showDialog(
      context: context,
      builder: (context) => _CorrectionDialog(
        transaction: transaction,
        onCorrectionSaved: (correctedTransaction) {
          _saveCorrectionAndLearn(correctedTransaction);
        },
      ),
    );
  }

  Future<void> _saveCorrectionAndLearn(MpesaSmsTransaction correctedTransaction) async {
    try {
      // Save the correction
      await MpesaImportService.saveTransactionCorrection(correctedTransaction);
      
      // Trigger machine learning update
      await MpesaImportService.updateMachineLearningModel(correctedTransaction);
      
      // Refresh data
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Correction saved and learning model updated!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving correction: $e')),
        );
      }
    }
  }
}

class _CorrectionDialog extends StatefulWidget {
  final MpesaSmsTransaction transaction;
  final Function(MpesaSmsTransaction) onCorrectionSaved;

  const _CorrectionDialog({
    required this.transaction,
    required this.onCorrectionSaved,
  });

  @override
  State<_CorrectionDialog> createState() => _CorrectionDialogState();
}

class _CorrectionDialogState extends State<_CorrectionDialog> {
  late TextEditingController _categoryController;
  late TextEditingController _merchantController;
  late MpesaTransactionType _selectedType;

  @override
  void initState() {
    super.initState();
    _categoryController = TextEditingController(text: widget.transaction.category ?? '');
    _merchantController = TextEditingController(text: widget.transaction.recipient ?? '');
    _selectedType = widget.transaction.type;
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _merchantController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Correct Transaction'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Original SMS:', style: TextStyle(color: Colors.grey.shade600)),
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.transaction.originalSms,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<MpesaTransactionType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Transaction Type',
                border: OutlineInputBorder(),
              ),
              items: MpesaTransactionType.values.map((type) =>
                DropdownMenuItem(
                  value: type,
                  child: Text(type.toString().split('.').last),
                )).toList(),
              onChanged: (value) => setState(() => _selectedType = value!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _merchantController,
              decoration: const InputDecoration(
                labelText: 'Merchant/Recipient',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                hintText: 'e.g., Groceries, Transport, Utilities',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final correctedTransaction = widget.transaction.copyWith(
              type: _selectedType,
              recipient: _merchantController.text.trim(),
              category: _categoryController.text.trim(),
              confidence: 1.0, // User correction = 100% confidence
              isValidated: true,
            );
            
            widget.onCorrectionSaved(correctedTransaction);
            Navigator.pop(context);
          },
          child: const Text('Save Correction'),
        ),
      ],
    );
  }
}
