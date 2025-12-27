import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:logging/logging.dart';

import 'realtime_data_service.dart';
import 'auth_service.dart';
import 'transaction_service.dart';
import 'sms_parser_service.dart';
import 'sms_import_service.dart';
import 'package:financeflow_app/viewmodels/transaction_viewmodel_fixed.dart';

import '../viewmodels/emergency_fund_viewmodel.dart';
import '../services/emergency_fund_service.dart';

import 'package:financeflow_app/viewmodels/bill_viewmodel.dart';
import 'package:financeflow_app/viewmodels/insights_viewmodel.dart';
import 'package:financeflow_app/viewmodels/debt_goals_viewmodel.dart';
import 'package:financeflow_app/viewmodels/budget_viewmodel.dart';
import 'package:financeflow_app/viewmodels/goal_viewmodel.dart';
import 'package:financeflow_app/viewmodels/family_viewmodel.dart';
import 'package:financeflow_app/viewmodels/income_viewmodel.dart';
import 'package:financeflow_app/viewmodels/loan_viewmodel.dart';
import 'package:financeflow_app/viewmodels/challenge_view_model.dart';
import 'package:financeflow_app/services/database_service.dart';
import 'package:financeflow_app/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A dedicated provider for application services that properly handles lifecycle
class ServiceProvider {
  static final _logger = Logger('ServiceProvider');
  
  /// Create all application service providers
  static List<SingleChildWidget> createProviders({TransactionViewModel? transactionViewModel}) {
    _logger.info('Creating application service providers');
    
    // Get service instances
    final authService = AuthService.instance;
    final transactionService = TransactionService.instance;
    
    // Create the realtime data service (fresh instance)
    final realtimeDataService = RealtimeDataService();
    
    // Initialize SMS services
    final smsParserService = SmsParserService();
    final smsImportService = SmsImportService(
      transactionService: transactionService,
      smsParserService: smsParserService,
    );
    
    final providers = <SingleChildWidget>[
      // Core services
      ChangeNotifierProvider.value(value: authService),
      // Create realtime data service with automatic disposal by the provider
      ChangeNotifierProvider<RealtimeDataService>(
        create: (_) {
          _logger.info('Creating RealtimeDataService through provider');
          return realtimeDataService;
        },
      ),
      
      // SMS services
      Provider.value(value: smsParserService),
      ChangeNotifierProvider.value(value: smsImportService),
      
      // View models (excluding TransactionViewModel if provided)
      if (transactionViewModel == null)
        ChangeNotifierProvider(create: (_) => TransactionViewModel()),
      
      // Other view models
      ChangeNotifierProvider(create: (_) => BudgetViewModel()),
      ChangeNotifierProvider(create: (_) => GoalViewModel()),
      ChangeNotifierProvider(create: (_) => DebtGoalsViewModel()),
      ChangeNotifierProvider(create: (_) => FamilyViewModel()),
      ChangeNotifierProvider(
        create: (_) => IncomeViewModel(
          databaseService: DatabaseService.instance,
          firestoreService: FirestoreService.instance,
          realtimeDataService: realtimeDataService,
          auth: FirebaseAuth.instance,
        ),
      ),
      ChangeNotifierProvider(create: (_) => LoanViewModel()),
      ChangeNotifierProvider(create: (_) => BillViewModel()),
      ChangeNotifierProvider(create: (_) => InsightsViewModel()),
      ChangeNotifierProvider(create: (_) => ChallengeViewModel()),

      // Emergency Fund view model
      ChangeNotifierProvider(
        create: (_) => EmergencyFundViewModel(
          emergencyFundService: EmergencyFundService.instance,
        ),
      ),

    ];
    
    return providers;
  }
}
