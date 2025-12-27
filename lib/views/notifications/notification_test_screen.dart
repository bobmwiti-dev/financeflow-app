import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/notification_integration_service.dart';
import '../../services/smart_notification_service.dart';
import '../../viewmodels/transaction_viewmodel_fixed.dart';
import '../../viewmodels/income_viewmodel.dart';
import '../../viewmodels/budget_viewmodel.dart';
import '../../viewmodels/goal_viewmodel.dart';
import '../../viewmodels/bill_viewmodel.dart';
import '../../models/notification_model.dart';

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  final NotificationIntegrationService _integrationService = NotificationIntegrationService();
  final SmartNotificationService _notificationService = SmartNotificationService();
  
  bool _isInitialized = false;
  String _testResults = '';

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  void _initializeNotifications() {
    final transactionViewModel = Provider.of<TransactionViewModel>(context, listen: false);
    final incomeViewModel = Provider.of<IncomeViewModel>(context, listen: false);
    final budgetViewModel = Provider.of<BudgetViewModel>(context, listen: false);
    final goalViewModel = Provider.of<GoalViewModel>(context, listen: false);
    final billViewModel = Provider.of<BillViewModel>(context, listen: false);

    _integrationService.initialize(
      transactionViewModel: transactionViewModel,
      incomeViewModel: incomeViewModel,
      budgetViewModel: budgetViewModel,
      goalViewModel: goalViewModel,
      billViewModel: billViewModel,
    );

    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _runNotificationTests() async {
    setState(() {
      _testResults = 'Running notification tests...\n';
    });

    try {
      // Test 1: Generate sample notifications
      await _testSampleNotifications();
      
      // Test 2: Generate notifications from real data
      await _testRealDataNotifications();
      
      // Test 3: Test notification filtering
      await _testNotificationFiltering();
      
      setState(() {
        _testResults += '\n✅ All tests completed successfully!';
      });
      
    } catch (e) {
      setState(() {
        _testResults += '\n❌ Test failed: $e';
      });
    }
  }

  Future<void> _testSampleNotifications() async {
    setState(() {
      _testResults += '\n📝 Test 1: Generating sample notifications...';
    });

    final transactionViewModel = Provider.of<TransactionViewModel>(context, listen: false);
    final incomeViewModel = Provider.of<IncomeViewModel>(context, listen: false);
    final budgetViewModel = Provider.of<BudgetViewModel>(context, listen: false);
    final goalViewModel = Provider.of<GoalViewModel>(context, listen: false);
    final billViewModel = Provider.of<BillViewModel>(context, listen: false);

    await _integrationService.generateTestNotifications(
      transactionViewModel: transactionViewModel,
      incomeViewModel: incomeViewModel,
      budgetViewModel: budgetViewModel,
      goalViewModel: goalViewModel,
      billViewModel: billViewModel,
    );

    final notifications = _notificationService.notifications;
    setState(() {
      _testResults += '\n   Generated ${notifications.length} sample notifications';
      _testResults += '\n   Types: ${notifications.map((n) => n.type.name).toSet().join(', ')}';
    });
  }

  Future<void> _testRealDataNotifications() async {
    setState(() {
      _testResults += '\n\n📊 Test 2: Analyzing real financial data...';
    });

    final transactionViewModel = Provider.of<TransactionViewModel>(context, listen: false);
    final incomeViewModel = Provider.of<IncomeViewModel>(context, listen: false);
    final budgetViewModel = Provider.of<BudgetViewModel>(context, listen: false);
    final goalViewModel = Provider.of<GoalViewModel>(context, listen: false);
    final billViewModel = Provider.of<BillViewModel>(context, listen: false);

    // Analyze current data
    final transactionCount = transactionViewModel.allTransactions.length;
    final incomeCount = incomeViewModel.incomeSources.length;
    final budgetCount = budgetViewModel.budgets.length;
    final goalCount = goalViewModel.goals.length;
    final billCount = billViewModel.bills.length;

    setState(() {
      _testResults += '\n   Transactions: $transactionCount';
      _testResults += '\n   Income Sources: $incomeCount';
      _testResults += '\n   Budgets: $budgetCount';
      _testResults += '\n   Goals: $goalCount';
      _testResults += '\n   Bills: $billCount';
    });

    // Generate notifications based on real data
    await _integrationService.generateTestNotifications(
      transactionViewModel: transactionViewModel,
      incomeViewModel: incomeViewModel,
      budgetViewModel: budgetViewModel,
      goalViewModel: goalViewModel,
      billViewModel: billViewModel,
    );

    setState(() {
      _testResults += '\n   ✅ Real data analysis completed';
    });
  }

  Future<void> _testNotificationFiltering() async {
    setState(() {
      _testResults += '\n\n🔍 Test 3: Testing notification filtering...';
    });

    final notifications = _notificationService.notifications;
    final unreadCount = _notificationService.unreadCount;
    
    // Count by priority
    final priorityCounts = <NotificationPriority, int>{};
    for (final notification in notifications) {
      priorityCounts.update(
        notification.priority,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }

    // Count by type
    final typeCounts = <NotificationType, int>{};
    for (final notification in notifications) {
      typeCounts.update(
        notification.type,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }

    setState(() {
      _testResults += '\n   Total notifications: ${notifications.length}';
      _testResults += '\n   Unread notifications: $unreadCount';
      _testResults += '\n   Priority breakdown:';
      for (final entry in priorityCounts.entries) {
        _testResults += '\n     ${entry.key.name}: ${entry.value}';
      }
      _testResults += '\n   Type breakdown:';
      for (final entry in typeCounts.entries) {
        _testResults += '\n     ${entry.key.name}: ${entry.value}';
      }
    });
  }

  void _clearAllNotifications() {
    _notificationService.clearAll();
    setState(() {
      _testResults += '\n🗑️ All notifications cleared';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Testing'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isInitialized ? Icons.check_circle : Icons.hourglass_empty,
                          color: _isInitialized ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Notification System Status',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isInitialized 
                          ? '✅ Notification system initialized and ready'
                          : '⏳ Initializing notification system...',
                      style: TextStyle(
                        color: _isInitialized ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isInitialized ? _runNotificationTests : null,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Run Tests'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _clearAllNotifications,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(width: 12),
            
            // Navigation Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/notifications');
                    },
                    icon: const Icon(Icons.notifications),
                    label: const Text('View Notifications'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/reports');
                    },
                    icon: const Icon(Icons.assessment),
                    label: const Text('View Reports'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Test Results
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Test Results',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            _testResults.isEmpty 
                                ? 'Click "Run Tests" to start testing the notification system...'
                                : _testResults,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Real-time Notification Count
            StreamBuilder<List<SmartNotification>>(
              stream: _notificationService.notificationStream,
              builder: (context, snapshot) {
                final notifications = snapshot.data ?? [];
                final unreadCount = notifications.where((n) => !n.isRead).length;
                
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Live Notification Count',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Total: ${notifications.length} | Unread: $unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
