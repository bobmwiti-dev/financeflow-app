import 'dart:math';

import 'package:financeflow_app/viewmodels/bill_viewmodel.dart';
import 'package:financeflow_app/viewmodels/transaction_viewmodel_fixed.dart' as fixed;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class InMyPocketCard extends StatefulWidget {
  const InMyPocketCard({super.key});

  @override
  State<InMyPocketCard> createState() => _InMyPocketCardState();
}

class _InMyPocketCardState extends State<InMyPocketCard> with TickerProviderStateMixin {
  bool _showTotalBalance = false;
  bool _showBreakdown = false;
  bool _isFlipped = false;
  double _lastInMyPocketAmount = 0;
  DateTime? _lastUpdated;

  late final AnimationController _pulseController;
  late final AnimationController _flipController;
  Future<void>? _dataLoadingFuture;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _dataLoadingFuture = _fetchData();
    _setupListeners();
  }

  Future<void> _fetchData() async {
    final transactionViewModel = Provider.of<fixed.TransactionViewModel>(context, listen: false);
    final billViewModel = Provider.of<BillViewModel>(context, listen: false);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    // Fetch all data concurrently
    await transactionViewModel.loadTransactionsByMonth(DateTime.now());

    if (uid != null) {
      await billViewModel.loadBills(uid);
    }

    if (mounted) {
      setState(() {
        _lastUpdated = DateTime.now();
      });
    }
  }

  void _setupListeners() {
    final transactionViewModel = Provider.of<fixed.TransactionViewModel>(context, listen: false);
    transactionViewModel.addListener(() {
      if (!mounted) return;
      final newBalance = transactionViewModel.getBalance();
      if (newBalance != _lastInMyPocketAmount) {
        _pulseController.forward(from: 0.0);
        setState(() {
          _lastInMyPocketAmount = newBalance;
          _lastUpdated = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _flipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _dataLoadingFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 235,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        return GestureDetector(
          onLongPress: () {
            if (_flipController.isCompleted) {
              _flipController.reverse();
            } else {
              _flipController.forward();
            }
            setState(() => _isFlipped = !_isFlipped);
          },
          onTap: () {
            if (_isFlipped) return; // Disable tap when flipped
            setState(() {
              if (_showBreakdown) {
                _showBreakdown = false;
              } else {
                _showTotalBalance = !_showTotalBalance;
              }
            });
          },
          onVerticalDragEnd: (details) {
            if (_isFlipped) return; // Disable swipe when flipped
            if (details.primaryVelocity! > 200) {
              setState(() => _showBreakdown = true);
            } else if (details.primaryVelocity! < -200) {
              setState(() => _showBreakdown = false);
            }
          },
          child: AnimatedBuilder(
            animation: _flipController,
            builder: (context, child) {
              final isFront = _flipController.value < 0.5;
              final transform = Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(_flipController.value * pi);

              return Transform(
                transform: transform,
                alignment: Alignment.center,
                child: Container(
                  height: 235,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withAlpha(77),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: AnimatedSwitcher(
                      duration: 600.ms,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: _showBreakdown
                          ? _buildBreakdownView(context)
                          : (isFront
                              ? _buildMainView(context)
                              : Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()..rotateY(pi),
                                  child: _buildAnalysisView(context),
                                )),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMainView(BuildContext context) {
    final transactionViewModel = Provider.of<fixed.TransactionViewModel>(context);
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');

    final double totalIncome = transactionViewModel.getTotalIncome();
    final double totalExpenses = transactionViewModel.getTotalExpenses().abs(); // Ensure positive value
    final double safeToSpendAmount = totalIncome - totalExpenses;
    final double totalBalanceAmount = totalIncome;

    final double amountToShow = _showTotalBalance ? totalBalanceAmount : safeToSpendAmount;
    final String titleText = _showTotalBalance ? 'Total Balance' : 'Safe-to-spend';

    // Remove the loading check here since FutureBuilder handles it

    return Column(
      key: const ValueKey('main'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AnimatedSwitcher(
              duration: 300.ms,
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: Text(
                titleText,
                key: ValueKey<String>(titleText),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ScaleTransition(
                scale: Tween<double>(begin: 1.0, end: 1.2).animate(
                  CurvedAnimation(parent: _pulseController, curve: Curves.elasticOut),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Animate(
          key: ValueKey(amountToShow),
        )
            .custom(
              duration: 1000.ms,
              builder: (context, value, child) => Text(
                currencyFormat.format(amountToShow * value),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
            .fadeIn(duration: 300.ms),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(51),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.trending_up, color: Colors.lightGreenAccent, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    _getTimeAgo(_lastUpdated),
                    style: const TextStyle(
                      color: Colors.lightGreenAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Spacer(),
        const Text(
          'Long-press to flip',
          style: TextStyle(color: Colors.white54, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildBreakdownView(BuildContext context) {
    final transactionViewModel = Provider.of<fixed.TransactionViewModel>(context);
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');

    final totalIncome = transactionViewModel.getTotalIncome();
    final totalExpenses = transactionViewModel.getTotalExpenses();
    final safeToSpend = totalIncome - totalExpenses;

    return Column(
      key: const ValueKey('breakdown'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Safe-to-Spend Breakdown',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        _buildBreakdownRow('Total Income', totalIncome, currencyFormat, Colors.greenAccent),
        _buildBreakdownRow('Total Expenses', -totalExpenses, currencyFormat, Colors.orangeAccent),
        const Divider(color: Colors.white24, thickness: 1, height: 24),
        _buildBreakdownRow('Safe to Spend', safeToSpend, currencyFormat, Colors.white, isTotal: true),
        const Spacer(),
        const Align(
          alignment: Alignment.bottomRight,
          child: Text(
            'Tap to close',
            style: TextStyle(color: Colors.white54, fontSize: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisView(BuildContext context) {
    final transactionViewModel = Provider.of<fixed.TransactionViewModel>(context);
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');

    final totalIncome = transactionViewModel.getTotalIncome();
    final totalExpenses = transactionViewModel.getTotalExpenses();
    final safeToSpend = totalIncome - totalExpenses;

    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysRemaining = daysInMonth - now.day + 1;

    final dailySafeSpend = daysRemaining > 0 ? safeToSpend / daysRemaining : 0.0;
    final weeklyBudget = dailySafeSpend * 7.0;

    return Column(
      key: const ValueKey('analysis'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Spending Analysis',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Icon(Icons.bar_chart, color: Colors.white70),
          ],
        ),
        const SizedBox(height: 16),
        _buildAnalysisRow('Daily Safe Spend', dailySafeSpend, currencyFormat),
        _buildAnalysisRow('Weekly Budget', weeklyBudget, currencyFormat),
        _buildAnalysisRow('Days Remaining', daysRemaining.toDouble(), null, unit: 'days'),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.yellowAccent, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tip: Set spending alerts at 80% of your budget',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'Updating...';
    final difference = DateTime.now().difference(dateTime);
    if (difference.inSeconds < 5) return 'Updated just now';
    if (difference.inMinutes < 1) return 'Updated ${difference.inSeconds}s ago';
    if (difference.inHours < 1) return 'Updated ${difference.inMinutes}m ago';
    if (difference.inDays < 1) return 'Updated ${difference.inHours}h ago';
    return 'Updated ${difference.inDays}d ago';
  }

  Widget _buildBreakdownRow(
      String title, double amount, NumberFormat format, Color color, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withAlpha(230),
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            format.format(amount),
            style: TextStyle(
              color: color,
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisRow(String title, double value, NumberFormat? format, {String unit = ''}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(color: Colors.white.withAlpha(230), fontSize: 14),
          ),
          Text(
            format != null ? format.format(value) : '${value.toInt()} $unit',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

}
