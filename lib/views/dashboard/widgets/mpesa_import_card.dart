import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingCard();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade600,
            Colors.green.shade700,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
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
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.sms,
                        color: Colors.white,
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
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getStatusText(),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.analytics, color: Colors.white, size: 20),
                          onPressed: () => Navigator.pushNamed(context, '/mpesa_analytics'),
                          tooltip: 'View Analytics',
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 16,
                        ),
                      ],
                    ),
                  ],
                ),
                if (_hasPermission && _importStats.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            'Total Records',
                            '${_importStats['totalMpesaTransactions'] ?? 0}',
                            Icons.receipt_long,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            'Imported',
                            '${_importStats['importedTransactions'] ?? 0}',
                            Icons.check_circle,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        Expanded(
                          child: _buildStatItem(
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

  Widget _buildLoadingCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.8),
          size: 16,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 10,
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
