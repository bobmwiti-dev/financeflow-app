import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/notification_model.dart';
import '../services/smart_notification_service.dart';

class NotificationBadge extends StatefulWidget {
  final VoidCallback? onTap;
  final Color? badgeColor;
  final Color? iconColor;
  final double iconSize;

  const NotificationBadge({
    super.key,
    this.onTap,
    this.badgeColor,
    this.iconColor,
    this.iconSize = 24,
  });

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge>
    with TickerProviderStateMixin {
  final SmartNotificationService _notificationService = SmartNotificationService();
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticOut,
    ));
    
    // Listen for new notifications to trigger animations
    _notificationService.notificationStream.listen((notifications) {
      final unreadCount = notifications.where((n) => !n.isRead && n.shouldShow).length;
      
      if (unreadCount > 0) {
        _startPulseAnimation();
        
        // Shake animation for high priority notifications
        final hasHighPriority = notifications.any((n) => 
            !n.isRead && n.priority.index >= 2 && n.shouldShow);
        
        if (hasHighPriority) {
          _startShakeAnimation();
        }
      } else {
        _stopAnimations();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _startPulseAnimation() {
    if (!_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }
  }

  void _startShakeAnimation() {
    if (!_shakeController.isAnimating) {
      _shakeController.forward().then((_) {
        _shakeController.reset();
      });
    }
  }

  void _stopAnimations() {
    _pulseController.stop();
    _pulseController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SmartNotification>>(
      stream: _notificationService.notificationStream,
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? [];
        final unreadNotifications = notifications
            .where((n) => !n.isRead && n.shouldShow)
            .toList();
        
        final unreadCount = unreadNotifications.length;
        final hasHighPriority = unreadNotifications
            .any((n) => n.priority.index >= 2);
        
        return GestureDetector(
          onTap: widget.onTap,
          child: AnimatedBuilder(
            animation: Listenable.merge([_pulseAnimation, _shakeAnimation]),
            builder: (context, child) {
              return Transform.scale(
                scale: unreadCount > 0 ? _pulseAnimation.value : 1.0,
                child: Transform.translate(
                  offset: Offset(
                    hasHighPriority ? (_shakeAnimation.value * 10 * (0.5 - ((_shakeAnimation.value * 4) % 1).abs())) : 0,
                    0,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Notification icon
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: unreadCount > 0 
                              ? (hasHighPriority ? Colors.red.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          unreadCount > 0 ? Icons.notifications_active : Icons.notifications_none,
                          size: widget.iconSize,
                          color: widget.iconColor ?? 
                              (unreadCount > 0 
                                  ? (hasHighPriority ? Colors.red : Colors.blue)
                                  : Colors.grey[600]),
                        ),
                      ),
                      
                      // Badge
                      if (unreadCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: widget.badgeColor ?? 
                                  (hasHighPriority ? Colors.red : Colors.blue),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ).animate()
                          .scale(
                            begin: const Offset(0, 0),
                            end: const Offset(1, 1),
                            duration: 300.ms,
                            curve: Curves.elasticOut,
                          ),
                      
                      // Priority indicator (pulsing dot for critical notifications)
                      if (unreadNotifications.any((n) => n.priority == NotificationPriority.critical))
                        Positioned(
                          left: 0,
                          top: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.purple.withValues(alpha: 0.6),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ).animate(onPlay: (controller) => controller.repeat())
                          .scale(
                            begin: const Offset(0.8, 0.8),
                            end: const Offset(1.2, 1.2),
                            duration: 1000.ms,
                          )
                          .then()
                          .scale(
                            begin: const Offset(1.2, 1.2),
                            end: const Offset(0.8, 0.8),
                            duration: 1000.ms,
                          ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class NotificationQuickPreview extends StatelessWidget {
  final List<SmartNotification> notifications;
  final VoidCallback? onViewAll;
  final VoidCallback? onMarkAllRead;

  const NotificationQuickPreview({
    super.key,
    required this.notifications,
    this.onViewAll,
    this.onMarkAllRead,
  });

  @override
  Widget build(BuildContext context) {
    final unreadNotifications = notifications
        .where((n) => !n.isRead && n.shouldShow)
        .take(3)
        .toList();

    if (unreadNotifications.isEmpty) {
      return Container(
        width: 300,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'No new notifications',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'You\'re all caught up!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: 320,
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  color: Colors.blue[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Recent Notifications',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (onMarkAllRead != null)
                  GestureDetector(
                    onTap: onMarkAllRead,
                    child: Text(
                      'Mark all read',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Notification list
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              itemCount: unreadNotifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notification = unreadNotifications[index];
                return _buildQuickNotificationItem(notification);
              },
            ),
          ),
          
          // Footer
          if (onViewAll != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: GestureDetector(
                onTap: onViewAll,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'View All Notifications',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: Colors.blue[600],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickNotificationItem(SmartNotification notification) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: notification.color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: notification.color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: notification.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              notification.icon,
              size: 16,
              color: notification.color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  notification.message,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: notification.color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              notification.priorityLabel,
              style: const TextStyle(
                fontSize: 8,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
