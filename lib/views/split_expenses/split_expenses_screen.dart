import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../models/split_expense_model.dart';
import '../../themes/app_theme.dart';
import 'widgets/split_expense_card.dart';
import 'widgets/create_split_expense_button.dart';

class SplitExpensesScreen extends StatefulWidget {
  const SplitExpensesScreen({super.key});

  @override
  State<SplitExpensesScreen> createState() => _SplitExpensesScreenState();
}

class _SplitExpensesScreenState extends State<SplitExpensesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<SplitExpenseModel> _splitExpenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSplitExpenses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSplitExpenses() async {
    // In a real app, this would fetch from a repository
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate network delay
    setState(() {
      _splitExpenses = SplitExpenseModel.getSampleData();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Split Expenses'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'You Owe'),
            Tab(text: 'Owed to You'),
          ],
          labelColor: AppTheme.accentColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.accentColor,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildExpensesList(_splitExpenses),
                _buildExpensesList(_getExpensesYouOwe()),
                _buildExpensesList(_getExpensesOwedToYou()),
              ],
            ),
      floatingActionButton: CreateSplitExpenseButton(
        onPressed: _showCreateSplitExpenseDialog,
      ),
    );
  }

  Widget _buildExpensesList(List<SplitExpenseModel> expenses) {
    if (expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No split expenses found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a new split expense to get started',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSplitExpenses,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: expenses.length,
        itemBuilder: (context, index) {
          final expense = expenses[index];
          return SplitExpenseCard(
            expense: expense,
            onTap: () => _showExpenseDetails(expense),
          ).animate()
            .fadeIn(
              duration: const Duration(milliseconds: 300),
              delay: Duration(milliseconds: 50 * index),
            )
            .slideY(begin: 0.1, end: 0);
        },
      ),
    );
  }

  List<SplitExpenseModel> _getExpensesYouOwe() {
    // In a real app, you would filter based on the current user ID
    const currentUserId = 'user1'; // Hardcoded for demo
    
    return _splitExpenses.where((expense) {
      if (expense.createdById == currentUserId) return false;
      
      final participant = expense.participants.firstWhere(
        (p) => p.id == currentUserId,
        orElse: () => SplitParticipant(
          id: '', 
          name: '', 
          amountOwed: 0, 
          amountPaid: 0,
        ),
      );
      
      return participant.id.isNotEmpty && !participant.hasPaid;
    }).toList();
  }

  List<SplitExpenseModel> _getExpensesOwedToYou() {
    // In a real app, you would filter based on the current user ID
    const currentUserId = 'user1'; // Hardcoded for demo
    
    return _splitExpenses.where((expense) {
      if (expense.createdById != currentUserId) return false;
      
      // Check if anyone still owes money
      return expense.participants.any((p) => 
        p.id != currentUserId && !p.hasPaid
      );
    }).toList();
  }

  void _showExpenseDetails(SplitExpenseModel expense) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      expense.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat.yMMMd().format(expense.createdAt),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.category,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          expense.category ?? 'Uncategorized',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildAmountSection(expense),
                    const SizedBox(height: 24),
                    const Text(
                      'Participants',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...expense.participants.map((participant) => 
                      _buildParticipantTile(participant, expense),
                    ),
                    const SizedBox(height: 24),
                    if (expense.description.isNotEmpty) ...[
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        expense.description,
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Send reminders logic
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Reminders sent successfully'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.notifications_active),
                            label: const Text('Send Reminders'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Mark as paid logic
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Marked as paid'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Mark as Paid'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.successColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAmountSection(SplitExpenseModel expense) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              Text(
                currencyFormat.format(expense.totalAmount),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Paid So Far',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              Text(
                currencyFormat.format(expense.amountPaid),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.successColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Remaining',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              Text(
                currencyFormat.format(expense.amountRemaining),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: expense.amountRemaining > 0 
                      ? AppTheme.warningColor 
                      : AppTheme.successColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: expense.percentPaid / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                expense.isFullyPaid 
                    ? AppTheme.successColor 
                    : AppTheme.accentColor,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${expense.percentPaid.toStringAsFixed(0)}% paid',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantTile(SplitParticipant participant, SplitExpenseModel expense) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: participant.isPayer 
            ? AppTheme.accentColor.withAlpha((255 * 0.05).round()) 
            : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: participant.isPayer 
              ? AppTheme.accentColor.withAlpha((255 * 0.3).round()) 
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: participant.isPayer 
                ? AppTheme.accentColor.withAlpha((255 * 0.2).round()) 
                : Colors.grey.shade200,
            child: Text(
              participant.name[0],
              style: TextStyle(
                color: participant.isPayer 
                    ? AppTheme.accentColor 
                    : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      participant.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      currencyFormat.format(participant.amountOwed),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      participant.isPayer 
                          ? 'Paid the bill' 
                          : participant.hasPaid 
                              ? 'Fully paid' 
                              : 'Owes money',
                      style: TextStyle(
                        fontSize: 12,
                        color: participant.isPayer 
                            ? AppTheme.accentColor 
                            : participant.hasPaid 
                                ? AppTheme.successColor 
                                : Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      participant.hasPaid 
                          ? 'Paid: ${currencyFormat.format(participant.amountPaid)}' 
                          : 'Paid: ${participant.percentPaid.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: participant.hasPaid 
                            ? AppTheme.successColor 
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                if (!participant.hasPaid) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: participant.percentPaid / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        participant.percentPaid > 0 
                            ? AppTheme.successColor 
                            : AppTheme.warningColor,
                      ),
                      minHeight: 4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateSplitExpenseDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Split Expense'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g., Dinner at Restaurant',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Total Amount',
                    prefixText: '\$',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Add details about this expense',
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'You\'ll be able to add participants in the next step',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
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
                // In a real app, this would navigate to a participant selection screen
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Split expense created successfully'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Next'),
            ),
          ],
        );
      },
    );
  }
}
