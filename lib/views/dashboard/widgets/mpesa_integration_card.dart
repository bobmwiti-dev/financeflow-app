import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MPesaIntegrationCard extends StatelessWidget {
  const MPesaIntegrationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'KES ', decimalDigits: 0);
    
    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0xFF00A651), Color(0xFF00D4AA)], // M-Pesa green gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.phone_android,
                        color: Colors.white,
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'M-Pesa Integration',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'BETA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // M-Pesa Balance Section
              _buildMPesaBalance(currencyFormat),
              
              const SizedBox(height: 12),
              
              // Recent M-Pesa Transactions
              _buildRecentTransactions(currencyFormat),
              
              const SizedBox(height: 16),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.sync,
                      label: 'Sync SMS',
                      onTap: () => _syncMPesaSMS(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.settings,
                      label: 'Setup',
                      onTap: () => _showSetupDialog(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMPesaBalance(NumberFormat currencyFormat) {
    // Mock data - in real implementation, this would come from SMS parsing
    const balance = 12450.0;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'M-Pesa Balance',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 16,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Last synced 2 mins ago',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Text(
            currencyFormat.format(balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecentTransactions(NumberFormat currencyFormat) {
    // Mock M-Pesa transactions - in real implementation, parsed from SMS
    final transactions = [
      {'type': 'sent', 'amount': 500.0, 'recipient': 'John Doe', 'time': '10:30 AM'},
      {'type': 'received', 'amount': 2000.0, 'sender': 'Salary', 'time': '9:15 AM'},
      {'type': 'paybill', 'amount': 1200.0, 'merchant': 'KPLC', 'time': 'Yesterday'},
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent M-Pesa Activity',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...transactions.map((tx) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Icon(
                _getTransactionIcon(tx['type'] as String),
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getTransactionDescription(tx),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                '${tx['type'] == 'received' ? '+' : '-'}${currencyFormat.format(tx['amount'])}',
                style: TextStyle(
                  color: tx['type'] == 'received' ? Colors.white : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  IconData _getTransactionIcon(String type) {
    switch (type) {
      case 'sent':
        return Icons.arrow_upward;
      case 'received':
        return Icons.arrow_downward;
      case 'paybill':
        return Icons.receipt;
      case 'buygoods':
        return Icons.shopping_cart;
      default:
        return Icons.swap_horiz;
    }
  }
  
  String _getTransactionDescription(Map<String, dynamic> tx) {
    final type = tx['type'] as String;
    final time = tx['time'] as String;
    
    switch (type) {
      case 'sent':
        return 'Sent to ${tx['recipient']} • $time';
      case 'received':
        return 'Received from ${tx['sender']} • $time';
      case 'paybill':
        return 'Paid ${tx['merchant']} • $time';
      case 'buygoods':
        return 'Bought from ${tx['merchant']} • $time';
      default:
        return 'M-Pesa transaction • $time';
    }
  }
  
  void _syncMPesaSMS(BuildContext context) {
    // Show sync progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00A651)),
            ),
            const SizedBox(height: 16),
            const Text('Syncing M-Pesa SMS messages...'),
            const SizedBox(height: 8),
            Text(
              'This may take a few moments',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
    
    // Simulate sync process
    Future.delayed(const Duration(seconds: 3), () {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('M-Pesa transactions synced successfully!'),
            backgroundColor: Color(0xFF00A651),
          ),
        );
      }
    });
  }
  
  void _showSetupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.phone_android, color: Color(0xFF00A651)),
            SizedBox(width: 8),
            Text('M-Pesa Setup'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To enable M-Pesa integration:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text('1. Grant SMS permissions'),
            Text('2. Allow automatic SMS parsing'),
            Text('3. Verify your M-Pesa number'),
            SizedBox(height: 12),
            Text(
              'Your SMS data stays secure and private on your device.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to M-Pesa setup screen (placeholder for future implementation)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('M-Pesa setup coming soon!'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A651),
              foregroundColor: Colors.white,
            ),
            child: const Text('Setup Now'),
          ),
        ],
      ),
    );
  }
}
