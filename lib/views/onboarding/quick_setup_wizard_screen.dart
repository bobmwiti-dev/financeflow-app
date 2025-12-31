import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../themes/app_theme.dart';
import '../../services/sms_reader_service.dart';
import '../../services/sms_import_service.dart';
import '../../services/mpesa_import_service.dart';
import '../../viewmodels/income_viewmodel.dart';
import '../../viewmodels/goal_viewmodel.dart';
import '../../viewmodels/transaction_viewmodel_fixed.dart' as fixed;
import '../../viewmodels/account_viewmodel.dart';
import '../../models/income_source_model.dart';
import '../../models/goal_model.dart';

class QuickSetupWizardScreen extends StatefulWidget {
  const QuickSetupWizardScreen({super.key});

  @override
  State<QuickSetupWizardScreen> createState() => _QuickSetupWizardScreenState();
}

class _QuickSetupWizardScreenState extends State<QuickSetupWizardScreen> {
  int _stepIndex = 0;
  bool _isWorking = false;

  bool _smsPermissionGranted = false;

  final TextEditingController _monthlyIncomeController = TextEditingController();
  bool _goalEmergencyFund = true;
  bool _goalRent = false;

  @override
  void initState() {
    super.initState();
    _initPermissionStatus();
  }

  @override
  void dispose() {
    _monthlyIncomeController.dispose();
    super.dispose();
  }

  Future<void> _initPermissionStatus() async {
    final has = await SmsReaderService.hasPermission();
    if (!mounted) return;
    setState(() {
      _smsPermissionGranted = has;
    });
  }

  Future<void> _requestSmsPermission() async {
    setState(() {
      _isWorking = true;
    });

    try {
      final granted = await SmsReaderService.requestPermission();
      if (!mounted) return;

      final smsImportService = Provider.of<SmsImportService>(context, listen: false);
      await smsImportService.requestPermission();

      setState(() {
        _smsPermissionGranted = granted;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  Future<void> _saveIncomeAndGoals() async {
    final rawIncome = _monthlyIncomeController.text.trim().replaceAll(',', '');
    final parsed = double.tryParse(rawIncome);

    if (parsed == null || parsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid monthly income amount.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isWorking = true;
    });

    try {
      final incomeVm = Provider.of<IncomeViewModel>(context, listen: false);
      final goalVm = Provider.of<GoalViewModel>(context, listen: false);
      final accountVm = Provider.of<AccountViewModel>(context, listen: false);

      final accountId = accountVm.defaultAccountId ?? 'default_account';
      final now = DateTime.now();
      final monthDate = DateTime(now.year, now.month, 1);

      final incomeSource = IncomeSource(
        name: 'Monthly Income',
        type: 'Salary',
        amount: parsed,
        date: monthDate,
        accountId: accountId,
        isRecurring: true,
        frequency: 'Monthly',
      );
      await incomeVm.addIncomeSource(incomeSource);

      if (_goalEmergencyFund) {
        await goalVm.addGoal(
          Goal(
            name: 'Emergency Fund',
            targetAmount: parsed * 3,
            category: 'Emergency Fund',
            targetDate: DateTime(now.year, now.month, now.day).add(const Duration(days: 365)),
          ),
        );
      }

      if (_goalRent) {
        await goalVm.addGoal(
          Goal(
            name: 'Rent',
            targetAmount: parsed,
            category: 'Housing',
            targetDate: DateTime(now.year, now.month, now.day).add(const Duration(days: 60)),
          ),
        );
      }

      if (!mounted) return;
      _next();
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  Future<void> _runFirstImportAndShowSnapshot() async {
    if (!_smsPermissionGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please grant SMS permission to import transactions.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isWorking = true;
    });

    try {
      final smsImportService = Provider.of<SmsImportService>(context, listen: false);
      final txVm = Provider.of<fixed.TransactionViewModel>(context, listen: false);
      final incomeVm = Provider.of<IncomeViewModel>(context, listen: false);

      await MpesaImportService.importTransactions(
        since: DateTime.now().subtract(const Duration(days: 30)),
        maxDays: 30,
        categorizeAutomatically: true,
        skipDuplicates: true,
      );

      await smsImportService.importTransactions(ensurePermission: false);

      await txVm.loadAllTransactions();
      await incomeVm.loadIncomeSources();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('quick_setup_completed', true);
      await prefs.setBool('first_30_snapshot_shown', false);

      if (!mounted) return;

      Navigator.of(context).pushReplacementNamed(
        '/first_30_days_snapshot',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  void _next() {
    setState(() {
      _stepIndex = (_stepIndex + 1).clamp(0, 2);
    });
  }

  void _back() {
    setState(() {
      _stepIndex = (_stepIndex - 1).clamp(0, 2);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Setup'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Stepper(
        currentStep: _stepIndex,
        controlsBuilder: (context, details) {
          final isLast = _stepIndex == 2;
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                if (_stepIndex > 0)
                  TextButton(
                    onPressed: _isWorking ? null : _back,
                    child: const Text('Back'),
                  ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _isWorking
                      ? null
                      : () async {
                          if (_stepIndex == 0) {
                            if (!_smsPermissionGranted) {
                              await _requestSmsPermission();
                            }
                            if (_smsPermissionGranted) {
                              _next();
                            }
                            return;
                          }
                          if (_stepIndex == 1) {
                            await _saveIncomeAndGoals();
                            return;
                          }
                          if (isLast) {
                            await _runFirstImportAndShowSnapshot();
                          }
                        },
                  child: _isWorking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isLast ? 'Import & Continue' : 'Continue'),
                ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('SMS Permission (Private & Local)'),
            isActive: _stepIndex >= 0,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'We only read SMS locally on your phone to compute your spending. We never send SMS contents to any server.',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      _smsPermissionGranted ? Icons.check_circle : Icons.lock,
                      color: _smsPermissionGranted ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _smsPermissionGranted ? 'Permission granted' : 'Permission not granted',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _smsPermissionGranted ? Colors.green : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Kenya context: This helps us auto-import M-Pesa and bank SMS (KCB, Equity, etc.) and instantly show your monthly picture.',
                ),
              ],
            ),
          ),
          Step(
            title: const Text('Set monthly income & goals'),
            isActive: _stepIndex >= 1,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _monthlyIncomeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Monthly income (KES)',
                    hintText: 'e.g. 80000',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _goalEmergencyFund,
                  onChanged: _isWorking
                      ? null
                      : (v) {
                          setState(() {
                            _goalEmergencyFund = v;
                          });
                        },
                  title: const Text('Emergency Fund'),
                  subtitle: const Text('Recommended for Kenya month-to-month stability'),
                ),
                SwitchListTile(
                  value: _goalRent,
                  onChanged: _isWorking
                      ? null
                      : (v) {
                          setState(() {
                            _goalRent = v;
                          });
                        },
                  title: const Text('Rent'),
                  subtitle: const Text('Set a short-term goal for upcoming rent'),
                ),
              ],
            ),
          ),
          Step(
            title: const Text('Instant insights'),
            isActive: _stepIndex >= 2,
            content: const Text(
              'We’ll import your last 30 days, then show a First 30 Days Snapshot with your inflow/outflow, top categories, M-Pesa fees, and a simple “saved vs overspent” message.',
            ),
          ),
        ],
      ),
    );
  }
}
