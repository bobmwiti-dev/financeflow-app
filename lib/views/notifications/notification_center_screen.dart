import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/notification_model.dart';
import '../../services/smart_notification_service.dart';
import '../../themes/app_theme.dart';
import '../../widgets/app_navigation_drawer.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen>
    with TickerProviderStateMixin {
  final SmartNotificationService _notificationService = SmartNotificationService();
  late AnimationController _refreshController;
  int _selectedFilterIndex = 0; // 0 = All, 1 = Unread, 2 = High Priority
  NotificationType? _selectedTypeFilter;

  final List<String> _filterLabels = ['All', 'Unread', 'High Priority'];

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _notificationService.initialize();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  List<SmartNotification> _getFilteredNotifications(List<SmartNotification> notifications) {
    var filtered = notifications.where((n) => n.shouldShow).toList();

    // Apply main filter
    switch (_selectedFilterIndex) {
      case 1: // Unread
        filtered = filtered.where((n) => !n.isRead).toList();
        break;
      case 2: // High Priority
        filtered = filtered.where((n) => n.priority.index >= 2).toList();
        break;
    }

    // Apply type filter
    if (_selectedTypeFilter != null) {
      filtered = filtered.where((n) => n.type == _selectedTypeFilter).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Mark all as read
          StreamBuilder<List<SmartNotification>>(
            stream: _notificationService.notificationStream,
            builder: (context, snapshot) {
              final hasUnread = snapshot.data?.any((n) => !n.isRead) ?? false;
              
              return IconButton(
                onPressed: hasUnread ? _markAllAsRead : null,
                icon: Icon(
                  Icons.done_all,
                  color: hasUnread ? Colors.blue : Colors.grey,
                ),
                tooltip: 'Mark all as read',
              );
            },
          ),
          
          // Clear all notifications
          IconButton(
            onPressed: _showClearAllDialog,
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear all',
          ),
          
          // Refresh
          IconButton(
            onPressed: _refreshNotifications,
            icon: AnimatedBuilder(
              animation: _refreshController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _refreshController.value * 2 * 3.14159,
                  child: const Icon(Icons.refresh),
                );
              },
            ),
            tooltip: 'Refresh',
          ),
        ],
      ),
      drawer: const AppNavigationDrawer(selectedIndex: 13), // Notifications index
      body: Column(
        children: [
          // Filter Section
          _buildFilterSection(),
          
          // Notification List
          Expanded(
            child: StreamBuilder<List<SmartNotification>>(
              stream: _notificationService.notificationStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }
                
                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }
                
                final notifications = snapshot.data ?? [];
                final filteredNotifications = _getFilteredNotifications(notifications);
                
                if (filteredNotifications.isEmpty) {
                  return _buildEmptyState();
                }
                
                return _buildNotificationList(filteredNotifications);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main filters
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filterLabels.asMap().entries.map((entry) {
                      final index = entry.key;
                      final label = entry.value;
                      final isSelected = _selectedFilterIndex == index;
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedFilterIndex = index;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue : Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey[700],
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Type filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTypeFilterChip('All Types', null),
                ...NotificationType.values.map((type) => 
                  _buildTypeFilterChip(_getTypeDisplayName(type), type)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilterChip(String label, NotificationType? type) {
    final isSelected = _selectedTypeFilter == type;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTypeFilter = type;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigo : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.indigo : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Loading notifications...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshNotifications,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;
    
    switch (_selectedFilterIndex) {
      case 1:
        message = 'No unread notifications';
        icon = Icons.mark_email_read;
        break;
      case 2:
        message = 'No high priority notifications';
        icon = Icons.priority_high;
        break;
      default:
        message = 'No notifications yet';
        icon = Icons.notifications_none;
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll notify you when something important happens',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 500.ms)
      .scale(begin: const Offset(0.8, 0.8), duration: 500.ms);
  }

  Widget _buildNotificationList(List<SmartNotification> notifications) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationTile(notification, index);
      },
    );
  }

  Widget _buildNotificationTile(SmartNotification notification, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.grey[50] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.isRead ? Colors.grey[200]! : notification.color.withValues(alpha: 0.3),
          width: notification.isRead ? 1 : 2,
        ),
        boxShadow: [
          if (!notification.isRead)
            BoxShadow(
              color: notification.color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _handleNotificationTap(notification),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: notification.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    notification.icon,
                    color: notification.color,
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and timestamp
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                                color: notification.isRead ? Colors.grey[700] : Colors.black,
                              ),
                            ),
                          ),
                          Text(
                            _formatTimestamp(notification.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Priority badge
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: notification.color,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              notification.priorityLabel,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getTypeDisplayName(notification.type),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Message
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: notification.isRead ? Colors.grey[600] : Colors.grey[800],
                          height: 1.4,
                        ),
                      ),
                      
                      // Action buttons
                      if (notification.actionRoute != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: notification.color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.arrow_forward,
                                      size: 16,
                                      color: notification.color,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Take Action',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: notification.color,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (!notification.isRead)
                              GestureDetector(
                                onTap: () => _markAsRead(notification.id),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.done,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Unread indicator
                if (!notification.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: notification.color,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: 300.ms, delay: Duration(milliseconds: index * 50))
      .slideX(begin: 0.2, duration: 300.ms, curve: Curves.easeOutCubic);
  }

  void _handleNotificationTap(SmartNotification notification) {
    // Mark as read
    _notificationService.markAsRead(notification.id);
    
    // Navigate to action route if available
    if (notification.actionRoute != null) {
      _notificationService.markAsActioned(notification.id);
      
      if (notification.actionArguments.isNotEmpty) {
        Navigator.of(context).pushNamed(
          notification.actionRoute!,
          arguments: notification.actionArguments,
        );
      } else {
        Navigator.of(context).pushNamed(notification.actionRoute!);
      }
    }
  }

  void _markAsRead(String notificationId) {
    _notificationService.markAsRead(notificationId);
  }

  void _markAllAsRead() {
    final notifications = _notificationService.notifications;
    for (final notification in notifications) {
      if (!notification.isRead) {
        _notificationService.markAsRead(notification.id);
      }
    }
  }

  void _refreshNotifications() {
    _refreshController.forward().then((_) {
      _refreshController.reset();
    });
    
    // In real implementation, this would trigger a refresh of financial data
    // and regenerate notifications
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to clear all notifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _notificationService.clearAll();
              Navigator.of(context).pop();
            },
            child: const Text(
              'Clear All',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }

  String _getTypeDisplayName(NotificationType type) {
    switch (type) {
      case NotificationType.budgetAlert:
        return 'Budget';
      case NotificationType.goalReminder:
        return 'Goal';
      case NotificationType.billDue:
        return 'Bill';
      case NotificationType.anomalyDetected:
        return 'Anomaly';
      case NotificationType.savingsOpportunity:
        return 'Savings';
      case NotificationType.mpesaAlert:
        return 'M-Pesa';
      case NotificationType.weeklyInsight:
        return 'Weekly';
      case NotificationType.monthlyReport:
        return 'Monthly';
      case NotificationType.emergencyAlert:
        return 'Emergency';
      case NotificationType.achievementUnlocked:
        return 'Achievement';
    }
  }
}
