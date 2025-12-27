import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/currency_service.dart';
import '../../models/currency_model.dart';

import '../../widgets/app_navigation_drawer.dart';
import '../../services/navigation_service.dart';
import '../../themes/app_theme.dart';
import '../../constants/app_constants.dart';
import 'data_migration_screen.dart';
import '../../services/auth_service.dart';
import '../../services/mock_data_service.dart';
import '../auth/sign_in_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with TickerProviderStateMixin {
  int _selectedIndex = 5; // Settings tab selected
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _showDualCurrency = false; // Kenya-focused: KES + USD conversion

  String _currency = 'KES';
  String _language = 'English';
  bool _isGeneratingData = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _loadSettings();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _darkModeEnabled = prefs.getBool('dark_mode_enabled') ?? false;
      // Currency is managed by CurrencyService (default KES)
      final curr = CurrencyService().preferences.primaryCurrency;
      _currency = CurrencyData.getCurrency(curr).isoCode;
      _showDualCurrency = CurrencyService().preferences.enableCurrencyConversion;
      _language = prefs.getString('language') ?? 'English';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('dark_mode_enabled', _darkModeEnabled);
    await prefs.setString('language', _language);
    // Dual currency is managed by CurrencyService
  }

  void _onItemSelected(int index) {
    setState(() => _selectedIndex = index);

    final route = NavigationService.routeForDrawerIndex(index);

    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    if (ModalRoute.of(context)?.settings.name != route) {
      NavigationService.navigateToReplacement(route);
    }
  }

  Future<void> _handleLogout() async {
    try {
      await AuthService.instance.logout();
      if (!mounted) return;
      // Navigate to login screen and remove all previous routes
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const SignInScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      // Handle any errors during logout, maybe show a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withValues(alpha: 0.8),
                      AppTheme.accentColor.withValues(alpha: 0.6),
                    ],
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildEnhancedSettingsSection(
                    'General',
                    Icons.settings,
                    [
                      _buildEnhancedSettingsItem(
                        icon: Icons.account_balance_wallet,
                        title: 'Manage Accounts',
                        subtitle: 'Add, edit, or delete accounts',
                        onTap: () => Navigator.pushNamed(context, '/account_management'),
                      ),
                      _buildEnhancedSettingsItem(
                        icon: Icons.language,
                        title: 'Language',
                        subtitle: _language,
                        onTap: () => _showLanguageDialog(),
                      ),
                      _buildEnhancedSettingsItem(
                        icon: Icons.attach_money,
                        title: 'Currency',
                        subtitle: _currency,
                        onTap: () => _showCurrencyDialog(),
                      ),
                      _buildEnhancedSettingsItem(
                        icon: Icons.currency_exchange,
                        title: 'Show USD Conversion',
                        subtitle: 'Display amounts in both KES and USD',
                        onTap: () => _toggleDualCurrency(),
                        trailing: _buildAnimatedSwitch(
                          value: _showDualCurrency,
                          onChanged: (value) => _toggleDualCurrency(),
                        ),
                      ),
                      _buildEnhancedSettingsItem(
                        icon: Icons.dark_mode,
                        title: 'Dark Mode',
                        onTap: () {
                          setState(() => _darkModeEnabled = !_darkModeEnabled);
                          _saveSettings();
                        },
                        trailing: _buildAnimatedSwitch(
                          value: _darkModeEnabled,
                          onChanged: (value) {
                            setState(() => _darkModeEnabled = value);
                            _saveSettings();
                          },
                        ),
                      ),
                      _buildEnhancedSettingsItem(
                        icon: Icons.notifications,
                        title: 'Notifications',
                        onTap: () {
                          setState(() => _notificationsEnabled = !_notificationsEnabled);
                          _saveSettings();
                        },
                        trailing: _buildAnimatedSwitch(
                          value: _notificationsEnabled,
                          onChanged: (value) {
                            setState(() => _notificationsEnabled = value);
                            _saveSettings();
                          },
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 600.ms, delay: 100.ms).moveY(begin: 20, end: 0),
                  const SizedBox(height: 24),
                  _buildEnhancedSettingsSection(
                    'Data & Privacy',
                    Icons.security,
                    [
                      _buildEnhancedSettingsItem(
                        icon: Icons.sms,
                        title: 'Import M-Pesa Transactions',
                        subtitle: 'Import transactions from SMS messages',
                        onTap: () {
                          Navigator.pushNamed(context, '/mpesa_import');
                        },
                      ),
                      _buildEnhancedSettingsItem(
                        icon: Icons.mobile_friendly,
                        title: 'M-Pesa Settings',
                        subtitle: 'Configure automatic import preferences',
                        onTap: () {
                          Navigator.pushNamed(context, '/mpesa_settings');
                        },
                      ),
                      _buildEnhancedSettingsItem(
                        icon: Icons.analytics,
                        title: 'M-Pesa Analytics',
                        subtitle: 'View detailed M-Pesa spending insights',
                        onTap: () {
                          Navigator.pushNamed(context, '/mpesa_analytics');
                        },
                      ),
                      _buildEnhancedSettingsItem(
                        icon: Icons.directions_car,
                        title: 'Transport Intelligence',
                        subtitle: 'Optimize your transport costs and routes',
                        onTap: () {
                          Navigator.pushNamed(context, '/transport_intelligence');
                        },
                      ),
                      _buildEnhancedSettingsItem(
                        icon: Icons.cloud_upload,
                        title: 'Migrate to Cloud',
                        subtitle: 'Transfer local data to Firebase',
                        onTap: () {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const DataMigrationScreen()),
                            );
                          } else {
                            _showSignInDialog();
                          }
                        },
                      ),
                      _buildEnhancedSettingsItem(
                        icon: Icons.backup,
                        title: 'Backup Data',
                        subtitle: 'Last backup: Never',
                        onTap: () {},
                      ),
                      _buildEnhancedSettingsItem(
                        icon: Icons.restore,
                        title: 'Restore Data',
                        subtitle: 'Restore from a backup file',
                        onTap: () {},
                      ),
                      _buildEnhancedSettingsItem(
                        icon: Icons.auto_fix_high,
                        title: 'Generate Demo Data',
                        subtitle: 'Create sample transactions for March-August 2024',
                        onTap: _isGeneratingData ? () {} : _showGenerateDataDialog,
                        trailing: _isGeneratingData 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : null,
                      ),
                      _buildEnhancedSettingsItem(
                        icon: Icons.delete_forever,
                        title: 'Clear All Data',
                        subtitle: 'Delete all your local data',
                        onTap: () => _showClearDataDialog(),
                        isDestructive: true,
                      ),
                    ],
                  ).animate().fadeIn(duration: 600.ms, delay: 200.ms).moveY(begin: 20, end: 0),
                  const SizedBox(height: 24),
                  _buildEnhancedSettingsSection(
                    'About',
                    Icons.info,
                    [
                      _buildEnhancedSettingsItem(
                        icon: Icons.info_outline,
                        title: 'App Version',
                        subtitle: AppConstants.appVersion,
                        onTap: () {},
                      ),
                      _buildEnhancedSettingsItem(
                        icon: Icons.description_outlined,
                        title: 'Terms of Service',
                        onTap: () {},
                      ),
                      _buildEnhancedSettingsItem(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        onTap: () {},
                      ),
                    ],
                  ).animate().fadeIn(duration: 600.ms, delay: 300.ms).moveY(begin: 20, end: 0),
                  const SizedBox(height: 40),
                  _buildLogoutButton().animate().fadeIn(duration: 600.ms, delay: 400.ms).scaleXY(begin: 0.8, end: 1.0),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
      drawer: AppNavigationDrawer(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemSelected,
      ),
    );
  }

  Widget _buildEnhancedSettingsSection(String title, IconData sectionIcon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.1),
                  AppTheme.accentColor.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    sectionIcon,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildEnhancedSettingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Widget? trailing,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDestructive
                          ? [
                              AppTheme.errorColor.withValues(alpha: 0.1),
                              AppTheme.errorColor.withValues(alpha: 0.05),
                            ]
                          : [
                              AppTheme.primaryColor.withValues(alpha: 0.1),
                              AppTheme.accentColor.withValues(alpha: 0.05),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isDestructive ? AppTheme.errorColor : AppTheme.primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDestructive ? AppTheme.errorColor : Colors.black87,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 16),
                  trailing,
                ] else ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade400,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.accentColor,
        activeTrackColor: AppTheme.accentColor.withValues(alpha: 0.3),
        inactiveThumbColor: Colors.grey.shade400,
        inactiveTrackColor: Colors.grey.shade300,
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 32),
      child: ElevatedButton.icon(
        onPressed: _handleLogout,
        icon: const Icon(Icons.logout, color: Colors.white),
        label: const Text(
          'Logout',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.errorColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          shadowColor: AppTheme.errorColor.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Language'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['English', 'Spanish', 'French', 'German'].map((lang) {
              return RadioListTile(
                title: Text(lang),
                value: lang,
                groupValue: _language,
                onChanged: (value) {
                  setState(() => _language = value as String);
                  _saveSettings();
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showCurrencyDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Currency'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...CurrencyData.popularCurrencies.map((currency) {
                final iso = currency.isoCode;
                return RadioListTile<String>(
                  title: Text('${currency.flag} ${currency.name} (${currency.isoCode})'),
                  value: iso,
                  groupValue: _currency,
                  onChanged: (value) async {
                    if (value == null) return;
                    final selected = CurrencyData.allCurrencies.firstWhere((c) => c.isoCode == value);
                    await CurrencyService().setPrimaryCurrency(selected.code);
                    setState(() => _currency = selected.isoCode);
                    if (context.mounted) Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  /// Toggle dual currency display (KES + USD conversion) for Kenya market
  Future<void> _toggleDualCurrency() async {
    setState(() {
      _showDualCurrency = !_showDualCurrency;
    });
    
    // Update CurrencyService preferences
    final currentPrefs = CurrencyService().preferences;
    final newPrefs = currentPrefs.copyWith(
      enableCurrencyConversion: _showDualCurrency,
      secondaryCurrency: _showDualCurrency ? SupportedCurrency.usd : null,
    );
    
    await CurrencyService().updatePreferences(newPrefs);
  }

  void _showSignInDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign In Required'),
        content: const Text('You need to be signed in to migrate your data to the cloud.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showGenerateDataDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Generate Demo Data'),
          content: const Text(
            'This will create realistic sample transactions, income, and budgets for March-August 2024. '
            'Your existing January and February data will remain unchanged.\n\n'
            'This process may take a few moments.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _generateMockData();
              },
              child: const Text('Generate Data', style: TextStyle(color: AppTheme.primaryColor)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _generateMockData() async {
    setState(() => _isGeneratingData = true);

    try {
      final success = await MockDataService.generateMockData();
      
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Demo data generated successfully! Check your dashboard.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to generate demo data. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGeneratingData = false);
      }
    }
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear All Data'),
          content: const Text('Are you sure you want to delete all your data? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Add data clearing logic here
              },
              child: const Text('Clear Data', style: TextStyle(color: AppTheme.errorColor)),
            ),
          ],
        );
      },
    );
  }
}
