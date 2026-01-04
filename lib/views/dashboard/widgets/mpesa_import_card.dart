import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:logging/logging.dart';

import '../../../services/mpesa_import_service.dart';
import '../../../services/sms_reader_service.dart';

class MpesaImportCard extends StatefulWidget {
  const MpesaImportCard({super.key});

  @override
  State<MpesaImportCard> createState() => _MpesaImportCardState();
}

class _MpesaImportCardState extends State<MpesaImportCard> {
  final Logger _logger = Logger('MpesaImportCard');
  
  bool _isLoading = true;
  Map<String, dynamic> _importStats = {};
  bool _hasPermission = false;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _loadMpesaStatus();
  }

  Future<void> _loadMpesaStatus() async {
    try {
      final hasPermission = await SmsReaderService.hasPermission();
      final importStats = await MpesaImportService.getImportStatistics();
      
      if (mounted) {
        setState(() {
          _hasPermission = hasPermission;
          _importStats = importStats;
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.severe('Error loading M-Pesa status: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _importNow() async {
    if (_isImporting) return;
    // Capture ScaffoldMessenger before any async gaps to avoid using
    // BuildContext across awaits.
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _isImporting = true;
    });

    try {
      final lastImportDate = _importStats['lastImportDate'] as DateTime?;
      final result = await MpesaImportService.importTransactions(
        since: lastImportDate,
        maxDays: 30,
        categorizeAutomatically: true,
        skipDuplicates: true,
      );

      if (!mounted) return;

      await _loadMpesaStatus();

      if (result.success && result.imported > 0) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Imported ${result.imported} M-Pesa transactions'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      _logger.severe('Error importing M-Pesa from dashboard card: $e');
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Error importing M-Pesa transactions'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return _buildLoadingCard(theme, colorScheme);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            colorScheme.surface,
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.pushNamed(context, '/mpesa_import');
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            colorScheme.primaryContainer.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.sms,
                        color: colorScheme.onPrimaryContainer,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'M-Pesa Import',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getStatusText(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.analytics,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            Navigator.pushNamed(context, '/mpesa_analytics');
                          },
                          tooltip: 'View Analytics',
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.7),
                          size: 16,
                        ),
                      ],
                    ),
                  ],
                ),
                if (_hasPermission &&
                    (_importStats['pendingTransactions'] ?? 0) > 0)
                  _buildImportBanner(),
                if (_hasPermission && _importStats.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outlineVariant
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            theme,
                            colorScheme,
                            'Total Records',
                            '${_importStats['totalMpesaTransactions'] ?? 0}',
                            Icons.receipt_long,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: colorScheme.outlineVariant
                              .withValues(alpha: 0.5),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            theme,
                            colorScheme,
                            'Imported',
                            '${_importStats['importedTransactions'] ?? 0}',
                            Icons.check_circle,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: colorScheme.outlineVariant
                              .withValues(alpha: 0.5),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            theme,
                            colorScheme,
                            'Pending',
                            '${_importStats['pendingTransactions'] ?? 0}',
                            Icons.pending,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideX(begin: 0.3, end: 0);
  }

  Widget _buildImportBanner() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pending = _importStats['pendingTransactions'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: colorScheme.onSecondaryContainer,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'New M-Pesa SMS detected  Import now? ($pending pending)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSecondaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _isImporting
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    _importNow();
                  },
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.onSecondaryContainer,
              backgroundColor: colorScheme.onSecondaryContainer
                  .withValues(alpha: 0.08),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              shape: const StadiumBorder(),
            ),
            child: _isImporting
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  )
                : Text(
                    'Import now',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            colorScheme.surface,
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    ColorScheme colorScheme,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: colorScheme.primary,
          size: 16,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _getStatusText() {
    if (!_hasPermission) {
      return 'Tap to grant SMS permission and start importing';
    }
    
    if (_importStats.isEmpty) {
      return 'Loading import status...';
    }
    
    final pending = _importStats['pendingTransactions'] ?? 0;
    if (pending > 0) {
      return '$pending new M-Pesa transactions ready to import';
    }
    
    final lastImport = _importStats['lastImportDate'];
    if (lastImport != null) {
      return 'Last import: ${_formatDate(lastImport)}';
    }
    
    return 'Tap to import your M-Pesa transactions';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
