import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

class QuickActionsPanel extends StatefulWidget {
  final List<String> recentPayees;
  final Function(String action) onActionSelected;
  final Function(String payee) onPayeeSelected;
  
  const QuickActionsPanel({
    super.key,
    required this.recentPayees,
    required this.onActionSelected,
    required this.onPayeeSelected,
  });

  @override
  State<QuickActionsPanel> createState() => _QuickActionsPanelState();
}

class _QuickActionsPanelState extends State<QuickActionsPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final List<Map<String, dynamic>> quickActions = [
      {
        'icon': Icons.shopping_cart_outlined,
        'color': Colors.redAccent,
        'label': 'Add Expense',
        'action': 'add_expense',
      },
      {
        'icon': Icons.attach_money,
        'color': Colors.green,
        'label': 'Add Income',
        'action': 'add_income',
      },
      {
        'icon': Icons.compare_arrows,
        'color': Colors.indigo,
        'label': 'Transfer',
        'action': 'transfer',
      },
      {
        'icon': Icons.pie_chart_outline,
        'color': Colors.orange,
        'label': 'New Budget',
        'action': 'new_budget',
      },
      {
        'icon': Icons.flag,
        'color': Colors.teal,
        'label': 'New Goal',
        'action': 'new_goal',
      },
      {
        'icon': Icons.sms,
        'color': Colors.green.shade600,
        'label': 'Import M-Pesa',
        'action': 'mpesa_import',
      },
      {
        'icon': Icons.directions_car,
        'color': Colors.blue.shade600,
        'label': 'Transport Intel',
        'action': 'transport_intelligence',
      },
    ];

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withValues(alpha: 0.03),
                  Colors.transparent,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.flash_on_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF1A1A1A), Color(0xFF4A4A4A)],
                        ).createShader(bounds),
                        child: const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Fast access to common tasks',
                        style: TextStyle(
                          fontSize: 15,
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color:
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.8),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: colorScheme.onPrimary,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              labelStyle: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
              unselectedLabelStyle: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(text: 'Actions'),
                Tab(text: 'Recent Payees'),
              ],
            ),
          ),
          SizedBox(
            height: 260,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Quick Actions Grid
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: quickActions.length,
                    itemBuilder: (context, index) {
                      final action = quickActions[index];
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            widget.onActionSelected(action['action']);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.surface,
                                  colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.85),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: colorScheme.outlineVariant
                                    .withValues(alpha: 0.6),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.shadow
                                      .withValues(alpha: 0.18),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        (action['color'] as Color)
                                            .withValues(alpha: 0.18),
                                        (action['color'] as Color)
                                            .withValues(alpha: 0.10),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (action['color'] as Color)
                                            .withValues(alpha: 0.18),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    action['icon'],
                                    color: action['color'],
                                    size: 20,
                                  ),
                                ).animate().scale(
                                      begin: const Offset(0.8, 0.8),
                                      end: const Offset(1, 1),
                                      delay:
                                          Duration(milliseconds: index * 80),
                                      duration:
                                          const Duration(milliseconds: 400),
                                      curve: Curves.easeOutBack,
                                    ),
                                const SizedBox(height: 6),
                                Flexible(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 2),
                                    child: Text(
                                      action['label'],
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurface,
                                        letterSpacing: -0.1,
                                        height: 1.2,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
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
                
                // Recent Payees List
                widget.recentPayees.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.people_outline_rounded,
                                size: 48,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No recent payees',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your recent transaction partners will appear here',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: widget.recentPayees.length,
                          itemBuilder: (context, index) {
                            if (index >= widget.recentPayees.length) {
                              return const SizedBox.shrink();
                            }
                            
                            final payee = widget.recentPayees[index];
                            final color = Colors.primaries[index % Colors.primaries.length];
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    colorScheme.surface,
                                    colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.9),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: colorScheme.outlineVariant
                                      .withValues(alpha: 0.6),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.shadow
                                        .withValues(alpha: 0.16),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                leading: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        color.withValues(alpha: 0.15),
                                        color.withValues(alpha: 0.08),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    payee.substring(0, 1).toUpperCase(),
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  payee,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: colorScheme.onSurface,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                subtitle: Text(
                                  'Tap to create transaction',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 13,
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  widget.onPayeeSelected(payee);
                                },
                              ),
                            );
                          },
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    ),
  ).animate()
    .fadeIn(duration: const Duration(milliseconds: 600))
    .slideY(begin: 0.1, end: 0);
  }
}
