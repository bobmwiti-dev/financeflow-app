import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  bool get _isSmsImportSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android;
  }

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
    if (!_isSmsImportSupported) {
      if (!mounted) return;
      setState(() {
        _smsPermissionGranted = false;
      });
      return;
    }
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
      if (!_isSmsImportSupported) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SMS import is only available on Android. You can continue setup without it.'),
          ),
        );
        return;
      }
      final granted = await SmsReaderService.requestPermission();
      if (!mounted) return;

      final smsImportService = Provider.of<SmsImportService>(context, listen: false);
      await smsImportService.requestPermission();

      setState(() {
        _smsPermissionGranted = granted;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not request SMS permission: $e'),
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
    if (!_isSmsImportSupported) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('quick_setup_completed', true);
      await prefs.setBool('first_30_snapshot_shown', true);

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/dashboard');
      return;
    }
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Setup'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withAlpha((0.06 * 255).toInt()),
              theme.scaffoldBackgroundColor,
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: colorScheme.outlineVariant.withAlpha((0.65 * 255).toInt()),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha((0.06 * 255).toInt()),
                                blurRadius: 18,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withAlpha((0.10 * 255).toInt()),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  Icons.auto_awesome,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Set up Finance Flow in under a minute',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Connect SMS (private & local), set your income, pick 1–2 goals, then get your first snapshot.',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Theme(
                          data: theme.copyWith(
                            colorScheme: theme.colorScheme.copyWith(
                              primary: colorScheme.primary,
                              secondary: colorScheme.secondary,
                            ),
                          ),
                          child: Stepper(
                            currentStep: _stepIndex,
                            type: StepperType.vertical,
                            elevation: 0,
                            controlsBuilder: (context, details) {
                              final isLast = _stepIndex == 2;
                              return Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Row(
                                  children: [
                                    if (_stepIndex > 0)
                                      OutlinedButton(
                                        onPressed: _isWorking ? null : _back,
                                        child: const Text('Back'),
                                      ),
                                    const Spacer(),
                                    FilledButton(
                                      onPressed: _isWorking
                                          ? null
                                          : () async {
                                              final messenger = ScaffoldMessenger.of(this.context);
                                              if (_stepIndex == 0) {
                                                if (!_isSmsImportSupported) {
                                                  _next();
                                                  return;
                                                }
                                                if (!_smsPermissionGranted) {
                                                  await _requestSmsPermission();
                                                }
                                                if (_smsPermissionGranted) {
                                                  _next();
                                                } else {
                                                  if (!mounted) return;
                                                  messenger.showSnackBar(
                                                    const SnackBar(
                                                      content: Text('Grant SMS permission to continue.'),
                                                    ),
                                                  );
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
                                content: _buildStepCard(
                                  context,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'We only read SMS locally on your phone to compute your spending. We never send SMS contents to any server.',
                                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                                      ),
                                      if (!_isSmsImportSupported) ...[
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: colorScheme.surfaceContainerHighest.withAlpha((0.55 * 255).toInt()),
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Icon(Icons.web, color: colorScheme.onSurfaceVariant),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  'SMS permission is not supported on this platform. Continue to set your income/goals; you can connect SMS on Android later.',
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    color: colorScheme.onSurfaceVariant,
                                                    height: 1.35,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: colorScheme.surfaceContainerHighest.withAlpha((0.55 * 255).toInt()),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 34,
                                              height: 34,
                                              decoration: BoxDecoration(
                                                color: colorScheme.surface,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                _smsPermissionGranted ? Icons.check_circle : Icons.lock,
                                                color: _smsPermissionGranted ? Colors.green : colorScheme.onSurfaceVariant,
                                                size: 18,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                _smsPermissionGranted ? 'Permission granted' : 'Permission not granted',
                                                style: theme.textTheme.bodyMedium?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  color: _smsPermissionGranted ? Colors.green : colorScheme.onSurface,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary.withAlpha((0.08 * 255).toInt()),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: colorScheme.primary.withAlpha((0.18 * 255).toInt()),
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Icon(Icons.info_outline, color: colorScheme.primary),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                'Kenya context: This helps us auto-import M-Pesa and bank SMS (KCB, Equity, etc.) and instantly show your monthly picture.',
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: colorScheme.onSurfaceVariant,
                                                  height: 1.35,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Step(
                                title: const Text('Set monthly income & goals'),
                                isActive: _stepIndex >= 1,
                                content: _buildStepCard(
                                  context,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      TextField(
                                        controller: _monthlyIncomeController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText: 'Monthly income (KES)',
                                          hintText: 'e.g. 80000',
                                          prefixIcon: const Icon(Icons.payments_outlined),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: colorScheme.surfaceContainerHighest.withAlpha((0.45 * 255).toInt()),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Column(
                                          children: [
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
                                            const Divider(height: 1),
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
                                    ],
                                  ),
                                ),
                              ),
                              Step(
                                title: const Text('Instant insights'),
                                isActive: _stepIndex >= 2,
                                content: _buildStepCard(
                                  context,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'We’ll import your last 30 days, then show a First 30 Days Snapshot with your inflow/outflow, top categories, M-Pesa fees, and a simple “saved vs overspent” message.',
                                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: colorScheme.surfaceContainerHighest.withAlpha((0.55 * 255).toInt()),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildBullet(context, 'Inflow vs Outflow (last 30 days)'),
                                            const SizedBox(height: 6),
                                            _buildBullet(context, 'Top categories + M-Pesa fees estimate'),
                                            const SizedBox(height: 6),
                                            _buildBullet(context, 'Simple message: saved vs overspent'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard(BuildContext context, {required Widget child}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha((0.65 * 255).toInt())),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  Widget _buildBullet(BuildContext context, String text) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle, size: 18, color: colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
