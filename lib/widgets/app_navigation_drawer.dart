import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:icons_plus/icons_plus.dart';
import '../constants/app_constants.dart';
import '../themes/app_theme.dart';
import '../viewmodels/insights_viewmodel.dart';

class AppNavigationDrawer extends StatelessWidget {
  final int selectedIndex;
  final Function(int)? onItemSelected;

  const AppNavigationDrawer({
    super.key,
    required this.selectedIndex,
    this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: 40,
                      height: 40,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.account_balance_wallet,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      AppConstants.appName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Smart Financial Management',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _buildNavItem(
            context,
            index: 0,
            title: 'Dashboard',
            icon: Bootstrap.speedometer2,
            route: AppConstants.dashboardRoute,
          ),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 8, bottom: 4),
            child: Text(
              'MONEY MANAGEMENT',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildNavItem(
            context,
            index: 1,
            title: 'Expenses',
            icon: Bootstrap.credit_card,
            route: AppConstants.expensesRoute,
          ),
          _buildNavItem(
            context,
            index: 6,
            title: 'Income',
            icon: Bootstrap.cash_stack,
            route: AppConstants.incomeRoute,
          ),
          _buildNavItem(
            context,
            index: 7,
            title: 'Budgets',
            icon: Bootstrap.piggy_bank,
            route: AppConstants.budgetsRoute,
          ),
          _buildNavItem(
            context,
            index: 8,
            title: 'Loans',
            icon: Bootstrap.bank,
            route: AppConstants.loansRoute,
          ),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 8, bottom: 4),
            child: Text(
              'INSIGHTS & ANALYTICS',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildNavItem(
            context,
            index: 9,
            title: 'AI Insights',
            icon: Bootstrap.lightbulb,
            route: AppConstants.insightsRoute,
            badge: Provider.of<InsightsViewModel>(context).unreadCount,
          ),
          _buildNavItem(
            context,
            index: 3,
            title: 'Reports',
            icon: Bootstrap.graph_up,
            route: AppConstants.reportsRoute,
          ),
          _buildNavItem(
            context,
            index: 2,
            title: 'Goals',
            icon: Bootstrap.bullseye,
            route: '/enhanced-goals',
          ),
          _buildNavItem(
            context,
            index: 10,
            title: 'Spending Heatmap',
            icon: Bootstrap.calendar3,
            route: AppConstants.spendingHeatmapRoute,
          ),
          _buildNavItem(
            context,
            index: 11,
            title: 'Challenges',
            icon: Bootstrap.trophy,
            route: AppConstants.spendingChallengesRoute,
          ),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 8, bottom: 4),
            child: Text(
              'OTHER',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildNavItem(
            context,
            index: 4,
            title: 'Family',
            icon: Bootstrap.people,
            route: AppConstants.familyRoute,
          ),
          _buildNavItem(
            context,
            index: 12,
            title: 'Profile',
            icon: Bootstrap.person_circle,
            route: AppConstants.profileRoute,
          ),
          const Divider(height: 1),
          _buildNavItem(
            context,
            index: 5,
            title: 'Settings',
            icon: Bootstrap.gear,
            route: AppConstants.settingsRoute,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required String title,
    required IconData icon,
    required String route,
    int badge = 0,
  }) {
    final isSelected = selectedIndex == index;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppTheme.primaryColor : null,
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppTheme.primaryColor : null,
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
      trailing: badge > 0
          ? Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha:0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              constraints: const BoxConstraints(
                minWidth: 24,
                minHeight: 24,
              ),
              child: Text(
                badge.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            )
          : null,
      selected: isSelected,
      onTap: () {
        Navigator.of(context).pop(); // Close the drawer
        Navigator.of(context).pushNamed(route);
      },
    );
  }
}
