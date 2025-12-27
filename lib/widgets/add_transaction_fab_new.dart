import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../themes/app_theme.dart';
import '../views/transactions/transaction_form_screen.dart';

class AddTransactionFAB extends StatefulWidget {
  final Function? onTransactionAdded;

  const AddTransactionFAB({
    super.key,
    this.onTransactionAdded,
  });

  @override
  State<AddTransactionFAB> createState() => _AddTransactionFABState();
}

class _AddTransactionFABState extends State<AddTransactionFAB> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final Tween<double> _rotationTween = Tween(begin: 0, end: 0.125);
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationTween.evaluate(_animationController) * 2 * 3.14159,
          child: FloatingActionButton(
            onPressed: () {
              if (_animationController.status == AnimationStatus.completed) {
                _animationController.reverse();
              } else {
                _animationController.forward();
              }
              _showAddTransactionOptions(context);
            },
            backgroundColor: AppTheme.accentColor,
            elevation: 4,
            child: AnimatedIcon(
              icon: AnimatedIcons.add_event,
              progress: _animationController,
              color: Colors.white,
            ),
          ),
        )
        .animate()
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          curve: Curves.elasticOut,
          duration: const Duration(milliseconds: 600),
        )
        .then(delay: const Duration(milliseconds: 200))
        .shimmer(
          duration: const Duration(milliseconds: 1800),
          color: Colors.white.withValues(alpha: 0.6),
        );
      },
    );
  }

  void _showAddTransactionOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) {
        if (!mounted) return Container();
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Handle bar at the top
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ).animate()
                .fadeIn(duration: const Duration(milliseconds: 300))
                .slideY(begin: 0.1, end: 0),
                
              // Title row
              Row(
                children: [
                  const Text(
                    'Add Transaction',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      foregroundColor: Colors.grey.shade700,
                    ),
                  ),
                ],
              ).animate()
                .fadeIn(duration: const Duration(milliseconds: 300))
                .slideY(begin: 0.1, end: 0),
                
              const SizedBox(height: 16),
              
              // Expense option
              _buildTransactionOption(
                context: context,
                title: 'Add Expense',
                subtitle: 'Record money going out',
                iconData: Icons.remove_circle_outline,
                color: AppTheme.expenseColor,
                onTap: () => _handleTransactionTap(context, isExpense: true),
              ).animate()
                .fadeIn(duration: const Duration(milliseconds: 300))
                .slideY(begin: 0.1, end: 0),
                
              const SizedBox(height: 8),
              
              // Income option
              _buildTransactionOption(
                context: context,
                title: 'Add Income',
                subtitle: 'Record money coming in',
                iconData: Icons.add_circle_outline,
                color: AppTheme.incomeColor,
                onTap: () => _handleTransactionTap(context, isExpense: false),
              ).animate()
                .fadeIn(duration: const Duration(milliseconds: 350))
                .slideY(begin: 0.1, end: 0),
                
              const SizedBox(height: 8),
              
              // Transfer option
              _buildTransactionOption(
                context: context,
                title: 'Transfer',
                subtitle: 'Move money between accounts',
                iconData: Icons.swap_horiz,
                color: Colors.blue,
                onTap: () => _handleTransferTap(context),
              ).animate()
                .fadeIn(duration: const Duration(milliseconds: 400))
                .slideY(begin: 0.1, end: 0),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildTransactionOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData iconData,
    required Color color,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade50,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              iconData,
              color: color,
              size: 28,
            ),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          tileColor: Colors.transparent,
          onTap: onTap,
        ),
      ),
    );
  }
  
  void _handleTransactionTap(BuildContext context, {required bool isExpense}) {
    // Use context directly - no async operations in this method
    Navigator.pop(context);
    _animationController.reverse();
    
    // Schedule the navigation after animation completes
    Future.delayed(const Duration(milliseconds: 300), () {
      _navigateToTransactionForm(isExpense);
    });
  }
  
  // Separate method for navigation that handles its own state
  Future<void> _navigateToTransactionForm(bool isExpense) async {
    // Check mounted state before proceeding
    if (!mounted) return;
    
    // Create the page route builder
    final pageRoute = PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => 
        TransactionFormScreen(isExpense: isExpense),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = const Offset(1.0, 0.0);
        var end = Offset.zero;
        var curve = Curves.easeInOut;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
    
    // Safe navigation pattern - no context captured across await
    if (!mounted) return;
    
    // Get current context but don't store it in a variable that crosses an await
    final result = await Navigator.of(context).push(pageRoute) as bool?;
    
    // Check mounted again after async operation
    if (!mounted) return;
    
    // Process the result
    if (result == true && widget.onTransactionAdded != null) {
      widget.onTransactionAdded!();
    }
  }
  
  void _handleTransferTap(BuildContext context) {
    Navigator.pop(context);
    _animationController.reverse();
    
    // Show a snackbar for now since transfer is not implemented
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Transfer feature coming soon!'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}
