import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:logging/logging.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../services/mpesa_analytics_service.dart';
import '../../models/mpesa_analytics_model.dart';
import '../../widgets/animated_button.dart';
import '../../utils/currency_extensions.dart';

class MpesaAnalyticsScreen extends StatefulWidget {
  const MpesaAnalyticsScreen({super.key});

  @override
  State<MpesaAnalyticsScreen> createState() => _MpesaAnalyticsScreenState();
}

class _MpesaAnalyticsScreenState extends State<MpesaAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  final Logger _logger = Logger('MpesaAnalyticsScreen');
  
  bool _isLoading = true;
  MpesaAnalyticsSummary? _analytics;
  String? _errorMessage;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final analytics = await MpesaAnalyticsService.generateAnalytics();
      setState(() {
        _analytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      _logger.severe('Error loading M-Pesa analytics: $e');
      setState(() {
        _errorMessage = 'Failed to load analytics: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('M-Pesa Analytics'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingView()
          : _errorMessage != null
              ? _buildErrorView()
              : _analytics == null
                  ? _buildNoDataView()
                  : _buildAnalyticsView(),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.green),
          SizedBox(height: 16),
          Text('Analyzing your M-Pesa data...'),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(
            'Error Loading Analytics',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          AnimatedButton(
            onPressed: _loadAnalytics,
            text: 'Retry',
            color: Colors.green,
            icon: Icons.refresh,
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No M-Pesa Data Found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Import your M-Pesa transactions first to see analytics',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          AnimatedButton(
            onPressed: () => Navigator.pushNamed(context, '/mpesa_import'),
            text: 'Import M-Pesa Data',
            color: Colors.green,
            icon: Icons.sms,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsView() {
    return Column(
      children: [
        // Key Insights Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade600, Colors.green.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Key Insights',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ..._analytics!.keyInsights.take(3).map((insight) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.insights, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        insight,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
        
        // Tab Bar
        TabBar(
          controller: _tabController,
          labelColor: Colors.green.shade600,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.green.shade600,
          tabs: const [
            Tab(text: 'Balance', icon: Icon(Icons.account_balance_wallet)),
            Tab(text: 'Merchants', icon: Icon(Icons.store)),
            Tab(text: 'Agents', icon: Icon(Icons.location_on)),
            Tab(text: 'Patterns', icon: Icon(Icons.analytics)),
          ],
        ),
        
        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildBalanceTab(),
              _buildMerchantsTab(),
              _buildAgentsTab(),
              _buildPatternsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceTab() {
    final balanceTrend = _analytics!.balanceTrend;
    // Using toKenyaDualCurrency() for Kenya M-Pesa merchant analytics
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance Overview Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Current Balance',
                  balanceTrend.currentBalance.toKenyaDualCurrency(),
                  Icons.account_balance_wallet,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Average Balance',
                  balanceTrend.averageBalance.toKenyaDualCurrency(),
                  Icons.trending_up,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Highest Balance',
                  balanceTrend.highestBalance.toKenyaDualCurrency(),
                  Icons.arrow_upward,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Balance Health',
                  '${balanceTrend.balanceHealthScore.toStringAsFixed(0)}%',
                  Icons.health_and_safety,
                  balanceTrend.balanceHealthScore > 70 ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Balance Trend Chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Balance Trend',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: balanceTrend.balanceHistory.isNotEmpty
                        ? _buildBalanceChart(balanceTrend.balanceHistory)
                        : const Center(child: Text('No balance history available')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMerchantsTab() {
    final merchants = _analytics!.topMerchants;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Merchants',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          if (merchants.isEmpty)
            const Center(
              child: Text('No merchant data available'),
            )
          else
            ...merchants.map((merchant) => _buildMerchantCard(merchant)),
        ],
      ),
    );
  }

  Widget _buildAgentsTab() {
    final agents = _analytics!.frequentAgents;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Frequent Agents',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          if (agents.isEmpty)
            const Center(
              child: Text('No agent data available'),
            )
          else
            ...agents.map((agent) => _buildAgentCard(agent)),
        ],
      ),
    );
  }

  Widget _buildPatternsTab() {
    final patterns = _analytics!.patterns;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transaction Patterns',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Peak Activity
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Peak Activity',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      Text('Most active at ${patterns.peakSpendingHour}:00'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.green.shade600),
                      const SizedBox(width: 8),
                      Text('Most active on ${_getDayName(patterns.mostActiveDay)}'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Transaction Stats
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transaction Statistics',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPatternStat('Total Transactions', '${patterns.totalTransactions}'),
                  _buildPatternStat('Average Amount', patterns.averageTransactionAmount.toKenyaDualCurrency()),
                  _buildPatternStat('Largest Transaction', patterns.largestTransaction.toKenyaDualCurrency()),
                  _buildPatternStat('Top Category', patterns.topSpendingCategory),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildMerchantCard(MerchantSpendingAnalysis merchant) {
    // Using toKenyaDualCurrency() for Kenya M-Pesa merchant analytics
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green.shade100,
                  child: Icon(Icons.store, color: Colors.green.shade600),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        merchant.merchantName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${merchant.transactionCount} transactions',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  merchant.totalSpent.toKenyaDualCurrency(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text('Avg: ${merchant.averageTransaction.toKenyaDualCurrency()}'),
                ),
                Expanded(
                  child: Text('Frequency: ${merchant.monthlyFrequency.toStringAsFixed(1)}/month'),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.2, end: 0);
  }

  Widget _buildAgentCard(AgentAnalysis agent) {
    // Using toKenyaDualCurrency() for Kenya M-Pesa merchant analytics
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(Icons.location_on, color: Colors.blue.shade600),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agent.agentName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${agent.totalTransactions} transactions • ${agent.primaryUsage}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  agent.totalAmount.toKenyaDualCurrency(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text('Withdrawals: ${agent.withdrawalCount}'),
                ),
                Expanded(
                  child: Text('Deposits: ${agent.depositCount}'),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2, end: 0);
  }

  Widget _buildBalanceChart(List<MpesaBalancePoint> balanceHistory) {
    final spots = balanceHistory.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.balance);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.green.shade600,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.shade100,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _getDayName(int dayOfWeek) {
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return days[dayOfWeek % 7];
  }
}
