import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/ai_insights_model.dart';
import '../../services/local_ai_intelligence_service.dart';
import '../../themes/app_theme.dart';

class FinancialIntelligenceCard extends StatelessWidget {
  final FinancialIntelligence intelligence;
  final VoidCallback? onViewDetails;

  const FinancialIntelligenceCard({
    super.key,
    required this.intelligence,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.1),
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildKeyInsights(),
              const SizedBox(height: 12),
              _buildRecommendationsPreview(),
              const SizedBox(height: 12),
              _buildActionButton(),
            ],
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: 600.ms)
      .slideY(begin: 0.3, end: 0, curve: Curves.easeOutQuad);
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.psychology,
            color: AppTheme.primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI Financial Intelligence',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Personalized insights for your finances',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        _buildConfidenceScore(),
      ],
    );
  }

  Widget _buildConfidenceScore() {
    final confidence = intelligence.predictiveInsights.confidenceScore;
    final color = confidence > 80 ? Colors.green : 
                 confidence > 60 ? Colors.orange : Colors.red;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '${confidence.toStringAsFixed(0)}%',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildKeyInsights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Key Insights',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildInsightCard(
              'Spending Pattern',
              _getSpendingPatternInsight(),
              Icons.trending_up,
              Colors.blue,
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildInsightCard(
              'Budget Health',
              intelligence.budgetOptimization.health.displayName,
              Icons.health_and_safety,
              intelligence.budgetOptimization.health.color,
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildInsightCard(
              'Transport Efficiency',
              intelligence.kenyaSpecificInsights.transportOptimization.efficiency.displayName,
              Icons.directions_bus,
              _getTransportEfficiencyColor(),
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildInsightCard(
              'M-Pesa Usage',
              intelligence.kenyaSpecificInsights.mpesaUsagePattern.usageFrequency.displayName,
              Icons.phone_android,
              Colors.green,
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildInsightCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsPreview() {
    final topRecommendations = intelligence.recommendations
        .where((r) => r.priority == Priority.high)
        .take(2)
        .toList();

    if (topRecommendations.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Great job! No urgent recommendations at this time.',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Recommendations',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...topRecommendations.map((recommendation) => 
          _buildRecommendationItem(recommendation)),
      ],
    );
  }

  Widget _buildRecommendationItem(FinancialRecommendation recommendation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: recommendation.priorityColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: recommendation.priorityColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            recommendation.typeIcon,
            color: recommendation.priorityColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: recommendation.priorityColor,
                    fontSize: 14,
                  ),
                ),
                if (recommendation.potentialSavings > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Save up to KES ${recommendation.potentialSavings.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: Colors.grey[400],
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onViewDetails,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insights, size: 20),
            SizedBox(width: 8),
            Text(
              'View Detailed Analysis',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSpendingPatternInsight() {
    final mostActiveDay = intelligence.spendingPatterns.mostActiveDay;
    final dayNames = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    
    if (mostActiveDay >= 1 && mostActiveDay <= 7) {
      return 'Most active: ${dayNames[mostActiveDay]}';
    }
    return 'Analyzing patterns...';
  }

  Color _getTransportEfficiencyColor() {
    switch (intelligence.kenyaSpecificInsights.transportOptimization.efficiency) {
      case TransportEfficiency.excellent:
        return Colors.green;
      case TransportEfficiency.good:
        return Colors.blue;
      case TransportEfficiency.fair:
        return Colors.orange;
      case TransportEfficiency.poor:
        return Colors.red;
      case TransportEfficiency.unknown:
        return Colors.grey;
    }
  }
}

class AIInsightsDetailScreen extends StatelessWidget {
  final FinancialIntelligence intelligence;

  const AIInsightsDetailScreen({
    super.key,
    required this.intelligence,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Financial Intelligence'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPredictiveInsights(),
            const SizedBox(height: 20),
            _buildKenyaSpecificInsights(),
            const SizedBox(height: 20),
            _buildRecommendations(),
            const SizedBox(height: 20),
            _buildAnomalies(),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictiveInsights() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Predictive Insights',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Next Week Spending Prediction',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            _buildWeeklyPredictionChart(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPredictionCard(
                    'Monthly Budget Need',
                    'KES ${intelligence.predictiveInsights.monthlyBudgetNeeds.toStringAsFixed(0)}',
                    Icons.account_balance_wallet,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPredictionCard(
                    'Confidence Score',
                    '${intelligence.predictiveInsights.confidenceScore.toStringAsFixed(0)}%',
                    Icons.psychology,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyPredictionChart() {
    final predictions = intelligence.predictiveInsights.nextWeekSpending;
    final maxPrediction = predictions.isNotEmpty ? predictions.reduce((a, b) => a > b ? a : b) : 0.0;
    
    return SizedBox(
      height: 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
          final amount = index < predictions.length ? predictions[index] : 0.0;
          final height = maxPrediction > 0 ? (amount / maxPrediction) * 80 : 0.0;
          
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'KES ${amount.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 10),
              ),
              const SizedBox(height: 4),
              Container(
                width: 20,
                height: height,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dayNames[index],
                style: const TextStyle(fontSize: 12),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildPredictionCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildKenyaSpecificInsights() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kenya-Specific Insights',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildMpesaInsights(),
            const SizedBox(height: 16),
            _buildTransportInsights(),
          ],
        ),
      ),
    );
  }

  Widget _buildMpesaInsights() {
    final mpesa = intelligence.kenyaSpecificInsights.mpesaUsagePattern;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.phone_android, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              const Text(
                'M-Pesa Usage Analysis',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(mpesa.usageInsight),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text('Transactions: ${mpesa.totalTransactions}'),
              ),
              Expanded(
                child: Text('Efficiency: ${mpesa.efficiencyScore.toStringAsFixed(0)}%'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransportInsights() {
    final transport = intelligence.kenyaSpecificInsights.transportOptimization;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_bus, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Transport Optimization',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(transport.recommendation),
          if (transport.potentialSavings > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Potential savings: KES ${transport.potentialSavings.toStringAsFixed(0)} (${transport.savingsPercentage.toStringAsFixed(1)}%)',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recommendations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...intelligence.recommendations.map((rec) => _buildRecommendationDetail(rec)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationDetail(FinancialRecommendation recommendation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(recommendation.typeIcon, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  recommendation.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: recommendation.priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  recommendation.priority.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    color: recommendation.priorityColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(recommendation.description),
          if (recommendation.potentialSavings > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Potential savings: KES ${recommendation.potentialSavings.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnomalies() {
    if (intelligence.anomalies.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 48),
              const SizedBox(height: 8),
              const Text(
                'No Anomalies Detected',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                'Your spending patterns look normal',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Spending Anomalies',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...intelligence.anomalies.map((anomaly) => _buildAnomalyItem(anomaly)),
          ],
        ),
      ),
    );
  }

  Widget _buildAnomalyItem(SpendingAnomaly anomaly) {
    final color = anomaly.severity == AnomalySeverity.high ? Colors.red :
                  anomaly.severity == AnomalySeverity.medium ? Colors.orange : Colors.yellow;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  anomaly.description,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            anomaly.suggestion,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
