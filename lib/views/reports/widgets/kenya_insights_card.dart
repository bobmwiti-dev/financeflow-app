import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../models/transaction_model.dart';
import '../../../models/time_period_model.dart';
import '../../../utils/currency_extensions.dart';
import 'report_card.dart';

class KenyaInsightsCard extends StatefulWidget {
  final TimePeriod selectedPeriod;
  final List<Transaction> allTransactions;

  const KenyaInsightsCard({
    super.key,
    required this.selectedPeriod,
    required this.allTransactions,
  });

  @override
  State<KenyaInsightsCard> createState() => _KenyaInsightsCardState();
}

class _KenyaInsightsCardState extends State<KenyaInsightsCard>
    with TickerProviderStateMixin {
  late AnimationController _loadingController;
  late Animation<double> _loadingAnimation;
  
  Map<String, dynamic> _insights = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _loadingAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );
    
    _analyzeKenyaInsights();
  }

  @override
  void didUpdateWidget(KenyaInsightsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPeriod != widget.selectedPeriod ||
        oldWidget.allTransactions.length != widget.allTransactions.length) {
      _analyzeKenyaInsights();
    }
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  void _analyzeKenyaInsights() async {
    setState(() {
      _isLoading = true;
    });

    _loadingController.reset();
    _loadingController.forward();

    // Simulate analysis time for better UX
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    final periodTransactions = widget.allTransactions
        .where((tx) => widget.selectedPeriod.containsDate(tx.date))
        .toList();

    final insights = _generateKenyaInsights(periodTransactions);

    if (mounted) {
      setState(() {
        _insights = insights;
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _generateKenyaInsights(List<Transaction> transactions) {
    final insights = <String, dynamic>{};

    // 1. M-Pesa vs Bank Analysis
    insights['mpesa_analysis'] = _analyzeMpesaVsBank(transactions);
    
    // 2. Transport Analysis (Matatu vs Uber)
    insights['transport_analysis'] = _analyzeTransport(transactions);
    
    // 3. Seasonal Spending Patterns
    insights['seasonal_patterns'] = _analyzeSeasonalPatterns(transactions);
    
    // 4. Chama Contributions
    insights['chama_analysis'] = _analyzeChamaContributions(transactions);
    
    // 5. Kenya-Specific Categories
    insights['kenya_categories'] = _analyzeKenyaCategories(transactions);
    
    // 6. Mobile Money Efficiency
    insights['mobile_efficiency'] = _analyzeMobileMoneyEfficiency(transactions);

    return insights;
  }

  Map<String, dynamic> _analyzeMpesaVsBank(List<Transaction> transactions) {
    final mpesaTransactions = transactions.where((tx) => 
        tx.title.toLowerCase().contains('mpesa') ||
        tx.title.toLowerCase().contains('safaricom') ||
        tx.title.toLowerCase().contains('paybill') ||
        tx.title.toLowerCase().contains('till') ||
        tx.category.toLowerCase().contains('mobile money')).toList();

    final bankTransactions = transactions.where((tx) => 
        tx.title.toLowerCase().contains('bank') ||
        tx.title.toLowerCase().contains('atm') ||
        tx.title.toLowerCase().contains('kcb') ||
        tx.title.toLowerCase().contains('equity') ||
        tx.title.toLowerCase().contains('cooperative')).toList();

    final mpesaTotal = mpesaTransactions.fold(0.0, (sum, tx) => sum + tx.amount.abs());
    final bankTotal = bankTransactions.fold(0.0, (sum, tx) => sum + tx.amount.abs());
    final totalTransactions = mpesaTransactions.length + bankTransactions.length;

    String insight = '';
    String recommendation = '';
    Color color = Colors.teal;

    if (totalTransactions == 0) {
      insight = 'No M-Pesa or bank transactions detected';
      recommendation = 'Consider tracking your mobile money transactions';
    } else {
      final mpesaPercentage = totalTransactions > 0 
          ? (mpesaTransactions.length / totalTransactions) * 100 
          : 0.0;

      if (mpesaPercentage > 70) {
        insight = '${mpesaPercentage.toStringAsFixed(0)}% of transactions via M-Pesa';
        recommendation = 'Great mobile money usage! Consider M-Pesa savings products';
        color = Colors.green;
      } else if (mpesaPercentage > 40) {
        insight = 'Balanced M-Pesa (${mpesaPercentage.toStringAsFixed(0)}%) and bank usage';
        recommendation = 'Good mix of payment methods for security';
        color = Colors.blue;
      } else {
        insight = 'Low M-Pesa usage (${mpesaPercentage.toStringAsFixed(0)}%)';
        recommendation = 'Consider M-Pesa for convenient payments';
        color = Colors.orange;
      }
    }

    return {
      'mpesa_total': mpesaTotal,
      'bank_total': bankTotal,
      'mpesa_count': mpesaTransactions.length,
      'bank_count': bankTransactions.length,
      'insight': insight,
      'recommendation': recommendation,
      'color': color,
    };
  }

  Map<String, dynamic> _analyzeTransport(List<Transaction> transactions) {
    final matatu = transactions.where((tx) => 
        tx.title.toLowerCase().contains('matatu') ||
        tx.title.toLowerCase().contains('bus') ||
        tx.title.toLowerCase().contains('stage') ||
        tx.category.toLowerCase().contains('transport')).toList();

    final uber = transactions.where((tx) => 
        tx.title.toLowerCase().contains('uber') ||
        tx.title.toLowerCase().contains('bolt') ||
        tx.title.toLowerCase().contains('taxi') ||
        tx.title.toLowerCase().contains('ride')).toList();

    final matatuTotal = matatu.fold(0.0, (sum, tx) => sum + tx.amount.abs());
    final uberTotal = uber.fold(0.0, (sum, tx) => sum + tx.amount.abs());
    final totalTransport = matatuTotal + uberTotal;

    String insight = '';
    String recommendation = '';
    Color color = Colors.blue;

    if (totalTransport == 0) {
      insight = 'No transport expenses detected';
      recommendation = 'Track your transport costs for better budgeting';
    } else {
      final matatuPercentage = totalTransport > 0 ? (matatuTotal / totalTransport) * 100 : 0.0;
      
      if (matatuPercentage > 80) {
        insight = 'Mostly using matatu/bus (${matatuPercentage.toStringAsFixed(0)}%)';
        recommendation = 'Great cost savings! Average: ${(matatuTotal / matatu.length).toKenyaCurrency()} per trip';
        color = Colors.green;
      } else if (matatuPercentage > 50) {
        insight = 'Balanced transport usage';
        recommendation = 'Good mix of affordable and convenient transport';
        color = Colors.blue;
      } else {
        insight = 'High ride-hailing usage (${(100 - matatuPercentage).toStringAsFixed(0)}%)';
        recommendation = 'Consider matatu for regular routes to save money';
        color = Colors.orange;
      }
    }

    return {
      'matatu_total': matatuTotal,
      'uber_total': uberTotal,
      'matatu_count': matatu.length,
      'uber_count': uber.length,
      'insight': insight,
      'recommendation': recommendation,
      'color': color,
    };
  }

  Map<String, dynamic> _analyzeSeasonalPatterns(List<Transaction> transactions) {
    final now = DateTime.now();
    final currentMonth = now.month;
    
    String seasonalInsight = '';
    String recommendation = '';
    Color color = Colors.purple;

    // Christmas season (December)
    if (currentMonth == 12) {
      final decemberSpending = transactions.fold(0.0, (sum, tx) => sum + tx.amount.abs());
      seasonalInsight = 'December spending: ${decemberSpending.toKenyaCurrency()}';
      recommendation = 'Christmas season - budget for gifts and travel';
      color = Colors.red;
    }
    // Back to school (January, April, September)
    else if ([1, 4, 9].contains(currentMonth)) {
      final schoolTransactions = transactions.where((tx) => 
          tx.title.toLowerCase().contains('school') ||
          tx.title.toLowerCase().contains('fees') ||
          tx.title.toLowerCase().contains('uniform') ||
          tx.title.toLowerCase().contains('books')).toList();
      
      if (schoolTransactions.isNotEmpty) {
        final schoolTotal = schoolTransactions.fold(0.0, (sum, tx) => sum + tx.amount.abs());
        seasonalInsight = 'School expenses: ${schoolTotal.toKenyaCurrency()}';
        recommendation = 'School term season - plan for education costs';
        color = Colors.blue;
      } else {
        seasonalInsight = 'Back-to-school season';
        recommendation = 'Consider setting aside funds for education expenses';
        color = Colors.orange;
      }
    }
    // Mid-year (July)
    else if (currentMonth == 7) {
      seasonalInsight = 'Mid-year spending review';
      recommendation = 'Good time to review and adjust your budget';
      color = Colors.green;
    }
    // Regular months
    else {
      final monthlySpending = transactions.fold(0.0, (sum, tx) => sum + tx.amount.abs());
      seasonalInsight = monthlySpending > 0 
          ? 'Regular spending: ${monthlySpending.toKenyaCurrency()}'
          : 'Regular spending pattern';
      recommendation = 'Maintain consistent budgeting habits';
      color = Colors.blue;
    }

    return {
      'insight': seasonalInsight,
      'recommendation': recommendation,
      'color': color,
      'current_month': currentMonth,
    };
  }

  Map<String, dynamic> _analyzeChamaContributions(List<Transaction> transactions) {
    final chamaTransactions = transactions.where((tx) => 
        tx.title.toLowerCase().contains('chama') ||
        tx.title.toLowerCase().contains('group') ||
        tx.title.toLowerCase().contains('contribution') ||
        tx.title.toLowerCase().contains('merry') ||
        tx.title.toLowerCase().contains('welfare')).toList();

    final chamaTotal = chamaTransactions.fold(0.0, (sum, tx) => sum + tx.amount.abs());
    
    String insight = '';
    String recommendation = '';
    Color color = Colors.indigo;

    if (chamaTransactions.isEmpty) {
      insight = 'No chama contributions detected';
      recommendation = 'Consider joining a chama for group savings';
    } else {
      final avgContribution = chamaTotal / chamaTransactions.length;
      insight = '${chamaTransactions.length} chama contributions (${chamaTotal.toKenyaCurrency()})';
      
      if (avgContribution > 5000) {
        recommendation = 'High chama contributions - great for long-term savings!';
        color = Colors.green;
      } else {
        recommendation = 'Regular chama participation - consider increasing contributions';
        color = Colors.blue;
      }
    }

    return {
      'total': chamaTotal,
      'count': chamaTransactions.length,
      'insight': insight,
      'recommendation': recommendation,
      'color': color,
    };
  }

  Map<String, dynamic> _analyzeKenyaCategories(List<Transaction> transactions) {
    final categories = <String, double>{};
    
    // Kenya-specific categories
    final kenyaCategories = {
      'Airtime': ['airtime', 'safaricom', 'airtel', 'telkom'],
      'Utilities': ['kplc', 'nairobi water', 'electricity', 'water'],
      'Food & Dining': ['nakumatt', 'tuskys', 'carrefour', 'naivas', 'restaurant'],
      'Transport': ['matatu', 'uber', 'bolt', 'fuel', 'petrol'],
      'Shopping': ['mall', 'supermarket', 'shop'],
    };

    for (final tx in transactions) {
      for (final entry in kenyaCategories.entries) {
        final categoryName = entry.key;
        final keywords = entry.value;
        
        if (keywords.any((keyword) => 
            tx.title.toLowerCase().contains(keyword) ||
            tx.category.toLowerCase().contains(keyword.toLowerCase()))) {
          categories.update(categoryName, (value) => value + tx.amount.abs(), 
              ifAbsent: () => tx.amount.abs());
          break;
        }
      }
    }

    final topCategory = categories.isNotEmpty 
        ? categories.entries.reduce((a, b) => a.value > b.value ? a : b)
        : null;

    return {
      'categories': categories,
      'top_category': topCategory?.key ?? 'None',
      'top_amount': topCategory?.value ?? 0.0,
    };
  }

  Map<String, dynamic> _analyzeMobileMoneyEfficiency(List<Transaction> transactions) {
    final mobileTransactions = transactions.where((tx) => 
        tx.title.toLowerCase().contains('mpesa') ||
        tx.title.toLowerCase().contains('airtel money') ||
        tx.title.toLowerCase().contains('mobile')).toList();

    final smallTransactions = mobileTransactions.where((tx) => tx.amount.abs() < 100).length;
    final largeTransactions = mobileTransactions.where((tx) => tx.amount.abs() > 1000).length;
    
    String efficiency = '';
    Color color = Colors.teal;

    if (mobileTransactions.isEmpty) {
      efficiency = 'No mobile money usage detected';
    } else {
      final avgAmount = mobileTransactions.fold(0.0, (sum, tx) => sum + tx.amount.abs()) / mobileTransactions.length;
      
      if (avgAmount > 500) {
        efficiency = 'Efficient mobile money usage (avg: ${avgAmount.toKenyaCurrency()})';
        color = Colors.green;
      } else {
        efficiency = 'Many small mobile transactions (avg: ${avgAmount.toKenyaCurrency()})';
        color = Colors.orange;
      }
    }

    return {
      'total_transactions': mobileTransactions.length,
      'small_transactions': smallTransactions,
      'large_transactions': largeTransactions,
      'efficiency': efficiency,
      'color': color,
    };
  }

  @override
  Widget build(BuildContext context) {
    return ReportCard(
      title: '🇰🇪 Kenya Financial Insights - ${widget.selectedPeriod.displayName}',
      child: _isLoading ? _buildLoadingState() : _buildInsightsContent(),
    ).animate()
      .fadeIn(duration: 500.ms)
      .slideY(begin: 0.2, duration: 500.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildLoadingState() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _loadingAnimation,
            builder: (context, child) {
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CircularProgressIndicator(
                        value: _loadingAnimation.value,
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
                      ),
                    ),
                    Center(
                      child: Text(
                        '🇰🇪',
                        style: TextStyle(fontSize: 32),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Analyzing Kenya-Specific Patterns',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'M-Pesa, transport, seasonal patterns, and more...',
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

  Widget _buildInsightsContent() {
    if (_insights.isEmpty) {
      return _buildNoDataState();
    }

    return Column(
      children: [
        // Header with Kenya flag
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.withValues(alpha: 0.1),
                Colors.red.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.green.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '🇰🇪',
                  style: TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kenya Financial Intelligence',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Insights tailored for Kenyan financial habits',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Insights Grid
        _buildInsightsGrid(),
      ],
    );
  }

  Widget _buildInsightsGrid() {
    return Column(
      children: [
        // M-Pesa vs Bank Analysis
        _buildInsightTile(
          '📱 Mobile Money Analysis',
          _insights['mpesa_analysis'],
          Icons.phone_android,
        ),
        
        const SizedBox(height: 12),
        
        // Transport Analysis
        _buildInsightTile(
          '🚌 Transport Insights',
          _insights['transport_analysis'],
          Icons.directions_bus,
        ),
        
        const SizedBox(height: 12),
        
        // Seasonal Patterns
        _buildInsightTile(
          '📅 Seasonal Patterns',
          _insights['seasonal_patterns'],
          Icons.calendar_today,
        ),
        
        const SizedBox(height: 12),
        
        // Chama Contributions
        _buildInsightTile(
          '👥 Chama Contributions',
          _insights['chama_analysis'],
          Icons.group,
        ),
        
        const SizedBox(height: 12),
        
        // Mobile Money Efficiency
        _buildInsightTile(
          '⚡ Mobile Money Efficiency',
          _insights['mobile_efficiency'],
          Icons.speed,
        ),
      ],
    );
  }

  Widget _buildInsightTile(String title, Map<String, dynamic>? data, IconData icon) {
    if (data == null) return const SizedBox.shrink();
    
    final color = data['color'] as Color? ?? Colors.blue;
    final insight = data['insight'] as String? ?? '';
    final recommendation = data['recommendation'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Text(
            insight,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          
          if (recommendation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 14,
                    color: color,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      recommendation,
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoDataState() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '🇰🇪',
            style: TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 16),
          Text(
            'No Kenya-Specific Data',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add M-Pesa, transport, or chama transactions to see insights',
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
}
