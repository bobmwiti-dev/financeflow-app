import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../models/anomaly_model.dart';
import '../../../models/time_period_model.dart';
import '../../../services/anomaly_detection_service.dart';
import '../../../viewmodels/transaction_viewmodel_fixed.dart';
import '../../../viewmodels/income_viewmodel.dart';
import 'report_card.dart';

class SmartAnomalyCard extends StatefulWidget {
  final TimePeriod selectedPeriod;

  const SmartAnomalyCard({
    super.key,
    required this.selectedPeriod,
  });

  @override
  State<SmartAnomalyCard> createState() => _SmartAnomalyCardState();
}

class _SmartAnomalyCardState extends State<SmartAnomalyCard>
    with TickerProviderStateMixin {
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;
  List<Anomaly> _anomalies = [];
  bool _isAnalyzing = true;
  int _selectedSeverityFilter = -1; // -1 = all, 0-3 = specific severity

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _scanAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );
    
    _performAnomalyDetection();
  }

  @override
  void didUpdateWidget(SmartAnomalyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPeriod != widget.selectedPeriod) {
      _performAnomalyDetection();
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  void _performAnomalyDetection() async {
    setState(() {
      _isAnalyzing = true;
    });

    _scanController.reset();
    _scanController.forward();

    // Simulate analysis time for better UX
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    final transactionViewModel = Provider.of<TransactionViewModel>(context, listen: false);
    final incomeViewModel = Provider.of<IncomeViewModel>(context, listen: false);

    final anomalies = AnomalyDetectionService.detectAnomalies(
      allTransactions: transactionViewModel.allTransactions,
      allIncomeSources: incomeViewModel.incomeSources,
      currentPeriod: widget.selectedPeriod,
    );

    if (mounted) {
      setState(() {
        _anomalies = anomalies;
        _isAnalyzing = false;
      });
    }
  }

  List<Anomaly> get _filteredAnomalies {
    if (_selectedSeverityFilter == -1) return _anomalies;
    final targetSeverity = AnomalySeverity.values[_selectedSeverityFilter];
    return _anomalies.where((anomaly) => anomaly.severity == targetSeverity).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ReportCard(
      title: '🔍 Smart Anomaly Detection - ${widget.selectedPeriod.displayName}',
      child: Column(
        children: [
          // Analysis Status Header
          _buildAnalysisHeader(),
          
          const SizedBox(height: 16),
          
          if (_isAnalyzing) ...[
            _buildAnalyzingState(),
          ] else if (_anomalies.isEmpty) ...[
            _buildNoAnomaliesState(),
          ] else ...[
            // Severity Filter Tabs
            _buildSeverityFilter(),
            const SizedBox(height: 16),
            
            // Anomaly Summary Stats
            _buildAnomalySummary(),
            const SizedBox(height: 16),
            
            // Anomaly List
            _buildAnomalyList(),
          ],
        ],
      ),
    ).animate()
      .fadeIn(duration: 500.ms)
      .slideY(begin: 0.2, duration: 500.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildAnalysisHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withValues(alpha: 0.1),
            Colors.purple.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: AnimatedBuilder(
              animation: _scanAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _scanAnimation.value * 2 * 3.14159,
                  child: Icon(
                    _isAnalyzing ? Icons.radar : Icons.psychology,
                    color: Colors.blue[700],
                    size: 24,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isAnalyzing ? 'Analyzing Spending Patterns...' : 'Analysis Complete',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isAnalyzing 
                      ? 'Scanning for unusual patterns and anomalies'
                      : '${_anomalies.length} anomalies detected',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (!_isAnalyzing)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _anomalies.isEmpty ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _anomalies.isEmpty ? 'All Clear' : '${_anomalies.length} Found',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnalyzingState() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _scanAnimation,
            builder: (context, child) {
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CircularProgressIndicator(
                        value: _scanAnimation.value,
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                      ),
                    ),
                    Center(
                      child: Icon(
                        Icons.analytics,
                        color: Colors.blue[600],
                        size: 32,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'AI-Powered Analysis in Progress',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Detecting spending patterns, duplicates, and anomalies...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoAnomaliesState() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              color: Colors.green[600],
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'All Clear!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No unusual spending patterns or anomalies detected for ${widget.selectedPeriod.displayName}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.psychology,
                  size: 16,
                  color: Colors.green[600],
                ),
                const SizedBox(width: 8),
                Text(
                  'Your spending patterns look normal',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityFilter() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('All', -1, _anomalies.length),
          const SizedBox(width: 8),
          ...AnomalySeverity.values.asMap().entries.map((entry) {
            final index = entry.key;
            final severity = entry.value;
            final count = _anomalies.where((a) => a.severity == severity).length;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildFilterChip(
                severity.name.toUpperCase(),
                index,
                count,
                color: _getSeverityColor(severity),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int index, int count, {Color? color}) {
    final isSelected = _selectedSeverityFilter == index;
    final chipColor = color ?? Colors.blue;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSeverityFilter = isSelected ? -1 : index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : chipColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: chipColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : chipColor,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.2) : chipColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnomalySummary() {
    final criticalCount = _anomalies.where((a) => a.severity == AnomalySeverity.critical).length;
    final highCount = _anomalies.where((a) => a.severity == AnomalySeverity.high).length;
    final mediumCount = _anomalies.where((a) => a.severity == AnomalySeverity.medium).length;
    final lowCount = _anomalies.where((a) => a.severity == AnomalySeverity.low).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: Colors.grey[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Detection Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (criticalCount > 0)
                _buildSummaryItem('Critical', criticalCount, Colors.purple),
              if (highCount > 0)
                _buildSummaryItem('High', highCount, Colors.red),
              if (mediumCount > 0)
                _buildSummaryItem('Medium', mediumCount, Colors.orange),
              if (lowCount > 0)
                _buildSummaryItem('Low', lowCount, Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnomalyList() {
    final filteredAnomalies = _filteredAnomalies;
    
    if (filteredAnomalies.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.filter_list_off,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No anomalies match the selected filter',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        ...filteredAnomalies.take(5).map((anomaly) => 
          _buildAnomalyItem(anomaly)),
        
        if (filteredAnomalies.length > 5)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.more_horiz,
                  color: Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${filteredAnomalies.length - 5} more anomalies detected',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAnomalyItem(Anomaly anomaly) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: anomaly.color.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: anomaly.color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: anomaly.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  anomaly.icon,
                  color: anomaly.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      anomaly.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: anomaly.color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            anomaly.severityLabel,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          anomaly.typeDescription,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Message
          Text(
            anomaly.message,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          
          // Recommendations
          if (anomaly.recommendations.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: Colors.amber[700],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Recommendations',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...anomaly.recommendations.take(2).map((rec) => 
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.only(top: 6, right: 8),
                            decoration: BoxDecoration(
                              color: anomaly.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              rec,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      ).animate()
      .fadeIn(duration: const Duration(milliseconds: 300), delay: Duration(milliseconds: _filteredAnomalies.indexOf(anomaly) * 100))
      .slideX(begin: 0.2, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
  }

  Color _getSeverityColor(AnomalySeverity severity) {
    switch (severity) {
      case AnomalySeverity.low:
        return Colors.blue;
      case AnomalySeverity.medium:
        return Colors.orange;
      case AnomalySeverity.high:
        return Colors.red;
      case AnomalySeverity.critical:
        return Colors.purple;
    }
  }
}
