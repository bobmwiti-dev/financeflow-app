import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../services/data_migration_service.dart';
import '../../themes/app_theme.dart';
import '../../utils/enhanced_animations.dart';

/// Screen for migrating data from local SQLite to Firebase Firestore
class DataMigrationScreen extends StatefulWidget {
  const DataMigrationScreen({super.key});

  @override
  State<DataMigrationScreen> createState() => _DataMigrationScreenState();
}

class _DataMigrationScreenState extends State<DataMigrationScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _showConfirmation = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    // Reset migration progress when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DataMigrationService.instance.resetProgress();
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _startMigration() async {
    setState(() {
      _showConfirmation = false;
    });
    
    // Start animation
    _animationController.repeat();
    
    // Start migration
    final success = await DataMigrationService.instance.migrateData();
    
    // Stop animation
    _animationController.stop();
    
    if (success && mounted) {
      // Show success animation
      _animationController.forward(from: 0.0);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Data migration completed successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: DataMigrationService.instance,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Data Migration'),
          elevation: 0,
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Consumer<DataMigrationService>(
          builder: (context, migrationService, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  _buildHeader(),
                  
                  const SizedBox(height: 32),
                  
                  // Migration status
                  if (migrationService.isMigrating)
                    _buildMigrationStatus(migrationService)
                  else if (_showConfirmation)
                    _buildConfirmation()
                  else
                    _buildStartMigrationButton(),
                  
                  const SizedBox(height: 32),
                  
                  // Migration info
                  _buildMigrationInfo(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Migrate Your Data to the Cloud',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideX(begin: -20, end: 0, curve: Curves.easeOutQuad),
        
        const SizedBox(height: 16),
        
        Text(
          'Transfer your financial data from your device to secure cloud storage for access across all your devices.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[700],
          ),
        )
        .animate()
        .fadeIn(delay: 300.ms, duration: 600.ms),
      ],
    );
  }
  
  Widget _buildMigrationStatus(DataMigrationService migrationService) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                RotationTransition(
                  turns: Tween(begin: 0.0, end: 1.0).animate(_animationController),
                  child: Icon(
                    Icons.sync,
                    size: 32,
                    color: AppTheme.accentColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    migrationService.currentTask,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Progress bar
            LinearProgressIndicator(
              value: migrationService.progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            
            const SizedBox(height: 16),
            
            // Progress percentage
            Text(
              '${(migrationService.progress * 100).toInt()}% Complete',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
              ),
            ),
            
            // Error message if any
            if (migrationService.error != null) ...[  
              const SizedBox(height: 16),
              Text(
                migrationService.error!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.red,
                ),
              ),
            ],
          ],
        ),
      ),
    )
    .animate()
    .fadeIn(duration: 500.ms)
    .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }
  
  Widget _buildConfirmation() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'This will migrate all your financial data to the cloud. Your existing data will remain on your device.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            
            const SizedBox(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showConfirmation = false;
                    });
                  },
                  child: const Text('Cancel'),
                ),
                
                const SizedBox(width: 16),
                
                ElevatedButton(
                  onPressed: _startMigration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ],
        ),
      ),
    )
    .animate()
    .fadeIn(duration: 400.ms)
    .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }
  
  Widget _buildStartMigrationButton() {
    return EnhancedAnimations.modernHoverEffect(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _showConfirmation = true;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text(
          'Start Migration',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    )
    .animate()
    .fadeIn(delay: 600.ms, duration: 600.ms)
    .moveY(begin: 20, end: 0);
  }
  
  Widget _buildMigrationInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What will be migrated?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            
            const SizedBox(height: 16),
            
            _buildInfoItem(
              icon: Icons.receipt_long,
              title: 'Transactions',
              description: 'All your financial transactions',
            ),
            
            _buildInfoItem(
              icon: Icons.account_balance_wallet,
              title: 'Budgets',
              description: 'Your budget categories and allocations',
            ),
            
            _buildInfoItem(
              icon: Icons.flag,
              title: 'Goals',
              description: 'Your financial goals and progress',
            ),
            
            _buildInfoItem(
              icon: Icons.attach_money,
              title: 'Income Sources',
              description: 'Your income sources and details',
            ),
            
            _buildInfoItem(
              icon: Icons.credit_card,
              title: 'Loans',
              description: 'Your loans and payment schedules',
              isLast: true,
            ),
          ],
        ),
      ),
    )
    .animate()
    .fadeIn(delay: 800.ms, duration: 600.ms);
  }
  
  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String description,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 24,
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
