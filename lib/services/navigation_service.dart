import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import 'package:financeflow_app/views/dashboard/dashboard_screen.dart';
import 'package:financeflow_app/views/expenses/expenses_screen.dart';
import 'package:financeflow_app/views/goals/goals_screen.dart';
import 'package:financeflow_app/views/reports/reports_screen.dart';
import 'package:financeflow_app/views/family/family_screen.dart';
import 'package:financeflow_app/views/settings/settings_screen.dart';
import 'package:financeflow_app/views/budgets/enhanced_budget_management_screen.dart';
import 'package:financeflow_app/views/income/income_screen.dart';
import 'package:financeflow_app/views/loans/loans_screen.dart';
import 'package:financeflow_app/views/insights/insights_screen.dart';
import 'package:financeflow_app/views/profile/profile_screen.dart';
import 'package:financeflow_app/views/upcoming_events/upcoming_events_screen.dart';
import 'package:financeflow_app/views/auth/sign_in_screen.dart';
import 'package:financeflow_app/views/challenges/spending_challenges_screen.dart';
import 'package:financeflow_app/views/add_transaction/add_transaction_screen.dart';
import 'package:financeflow_app/views/insights/spending_heatmap_screen.dart';
import 'package:financeflow_app/views/bills/add_bill_screen.dart';
import 'package:financeflow_app/views/notifications/notification_test_screen.dart';
import 'package:financeflow_app/widgets/currency_selector.dart';
import 'package:financeflow_app/views/budgets/add_budget_screen.dart';
import 'package:financeflow_app/views/goals/add_goal_screen.dart';
import 'package:financeflow_app/views/transfer/transfer_screen.dart';
import 'package:financeflow_app/views/mpesa/mpesa_import_screen.dart';
import 'package:financeflow_app/views/mpesa/mpesa_settings_screen.dart';
import 'package:financeflow_app/views/mpesa/mpesa_analytics_screen.dart';
import 'package:financeflow_app/views/transport/transport_intelligence_screen.dart';
import 'package:financeflow_app/views/onboarding/account_setup_screen.dart';
import 'package:financeflow_app/views/onboarding/splash_screen.dart';
import 'package:financeflow_app/views/onboarding/onboarding_screen.dart';
import 'package:financeflow_app/views/accounts/account_management_screen.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static NavigatorState? get navigator => navigatorKey.currentState;
  static Future<dynamic> navigateTo(String routeName, {Object? arguments}) async {
    if (navigatorKey.currentContext == null) {
      debugPrint('Navigator not ready yet');
      return null;
    }
    return await Navigator.of(navigatorKey.currentContext!).pushNamed(
      routeName,
      arguments: arguments,
    );
  }

  static Future<dynamic> navigateToReplacement(String routeName, {Object? arguments}) async {
    if (navigatorKey.currentContext == null) {
      debugPrint('Navigator not ready yet');
      return null;
    }
    return await Navigator.of(navigatorKey.currentContext!).pushReplacementNamed(
      routeName,
      arguments: arguments,
    );
  }

  static Future<dynamic> navigateToAndClearStack(String routeName, {Object? arguments}) async {
    if (navigatorKey.currentContext == null) {
      debugPrint('Navigator not ready yet');
      return null;
    }
    return await Navigator.of(navigatorKey.currentContext!).pushNamedAndRemoveUntil(
      routeName,
      (Route<dynamic> route) => false,
      arguments: arguments,
    );
  }
  static void goBack() {
    return navigator!.pop();
  }

  /// Map drawer index to route name
  static const String accountSetupRoute = '/account_setup';
  static const String accountManagementRoute = '/account_management';

  static String routeForDrawerIndex(int index) {
    switch (index) {
      case 0:
        return AppConstants.dashboardRoute;
      case 1:
        return AppConstants.expensesRoute;
      case 3:
        return AppConstants.reportsRoute;
      case 4:
        return AppConstants.familyRoute;
      case 5:
        return AppConstants.settingsRoute;
      case 6:
        return AppConstants.incomeRoute;
      case 7:
        return AppConstants.budgetsRoute;
      case 8:
        return AppConstants.loansRoute;
      case 9:
        return AppConstants.insightsRoute;
      case 10:
        return AppConstants.spendingHeatmapRoute;
      case 11:
        return AppConstants.spendingChallengesRoute;
      case 12:
        return AppConstants.profileRoute;
      default:
        return AppConstants.dashboardRoute;
    }
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppConstants.dashboardRoute:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case AppConstants.spendingChallengesRoute:
        return MaterialPageRoute(
          builder: (_) => const SpendingChallengesScreen(),
        );
      case AppConstants.expensesRoute:
        return MaterialPageRoute(builder: (_) => const ExpensesScreen());
      case AppConstants.incomeRoute:
        return MaterialPageRoute(builder: (_) => const IncomeScreen());
      case AppConstants.loansRoute:
        return MaterialPageRoute(builder: (_) => const LoansScreen());
      case AppConstants.budgetsRoute:
        return MaterialPageRoute(builder: (_) => const EnhancedBudgetManagementScreen());
      case AppConstants.goalsRoute:
        return MaterialPageRoute(builder: (_) => const GoalsScreen());
      case '/enhanced-goals':
        return MaterialPageRoute(builder: (_) => const GoalsScreen());
      case AppConstants.reportsRoute:
        return MaterialPageRoute(builder: (_) => const ReportsScreen());
      case AppConstants.familyRoute:
        return MaterialPageRoute(builder: (_) => const FamilyScreen());
      case AppConstants.settingsRoute:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case AppConstants.addBillRoute:
        return MaterialPageRoute(builder: (_) => const AddBillScreen());
      case AppConstants.addGoalRoute:
        return MaterialPageRoute(builder: (_) => const AddGoalScreen());
      case AppConstants.debtGoalDetailsRoute:
        return MaterialPageRoute(builder: (_) => const GoalsScreen());
      case AppConstants.addBudgetRoute:
        return MaterialPageRoute(builder: (_) => const AddBudgetScreen());
      case AppConstants.transferRoute:
        return MaterialPageRoute(builder: (_) => const TransferScreen());
      case AppConstants.insightsRoute:
        return MaterialPageRoute(builder: (_) => const InsightsScreen());
      case AppConstants.upcomingEventsRoute:
        return MaterialPageRoute(builder: (_) => const UpcomingEventsScreen());
      case AppConstants.spendingHeatmapRoute:
        return MaterialPageRoute(builder: (_) => const SpendingHeatmapScreen());
      case AppConstants.profileRoute:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case '/notifications':
      case '/notification_test':
        return MaterialPageRoute(builder: (_) => const NotificationTestScreen());
      case '/currency_settings':
        return MaterialPageRoute(builder: (_) => const CurrencyPreferencesScreen());
      case '/mpesa_import':
        return MaterialPageRoute(builder: (_) => const MpesaImportScreen());
      case '/mpesa_settings':
        return MaterialPageRoute(builder: (_) => const MpesaSettingsScreen());
      case '/mpesa_analytics':
        return MaterialPageRoute(builder: (_) => const MpesaAnalyticsScreen());
      case '/transport_intelligence':
        return MaterialPageRoute(builder: (_) => const TransportIntelligenceScreen());
      case '/account_setup':
        return MaterialPageRoute(builder: (_) => const AccountSetupScreen());
      case '/account_management':
        return MaterialPageRoute(builder: (_) => const AccountManagementScreen());
      case '/splash':
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case '/onboarding':
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case AppConstants.signInRoute:
        return MaterialPageRoute(builder: (_) => const SignInScreen());
      case '/add_transaction':
        return MaterialPageRoute(builder: (_) => const AddTransactionScreen());
      default:
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Not Found')),
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }

  static Widget getScreenByIndex(int index) {
    switch (index) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const ExpensesScreen();
      case 2:
        return const EnhancedBudgetManagementScreen();
      case 3:
        return const GoalsScreen();
      case 4:
        return const ReportsScreen();
      case 5:
        return const FamilyScreen();
      case 6:
        return const SettingsScreen();
      case 7:
        return const IncomeScreen();
      case 8:
        return const LoansScreen();
      case 9:
        return const InsightsScreen();
      case 10:
        return const SpendingHeatmapScreen();
      default:
        return const DashboardScreen();
    }
  }
}
