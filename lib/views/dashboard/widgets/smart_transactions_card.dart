import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import '../../../models/transaction_model.dart';
import '../../../utils/category_icons.dart';
import '../../../utils/kenya_merchant_recognition.dart';
import '../../../viewmodels/transaction_viewmodel_fixed.dart' as fixed;

/// Recent Transactions card displaying user's transaction history
class RecentTransactionsCard extends StatefulWidget {
  final int maxTransactions;
  final VoidCallback? onViewAll;
  final DateTime? selectedMonth;

  const RecentTransactionsCard({
    super.key,
    this.maxTransactions = 5,
    this.onViewAll,
    this.selectedMonth,
  });

  @override
  State<RecentTransactionsCard> createState() => _RecentTransactionsCardState();
}

class _RecentTransactionsCardState extends State<RecentTransactionsCard> 
    with TickerProviderStateMixin {
  final Logger _logger = Logger('RecentTransactionsCard');
  late AnimationController _slideController;
  late AnimationController _pulseController;
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Today'];
  int _hoveredIndex = -1;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _slideController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<fixed.TransactionViewModel>(
      builder: (context, transactionVM, child) {
        final transactions = _getFilteredTransactions(transactionVM.transactions);
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildFilterChips(),
              _buildTransactionsList(transactions),
            ],
          ),
        ).animate()
          .fadeIn(duration: 600.ms)
          .slideY(begin: 0.3, duration: 600.ms, curve: Curves.easeOutCubic);
      },
    );
  }

  Widget _buildHeader() {
    final selectedMonth = widget.selectedMonth ?? DateTime.now();
    final monthName = DateFormat.MMMM().format(selectedMonth);
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recent Transactions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.calendar_month,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$monthName ${selectedMonth.year}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.receipt_long,
              color: Colors.blue[600],
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                }
              },
              backgroundColor: Colors.grey[100],
              selectedColor: Colors.blue.withValues(alpha: 0.2),
              checkmarkColor: Colors.blue[700],
              labelStyle: TextStyle(
                color: isSelected ? Colors.blue[700] : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionsList(List<Transaction> transactions) {
    if (transactions.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return _buildSmartTransactionTile(transaction, index);
          },
        ),
        if (widget.onViewAll != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextButton(
              onPressed: widget.onViewAll,
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue[700],
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('View All Transactions'),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: 14),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSmartTransactionTile(Transaction transaction, int index) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final isExpense = transaction.isExpense;
    final isHovered = _hoveredIndex == index;
    
    // Enhanced with Kenya merchant recognition and smart categorization
    final merchantInfo = KenyaMerchantRecognition.recognizeMerchant(
      transaction.description ?? transaction.title
    );
    
    final categoryColor = merchantInfo?.color ?? CategoryIcons.getColorForCategory(transaction.category);
    final displayName = merchantInfo?.displayName ?? transaction.title;
    final smartCategory = merchantInfo?.category ?? transaction.category;
    
    // Smart insights based on transaction patterns
    final insights = _generateTransactionInsights(transaction, merchantInfo);
    
    return MouseRegion(
      onEnter: (_) {
        if (mounted) {
          setState(() => _hoveredIndex = index);
        }
      },
      onExit: (_) {
        if (mounted) {
          setState(() => _hoveredIndex = -1);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isHovered ? Colors.blue.withValues(alpha: 0.05) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isHovered ? Colors.blue.withValues(alpha: 0.3) : Colors.grey[200]!,
            width: isHovered ? 1.5 : 1,
          ),
          boxShadow: isHovered ? [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              _logger.info('Smart transaction tapped: ${transaction.title}');
              Navigator.pushNamed(
                context,
                '/transaction_details',
                arguments: transaction,
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CategoryIcons.getBrandCircleWidget(
                    transaction.title,
                    size: 48.0,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: isHovered ? 16 : 15,
                            color: isHovered ? Colors.blue[700] : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: categoryColor.withValues(alpha: isHovered ? 0.2 : 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                smartCategory,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: categoryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat.MMMd().format(transaction.date),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        if (insights.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                size: 12,
                                color: Colors.blue[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  insights,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.blue[600],
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isHovered ? 16 : 15,
                          color: isExpense ? Colors.red[600] : Colors.green[600],
                        ),
                        child: Text(currencyFormat.format(transaction.amount.abs())),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isExpense 
                            ? Colors.red.withValues(alpha: isHovered ? 0.2 : 0.1) 
                            : Colors.green.withValues(alpha: isHovered ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isExpense ? Icons.arrow_upward : Icons.arrow_downward,
                              size: 10,
                              color: isExpense ? Colors.red[700] : Colors.green[700],
                            ),
                            const SizedBox(width: 2),
                            Text(
                              isExpense ? 'OUT' : 'IN',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isExpense ? Colors.red[700] : Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate(delay: (index * 100).ms)
      .fadeIn(duration: 400.ms)
      .slideX(begin: 0.3, duration: 400.ms);
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 40,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start tracking your expenses and income',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/add_transaction');
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Transaction'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Transaction> _getFilteredTransactions(List<Transaction> transactions) {
    final selectedMonth = widget.selectedMonth ?? DateTime.now();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // First filter by selected month
    List<Transaction> monthFiltered = transactions.where((t) {
      return t.date.year == selectedMonth.year && t.date.month == selectedMonth.month;
    }).toList();
    
    List<Transaction> filtered = monthFiltered;
    
    switch (_selectedFilter) {
      case 'Today':
        filtered = monthFiltered.where((t) {
          final transactionDate = DateTime(t.date.year, t.date.month, t.date.day);
          return transactionDate.isAtSameMomentAs(today);
        }).toList();
        break;
      default: // 'All'
        filtered = monthFiltered;
    }
    
    // Sort by date (most recent first)
    filtered.sort((a, b) => b.date.compareTo(a.date));
    
    _logger.info('Filtered ${filtered.length} transactions for ${DateFormat.MMMM().format(selectedMonth)} ${selectedMonth.year} with filter: $_selectedFilter');
    
    return filtered.take(widget.maxTransactions).toList();
  }

  String _generateTransactionInsights(Transaction transaction, MerchantInfo? merchantInfo) {
    final now = DateTime.now();
    final daysSince = now.difference(transaction.date).inDays;
    
    // Recent transaction insight
    if (daysSince == 0) {
      return 'Today';
    } else if (daysSince == 1) {
      return 'Yesterday';
    }
    
    // Merchant-specific insights (updated for USD amounts)
    if (merchantInfo != null) {
      if (merchantInfo.category == 'Transport' && transaction.amount.abs() > 50) {
        return 'Higher than usual transport cost';
      } else if (merchantInfo.category == 'Food' && daysSince < 7) {
        return 'Recent dining expense';
      } else if (merchantInfo.category == 'Shopping' && transaction.amount.abs() > 200) {
        return 'Large purchase';
      }
    }
    
    // Amount-based insights (updated for USD amounts)
    if (transaction.amount.abs() > 500) {
      return 'Large transaction';
    } else if (transaction.isExpense && transaction.amount.abs() < 10) {
      return 'Small expense';
    }
    
    return '';
  }
}
