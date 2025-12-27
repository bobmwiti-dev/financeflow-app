class AppConstants {
  // App information
  static const String appName = 'Finance Flow';
  static const String appVersion = '1.0.0';
  static const String signInRoute = '/sign-in';
  
  // Navigation routes
  static const String dashboardRoute = '/dashboard';
  static const String expensesRoute = '/expenses';
  static const String goalsRoute = '/goals';
  static const String reportsRoute = '/reports';
  static const String familyRoute = '/family';
  static const String settingsRoute = '/settings';
  static const String incomeRoute = '/income';
  static const String loansRoute = '/loans';
  static const String insightsRoute = '/insights';
  static const String profileRoute = '/profile';
  static const String budgetsRoute = '/budgets';
  static const String spendingHeatmapRoute = '/spending-heatmap';
  static const String upcomingEventsRoute = '/upcoming_events';
  static const String spendingChallengesRoute = '/spending-challenges';
  static const String transactionDetailsRoute = '/transaction-details';
  // Quick action routes
  static const String addTransactionRoute = '/add_transaction';
  static const String addBillRoute = '/add_bill';
  static const String addGoalRoute = '/add_goal';
  static const String debtGoalDetailsRoute = '/debt_goal_detail';
  static const String addBudgetRoute = '/add_budget';
  static const String transferRoute = '/transfer';
  static const String scheduledPaymentsRoute = '/scheduled-payments';
  
  // Transaction categories
  static const List<String> expenseCategories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Entertainment',
    'Health',
    'Housing',
    'Other',
  ];
  
  static const List<String> incomeCategories = [
    'Salary',
    'Freelance',
    'Investments',
    'Gifts',
    'Other',
  ];
  
  // Income source types
  static const List<String> incomeSourceTypes = [
    'Salary',
    'Side Hustle',
    'Loan',
    'Grant',
    'Family Contribution',
    'Business',
    'Dividend',
    'Investment',
    'Gift',
    'Other',
  ];
  
  // Frequency options
  static const List<String> frequencyOptions = [
    'One-time',
    'Daily',
    'Weekly',
    'Bi-weekly',
    'Monthly',
    'Quarterly',
    'Annually',
  ];
  
  // Loan status options
  static const List<String> loanStatusOptions = [
    'Active',
    'Paid',
    'Defaulted',
  ];
  
  // Expense carry forward options
  static const List<String> carryForwardCategories = [
    'Bills',
    'Housing',
    'Health',
  ];
  
  static const List<String> resetCategories = [
    'Entertainment',
    'Food',
    'Transport',
  ];
  
  // Payment methods
  static const List<String> paymentMethods = [
    'Cash',
    'Credit Card',
    'Debit Card',
    'Bank Transfer',
    'Mobile Payment',
    'Other',
  ];
  
  // Goal categories
  static const List<String> goalCategories = [
    'Vacation',
    'Emergency Fund',
    'Electronics',
    'Vehicle',
    'Home',
    'Education',
    'Retirement',
    'Other',
  ];
  
  // Date formats
  static const String dateFormat = 'MMM dd, yyyy';
  static const String monthYearFormat = 'MMMM yyyy';
  
  // Chart settings
  static const int chartAnimationDuration = 500; // milliseconds
  
  // AI Insights
  static const List<String> insightTypes = [
    'Spending Pattern',
    'Budget Alert',
    'Saving Opportunity',
    'Financial Health',
    'Debt Management',
    'Income Optimization',
    'Goal Progress',
    'Expense Anomaly',
  ];
  
  static const Map<String, String> insightDescriptions = {
    'Spending Pattern': 'Analysis of your spending habits and trends',
    'Budget Alert': 'Notifications when you approach or exceed budget limits',
    'Saving Opportunity': 'Suggestions for potential savings based on your spending patterns',
    'Financial Health': 'Overall assessment of your financial situation',
    'Debt Management': 'Recommendations for managing and reducing debt',
    'Income Optimization': 'Ideas to optimize your income sources',
    'Goal Progress': 'Updates on your progress towards financial goals',
    'Expense Anomaly': 'Detection of unusual spending patterns',
  };
  
  static const Map<String, String> insightIcons = {
    'Spending Pattern': 'trending_up',
    'Budget Alert': 'warning',
    'Saving Opportunity': 'savings',
    'Financial Health': 'health_and_safety',
    'Debt Management': 'account_balance',
    'Income Optimization': 'attach_money',
    'Goal Progress': 'flag',
    'Expense Anomaly': 'priority_high',
  };
  
  // Financial health thresholds
  static const double goodSavingsRateThreshold = 0.20; // 20% of income
  static const double moderateSavingsRateThreshold = 0.10; // 10% of income
  static const double goodDebtToIncomeRatio = 0.36; // 36% or less
  static const double moderateDebtToIncomeRatio = 0.43; // 43% or less
  static const double goodEmergencyFundMonths = 6.0; // 6 months of expenses
  static const double moderateEmergencyFundMonths = 3.0; // 3 months of expenses
}
