import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

import '../../viewmodels/family_viewmodel.dart';
import '../../models/family_member_model.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../../services/navigation_service.dart';
import '../../themes/app_theme.dart';
import 'widgets/family_member_card.dart';
import 'widgets/add_family_member_dialog.dart';
import 'allowance_requests_screen.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> with TickerProviderStateMixin {
  int _selectedIndex = 4; // Family index in the drawer
  final Logger logger = Logger('FamilyScreen');
  late AnimationController _headerAnimationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _headerAnimation;
  
  @override
  void initState() {
    super.initState();
    _headerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _cardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _headerAnimation = CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutCubic,
    );
    
    _headerAnimationController.forward();
    _cardAnimationController.forward();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize family view model after first frame is drawn
      if (mounted) {
        final familyViewModel = Provider.of<FamilyViewModel>(context, listen: false);
        familyViewModel.startListening();
      }
    });
  }

  void _onItemSelected(int index) {
    setState(() => _selectedIndex = index);

    final String route = NavigationService.routeForDrawerIndex(index);

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    if (ModalRoute.of(context)?.settings.name != route) {
      NavigationService.navigateToReplacement(route);
    }
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Consumer<FamilyViewModel>(
        builder: (context, viewModel, _) {
          return CustomScrollView(
            slivers: [
              _buildEnhancedAppBar(viewModel),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      if (viewModel.isLoading && !viewModel.hasFamilyMembers)
                        _buildLoadingState()
                      else if (viewModel.hasError)
                        _buildErrorState(viewModel)
                      else if (!viewModel.hasFamilyMembers)
                        _buildEnhancedEmptyState()
                      else ...[
                        _buildEnhancedFamilySummary(context, viewModel),
                        const SizedBox(height: 24),
                        _buildQuickActionsCard(viewModel),
                        const SizedBox(height: 24),
                        _buildBudgetSharingCard(viewModel),
                        const SizedBox(height: 24),
                        _buildEnhancedFamilyMemberList(context, viewModel),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      drawer: AppNavigationDrawer(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemSelected,
      ),
      floatingActionButton: Consumer<FamilyViewModel>(
        builder: (context, viewModel, _) {
          if (!viewModel.hasFamilyMembers) return const SizedBox.shrink();
          
          return FloatingActionButton.extended(
            onPressed: () {
              logger.info('Add family member button pressed');
              _showAddFamilyMemberDialog(context);
            },
            backgroundColor: AppTheme.primaryColor,
            icon: const Icon(Icons.person_add, color: Colors.white),
            label: const Text(
              'Add Member',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ).animate()
            .scale(delay: 800.ms, duration: 400.ms, curve: Curves.elasticOut)
            .fadeIn(delay: 800.ms, duration: 400.ms);
        },
      ),
    );
  }

  Widget _buildEnhancedAppBar(FamilyViewModel viewModel) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppTheme.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        title: AnimatedBuilder(
          animation: _headerAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.8 + (_headerAnimation.value * 0.2),
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.white, Colors.white70],
                ).createShader(bounds),
                child: const Text(
                  'Family Budget',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            );
          },
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withValues(alpha: 0.8),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () {
            logger.info('Manual refresh triggered');
            viewModel.startListening();
          },
        ),
        IconButton(
          icon: const Icon(Icons.request_quote, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AllowanceRequestsScreen(
                  primaryUserId: viewModel.primaryUserId ?? '',
                  memberId: viewModel.primaryUserId ?? '',
                  memberName: 'Family Requests',
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading family data...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(duration: 400.ms)
      .slideY(begin: 0.3, duration: 400.ms);
  }

  Widget _buildErrorState(FamilyViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              color: Colors.red[400],
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Error loading family data',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            viewModel.error ?? 'Unknown error occurred',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              logger.info('Retrying family data load');
              viewModel.startListening();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 400.ms)
      .slideY(begin: 0.3, duration: 400.ms);
  }

  Widget _buildEnhancedEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.1),
                    AppTheme.primaryColor.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.family_restroom,
                size: 60,
                color: AppTheme.primaryColor.withValues(alpha: 0.6),
              ),
            ).animate()
              .scale(duration: 600.ms, curve: Curves.elasticOut)
              .fadeIn(duration: 400.ms),
            const SizedBox(height: 24),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.7)],
              ).createShader(bounds),
              child: const Text(
                'Start Your Family Budget',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ).animate()
              .fadeIn(delay: 200.ms, duration: 600.ms)
              .slideY(begin: 0.3, duration: 600.ms),
            const SizedBox(height: 12),
            Text(
              'Add family members to track budgets,\nmanage allowances, and build healthy\nfinancial habits together!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ).animate()
              .fadeIn(delay: 400.ms, duration: 600.ms)
              .slideY(begin: 0.3, duration: 600.ms),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _showAddFamilyMemberDialog(context),
                icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
                label: const Text(
                  'Add First Member',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ).animate()
              .fadeIn(delay: 600.ms, duration: 600.ms)
              .slideY(begin: 0.3, duration: 600.ms)
              .shimmer(delay: 1200.ms, duration: 2000.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedFamilySummary(BuildContext context, FamilyViewModel viewModel) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    final totalBudget = viewModel.getTotalFamilyBudget();
    final totalSpent = viewModel.getTotalFamilySpent();
    final remaining = viewModel.getRemainingFamilyBudget();
    final percentUsed = totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0;
    final isOverBudget = remaining < 0;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Family Budget Overview',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${viewModel.familyMembers.length} members',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildSummaryMetric(
                  'Total Budget',
                  currencyFormat.format(totalBudget),
                  Icons.savings,
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryMetric(
                  'Total Spent',
                  currencyFormat.format(totalSpent),
                  Icons.shopping_cart,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryMetric(
            'Remaining',
            currencyFormat.format(remaining),
            isOverBudget ? Icons.warning : Icons.trending_up,
            isOverBudget ? AppTheme.errorColor : AppTheme.successColor,
            isFullWidth: true,
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Budget Usage',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${percentUsed.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getProgressColor(percentUsed.toDouble()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(percentUsed.toDouble())),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 600.ms)
      .slideY(begin: 0.3, duration: 600.ms);
  }

  Widget _buildSummaryMetric(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: isFullWidth
          ? Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildQuickActionsCard(FamilyViewModel viewModel) {
    return Container(
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  'Add Member',
                  Icons.person_add,
                  AppTheme.primaryColor,
                  () => _showAddFamilyMemberDialog(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  'View Requests',
                  Icons.request_quote,
                  Colors.indigo,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AllowanceRequestsScreen(
                          primaryUserId: viewModel.primaryUserId ?? '',
                          memberId: viewModel.primaryUserId ?? '',
                          memberName: 'Family Requests',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate()
      .fadeIn(delay: 200.ms, duration: 600.ms)
      .slideY(begin: 0.3, duration: 600.ms);
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: color,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedFamilyMemberList(BuildContext context, FamilyViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Family Members',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${viewModel.familyMembers.length} members',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: viewModel.familyMembers.length,
          itemBuilder: (context, index) {
            final member = viewModel.familyMembers[index];
            return FamilyMemberCard(
              name: member.name,
              budget: member.budget,
              spent: member.spent,
              avatarPath: member.avatarPath,
              onTap: () {
                logger.info('Family member ${member.name} tapped');
              },
              onAddExpense: () {
                logger.info('Add expense for ${member.name}');
                _showAddExpenseDialog(context, member.name);
              },
              onViewRequests: () {
                logger.info('View requests for ${member.name}');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AllowanceRequestsScreen(
                      primaryUserId: viewModel.primaryUserId ?? '',
                      memberId: member.id ?? '',
                      memberName: member.name,
                    ),
                  ),
                );
              },
            ).animate()
              .fadeIn(delay: (300 + (index * 100)).ms, duration: 600.ms)
              .slideX(begin: 0.3, duration: 600.ms);
          },
        ),
      ],
    );
  }

  Widget _buildBudgetSharingCard(FamilyViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.indigo.withValues(alpha: 0.1),
            Colors.purple.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.indigo.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo, Colors.indigo.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.share,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Budget Collaboration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Share insights and manage together',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildCollaborationFeature(
                  'Family Goals',
                  'Set shared financial targets',
                  Icons.flag,
                  Colors.green,
                  () => _showFamilyGoalsDialog(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCollaborationFeature(
                  'Spending Insights',
                  'View family spending patterns',
                  Icons.analytics,
                  Colors.blue,
                  () => _showSpendingInsights(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCollaborationFeature(
                  'Budget Alerts',
                  'Get notified of overspending',
                  Icons.notifications_active,
                  Colors.orange,
                  () => _showBudgetAlertsDialog(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCollaborationFeature(
                  'Family Chat',
                  'Discuss financial decisions',
                  Icons.chat_bubble,
                  Colors.purple,
                  () => _showFamilyChatDialog(),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate()
      .fadeIn(delay: 400.ms, duration: 600.ms)
      .slideY(begin: 0.3, duration: 600.ms);
  }

  Widget _buildCollaborationFeature(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: color,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage < 50) {
      return AppTheme.successColor;
    } else if (percentage < 80) {
      return AppTheme.warningColor;
    } else {
      return AppTheme.errorColor;
    }
  }

  // Collaboration feature methods
  void _showFamilyGoalsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Family Goals'),
        content: const Text('Set and track shared financial goals for your family. This feature helps everyone work towards common objectives like saving for vacations, education, or major purchases.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Coming Soon'),
          ),
        ],
      ),
    );
  }

  void _showSpendingInsights() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Spending Insights'),
        content: const Text('View detailed analytics of your family\'s spending patterns, trends, and recommendations for better budget management.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Coming Soon'),
          ),
        ],
      ),
    );
  }

  void _showBudgetAlertsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Budget Alerts'),
        content: const Text('Configure smart notifications to alert family members when approaching budget limits or when unusual spending patterns are detected.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Coming Soon'),
          ),
        ],
      ),
    );
  }

  void _showFamilyChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Family Chat'),
        content: const Text('Communicate with family members about financial decisions, share spending updates, and collaborate on budget planning in real-time.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Coming Soon'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddFamilyMemberDialog(BuildContext context) async {
    if (!context.mounted) return;
    
    final result = await showDialog<FamilyMember>(
      context: context,
      builder: (BuildContext dialogContext) {
        return const AddFamilyMemberDialog();
      },
    );
    
    if (result != null && context.mounted) {
      final viewModel = Provider.of<FamilyViewModel>(context, listen: false);
      
      final success = await viewModel.addFamilyMember(result);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.name} added successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add family member'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showAddExpenseDialog(BuildContext context, String memberName) async {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();

    if (!context.mounted) return;

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Add Expense for $memberName'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    hintText: 'Enter amount',
                    prefixText: '\$',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter description (optional)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text) ?? 0.0;

                if (amount > 0) {
                  if (!context.mounted) return;
                  final viewModel = Provider.of<FamilyViewModel>(context, listen: false);

                  final member = viewModel.familyMembers.firstWhere(
                    (m) => m.name == memberName,
                    orElse: () => throw Exception('Member not found'),
                  );

                  final success = await viewModel.updateFamilyMemberSpending(
                    member.id ?? '',
                    member.spent + amount,
                  );

                  if (success && context.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                }
              },
              child: const Text('Add Expense'),
            ),
          ],
        );
      },
    );
  }
}


