import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../utils/currency_extensions.dart';
import '../../utils/enhanced_animations.dart';
import '../../utils/form_dialogs.dart';

/// A unified panel for managing income, budget, and loan sections
/// Removes redundancy by providing a single add button per section
/// and maintains a consistent UI pattern across all financial management tasks
class UnifiedFinancialManagementPanel extends StatefulWidget {
  final List<FinancialManagementSection> sections;
  final Function(FinancialManagementSection, FinancialManagementItem)? onItemTap;
  final Function(FinancialManagementSection)? onAddItem;
  final Function(FinancialManagementSection)? onViewAll;

  const UnifiedFinancialManagementPanel({
    super.key,
    required this.sections,
    this.onItemTap,
    this.onAddItem,
    this.onViewAll,
  });

  @override
  State<UnifiedFinancialManagementPanel> createState() => _UnifiedFinancialManagementPanelState();
}

class _UnifiedFinancialManagementPanelState extends State<UnifiedFinancialManagementPanel> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section tabs - Income, Budget, Loans
          _buildTabHeader(),
          
          // Content for selected tab
          _buildTabContent(),
        ],
      ),
    )
    .animate()
    .fadeIn(duration: const Duration(milliseconds: 800))
    .moveY(begin: 20, end: 0, curve: Curves.easeOutQuint);
  }

  Widget _buildTabHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: List.generate(
                widget.sections.length,
                (index) => _buildTabButton(index),
              ),
            ),
          ),
          // Add button for current section - single unified button
          if (widget.onAddItem != null)
            EnhancedAnimations.scaleOnTap(
              onTap: () async {
                HapticFeedback.mediumImpact();
                final section = widget.sections[_selectedTabIndex];
                
                // Show the appropriate form dialog based on section type
                FinancialManagementItem? newItem;
                
                if (section.name == 'Income') {
                  newItem = await FormDialogs.showIncomeFormDialog(context: context);
                } else if (section.name == 'Budget') {
                  newItem = await FormDialogs.showBudgetFormDialog(context: context);
                } else if (section.name == 'Loans') {
                  newItem = await FormDialogs.showLoanFormDialog(context: context);
                }
                
                // If an item was created and the callback exists, invoke it
                if (newItem != null && widget.onAddItem != null && mounted) {
                  widget.onAddItem!(section);
                  
                  // Show a success message with a nice animation - properly check mounted status
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 12),
                            Text('${newItem.name} added successfully'),
                          ],
                        ),
                        backgroundColor: section.color,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.sections[_selectedTabIndex].color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_circle, 
                      size: 16, 
                      color: widget.sections[_selectedTabIndex].color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Add ${widget.sections[_selectedTabIndex].name}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: widget.sections[_selectedTabIndex].color,
                      ),
                    ),
                  ],
                ),
              )
              .animate(
                onPlay: (controller) => controller.repeat(reverse: true, period: const Duration(milliseconds: 3000)),
              )
              .scaleXY(begin: 1.0, end: 1.05, duration: const Duration(milliseconds: 1000), curve: Curves.easeInOut),
            ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index) {
    final section = widget.sections[index];
    final isSelected = _selectedTabIndex == index;
    
    return EnhancedAnimations.scaleOnTap(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? section.color.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? section.color
                : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              section.icon,
              color: isSelected ? section.color : Colors.grey.shade600,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              section.name,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? section.color : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    final currentSection = widget.sections[_selectedTabIndex];
    final items = currentSection.items;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentSection.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentSection.subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              // Total amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentSection.totalAmount.toCurrency(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: currentSection.color,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          const Divider(),
          
          // Items list
          items.isEmpty
              ? _buildEmptyState(currentSection)
              : Column(
                  children: [
                    ...List.generate(
                      items.length > 3 ? 3 : items.length,
                      (index) => _buildItemCard(items[index], currentSection, index),
                    ),
                    
                    // View all button
                    if (items.length > 3 && widget.onViewAll != null)
                      TextButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          if (widget.onViewAll != null) {
                            widget.onViewAll!(currentSection);
                          }
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('View All ${items.length} ${currentSection.name}'),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward, size: 16),
                          ],
                        ),
                      ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(FinancialManagementSection section) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            section.icon,
            size: 48,
            color: Colors.grey.shade300,
          )
          .animate()
          .scale(duration: const Duration(milliseconds: 600), curve: Curves.elasticOut),
          const SizedBox(height: 16),
          Text(
            'No ${section.name} Added Yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            section.emptyStateMessage,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          if (widget.onAddItem != null) ...[  
            const SizedBox(height: 16),
            EnhancedAnimations.animatedButton(
              ElevatedButton.icon(
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  
                  // Show the appropriate form dialog based on section type
                  FinancialManagementItem? newItem;
                  
                  if (section.name == 'Income') {
                    newItem = await FormDialogs.showIncomeFormDialog(context: context);
                  } else if (section.name == 'Budget') {
                    newItem = await FormDialogs.showBudgetFormDialog(context: context);
                  } else if (section.name == 'Loans') {
                    newItem = await FormDialogs.showLoanFormDialog(context: context);
                  }
                  
                  // If an item was created and the callback exists, invoke it
                  if (newItem != null && widget.onAddItem != null && mounted) {
                    widget.onAddItem!(section);
                    
                    // Show a success message with an animated snackbar
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 12),
                              Text('${newItem.name} added successfully'),
                            ],
                          ),
                          backgroundColor: section.color,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          // Use standard animation
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.add, size: 16),
                label: Text('Add ${section.name}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: section.color,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemCard(
    FinancialManagementItem item,
    FinancialManagementSection section,
    int index,
  ) {
    return EnhancedAnimations.scaleOnTap(
      onTap: () {
        HapticFeedback.selectionClick();
        if (widget.onItemTap != null) {
          widget.onItemTap!(section, item);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: section.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                item.icon ?? section.icon,
                color: section.color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.amount.toCurrency(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (item.period != null)
                  Text(
                    item.period!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    )
    .animate(delay: Duration(milliseconds: 100 * index))
    .fadeIn(duration: const Duration(milliseconds: 600))
    .slideY(begin: 0.2, end: 0);
  }
}

/// Model class for financial section (Income, Budget, Loan)
class FinancialManagementSection {
  final String id;
  final String name;
  final String subtitle;
  final double totalAmount;
  final IconData icon;
  final Color color;
  final List<FinancialManagementItem> items;
  final String emptyStateMessage;

  const FinancialManagementSection({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.totalAmount,
    required this.icon,
    required this.color,
    required this.items,
    required this.emptyStateMessage,
  });
}

/// Model class for items within a section
class FinancialManagementItem {
  final String id;
  final String name;
  final String description;
  final double amount;
  final String? period;
  final IconData? icon;
  final DateTime? date;
  final bool? isRecurring;

  const FinancialManagementItem({
    required this.id,
    required this.name,
    required this.description,
    required this.amount,
    this.period,
    this.icon,
    this.date,
    this.isRecurring,
  });
}
