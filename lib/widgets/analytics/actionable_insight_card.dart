import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../models/insight_model.dart';

class ActionableInsightCard extends StatefulWidget {
  final Insight insight;
  final Function()? onTakeAction;
  final Function()? onDismiss;
  
  const ActionableInsightCard({
    super.key,
    required this.insight,
    this.onTakeAction,
    this.onDismiss,
  });

  @override
  State<ActionableInsightCard> createState() => _ActionableInsightCardState();
}

class _ActionableInsightCardState extends State<ActionableInsightCard> {
  bool _isExpanded = false;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _getBorderColor(widget.insight.type).withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getBackgroundColor(widget.insight.type),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIcon(widget.insight.type),
                      color: _getIconColor(widget.insight.type),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getBackgroundColor(widget.insight.type).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                widget.insight.type,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _getIconColor(widget.insight.type),
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              DateFormat('MMM d').format(widget.insight.date),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.insight.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.insight.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: _isExpanded ? null : 2,
                          overflow: _isExpanded ? null : TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_isExpanded) ...[
                const SizedBox(height: 16),
                _buildInsightDetails(),
                const SizedBox(height: 16),
                _buildActionButtons(),
              ],
              if (!_isExpanded) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _isExpanded = true;
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('See More'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 300)).slide(
          begin: const Offset(0, 0.1),
          end: const Offset(0, 0),
          duration: const Duration(milliseconds: 300),
        );
  }
  
  Widget _buildInsightDetails() {
    if (widget.insight is SpendingPatternInsight) {
      return _buildSpendingPatternDetails(widget.insight as SpendingPatternInsight);
    } else if (widget.insight is BudgetAlertInsight) {
      return _buildBudgetAlertDetails(widget.insight as BudgetAlertInsight);
    } else if (widget.insight is SavingOpportunityInsight) {
      return _buildSavingOpportunityDetails(widget.insight as SavingOpportunityInsight);
    } else if (widget.insight is FinancialHealthInsight) {
      return _buildFinancialHealthDetails(widget.insight as FinancialHealthInsight);
    } else {
      return const SizedBox.shrink();
    }
  }
  
  Widget _buildSpendingPatternDetails(SpendingPatternInsight insight) {
    final isIncrease = insight.percentageChange > 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailItem(
          'Category',
          insight.category,
        ),
        _buildDetailItem(
          'Time Frame',
          insight.timeFrame,
        ),
        _buildDetailItem(
          'Previous Amount',
          NumberFormat.currency(symbol: '\$').format(insight.previousAmount),
        ),
        _buildDetailItem(
          'Current Amount',
          NumberFormat.currency(symbol: '\$').format(insight.currentAmount),
        ),
        _buildDetailItem(
          'Change',
          '${insight.percentageChange >= 0 ? '+' : ''}${insight.percentageChange.toStringAsFixed(1)}%',
          valueColor: isIncrease ? Colors.red.shade700 : Colors.green.shade700,
          valueIcon: isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
        ),
      ],
    );
  }
  
  Widget _buildBudgetAlertDetails(BudgetAlertInsight insight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailItem(
          'Category',
          insight.category,
        ),
        _buildDetailItem(
          'Budget',
          NumberFormat.currency(symbol: '\$').format(insight.budgetAmount),
        ),
        _buildDetailItem(
          'Spent',
          NumberFormat.currency(symbol: '\$').format(insight.spentAmount),
        ),
        _buildDetailItem(
          'Usage',
          '${(insight.percentageUsed * 100).toStringAsFixed(0)}%',
          valueColor: insight.percentageUsed > 0.9 ? Colors.red.shade700 : Colors.amber.shade700,
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: insight.percentageUsed,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(
            insight.percentageUsed > 0.9 ? Colors.red.shade400 : 
            insight.percentageUsed > 0.7 ? Colors.orange.shade400 : 
            Colors.green.shade400,
          ),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
  
  Widget _buildSavingOpportunityDetails(SavingOpportunityInsight insight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailItem(
          'Category',
          insight.category,
        ),
        _buildDetailItem(
          'Potential Savings',
          NumberFormat.currency(symbol: '\$').format(insight.potentialSavings),
          valueColor: Colors.green.shade700,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber.shade600, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  insight.suggestion,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildFinancialHealthDetails(FinancialHealthInsight insight) {
    Color healthColor;
    IconData healthIcon;
    
    switch (insight.overallHealth) {
      case 'good':
        healthColor = Colors.green.shade700;
        healthIcon = Icons.sentiment_very_satisfied;
        break;
      case 'moderate':
        healthColor = Colors.orange.shade700;
        healthIcon = Icons.sentiment_neutral;
        break;
      default:
        healthColor = Colors.red.shade700;
        healthIcon = Icons.sentiment_very_dissatisfied;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(healthIcon, color: healthColor, size: 24),
            const SizedBox(width: 8),
            Text(
              'Overall Health: ${insight.overallHealth.toUpperCase()}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: healthColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildDetailItem(
          'Savings Rate',
          '${(insight.savingsRate * 100).toStringAsFixed(1)}%',
          valueColor: insight.savingsRate > 0.15 ? Colors.green.shade700 : Colors.amber.shade700,
        ),
        _buildDetailItem(
          'Debt-to-Income',
          insight.debtToIncomeRatio.toStringAsFixed(2),
          valueColor: insight.debtToIncomeRatio < 0.36 ? Colors.green.shade700 : Colors.red.shade700,
        ),
        _buildDetailItem(
          'Emergency Fund',
          '${insight.emergencyFundMonths.toStringAsFixed(1)} months',
          valueColor: insight.emergencyFundMonths > 3 ? Colors.green.shade700 : Colors.red.shade700,
        ),
        const SizedBox(height: 12),
        const Text(
          'Recommendations:',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        ...insight.recommendations.map((recommendation) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  recommendation,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
  
  Widget _buildDetailItem(String label, String value, {Color? valueColor, IconData? valueIcon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          Row(
            children: [
              if (valueIcon != null) ...[
                Icon(valueIcon, size: 14, color: valueColor),
                const SizedBox(width: 4),
              ],
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: widget.onDismiss,
          child: const Text('Dismiss'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: widget.onTakeAction,
          style: ElevatedButton.styleFrom(
            backgroundColor: _getIconColor(widget.insight.type),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_getActionText(widget.insight.type)),
              const Icon(Icons.arrow_forward, size: 16),
            ],
          ),
        ),
      ],
    );
  }
  
  String _getActionText(String insightType) {
    switch (insightType) {
      case 'Spending Pattern':
        return 'View Details ';
      case 'Budget Alert':
        return 'Adjust Budget ';
      case 'Saving Opportunity':
        return 'Start Saving ';
      case 'Financial Health':
        return 'Take Action ';
      default:
        return 'Take Action ';
    }
  }
  
  IconData _getIcon(String insightType) {
    switch (insightType) {
      case 'Spending Pattern':
        return Icons.trending_up;
      case 'Budget Alert':
        return Icons.warning_amber;
      case 'Saving Opportunity':
        return Icons.savings;
      case 'Financial Health':
        return Icons.favorite;
      default:
        return Icons.insights;
    }
  }
  
  Color _getIconColor(String insightType) {
    switch (insightType) {
      case 'Spending Pattern':
        return Colors.blue.shade700;
      case 'Budget Alert':
        return Colors.orange.shade700;
      case 'Saving Opportunity':
        return Colors.green.shade700;
      case 'Financial Health':
        return Colors.purple.shade700;
      default:
        return Colors.blueGrey.shade700;
    }
  }
  
  Color _getBackgroundColor(String insightType) {
    switch (insightType) {
      case 'Spending Pattern':
        return Colors.blue.shade50;
      case 'Budget Alert':
        return Colors.orange.shade50;
      case 'Saving Opportunity':
        return Colors.green.shade50;
      case 'Financial Health':
        return Colors.purple.shade50;
      default:
        return Colors.blueGrey.shade50;
    }
  }
  
  Color _getBorderColor(String insightType) {
    switch (insightType) {
      case 'Spending Pattern':
        return Colors.blue.shade300;
      case 'Budget Alert':
        return Colors.orange.shade300;
      case 'Saving Opportunity':
        return Colors.green.shade300;
      case 'Financial Health':
        return Colors.purple.shade300;
      default:
        return Colors.blueGrey.shade300;
    }
  }
}
