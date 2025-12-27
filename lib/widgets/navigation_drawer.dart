import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../constants/app_constants.dart';
import '../themes/app_theme.dart';
import '../services/navigation_service.dart';

class AppNavigationDrawer extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const AppNavigationDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
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
                      'Budget Tracker',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Text(
                  'Manage your finances with ease',
                  style: TextStyle(
                    color: Colors.white70,
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
            icon: FontAwesomeIcons.chartLine,
            route: AppConstants.dashboardRoute,
          ),
          _buildNavItem(
            context,
            index: 1,
            title: 'Expenses',
            icon: FontAwesomeIcons.moneyBill,
            route: AppConstants.expensesRoute,
          ),
          _buildNavItem(
            context,
            index: 2,
            title: 'Budgets',
            icon: FontAwesomeIcons.wallet,
            route: '/budgets',
          ),
          _buildNavItem(
            context,
            index: 3,
            title: 'Goals',
            icon: FontAwesomeIcons.bullseye,
            route: AppConstants.goalsRoute,
          ),
          _buildNavItem(
            context,
            index: 4,
            title: 'Reports',
            icon: FontAwesomeIcons.chartPie,
            route: AppConstants.reportsRoute,
          ),
          _buildNavItem(
            context,
            index: 5,
            title: 'Family',
            icon: FontAwesomeIcons.users,
            route: AppConstants.familyRoute,
          ),
          const Divider(),
          _buildNavItem(
            context,
            index: 6,
            title: 'Settings',
            icon: FontAwesomeIcons.gear,
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
  }) {
    final isSelected = selectedIndex == index;
    
    return ListTile(
      leading: FaIcon(
        icon,
        color: isSelected ? AppTheme.primaryColor : null,
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppTheme.primaryColor : null,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onTap: () {
        onItemSelected(index);
        Navigator.pop(context); // Close the drawer
        if (route != Navigator.of(context).widget.initialRoute) {
          NavigationService.navigateTo(route);
        }
      },
    );
  }
}
