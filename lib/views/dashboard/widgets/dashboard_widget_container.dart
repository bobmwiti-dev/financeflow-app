import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../models/dashboard_widget_config.dart';
import '../../../themes/app_theme.dart';

/// A container widget for dashboard items with consistent styling and edit controls
class DashboardWidgetContainer extends StatelessWidget {
  final DashboardWidgetConfig config;
  final Widget child;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;
  final VoidCallback? onDragComplete;
  
  const DashboardWidgetContainer({
    required this.config,
    required this.child,
    this.onEdit,
    this.onRemove,
    this.onDragComplete,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<DashboardWidgetConfig>(
      data: config,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.accentColor.withValues(alpha: 100),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                config.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Icon(
                  Icons.drag_indicator,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 50),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 100),
              width: 1,
            ),
          ),
          height: 200,
        ),
      ),
      onDragCompleted: onDragComplete,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 10),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and actions
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      config.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onEdit != null)
                    IconButton(
                      icon: const Icon(Icons.settings, size: 20),
                      onPressed: onEdit,
                      tooltip: 'Edit Widget',
                      visualDensity: VisualDensity.compact,
                    ),
                  if (onRemove != null)
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: onRemove,
                      tooltip: 'Remove Widget',
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),
            
            // Widget content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: child,
            ),
          ],
        ),
      ).animate()
        .fadeIn(duration: const Duration(milliseconds: 500))
        .slideY(begin: 0.1, end: 0),
    );
  }
}

/// A placeholder widget for empty dashboard slots
class DashboardEmptySlot extends StatelessWidget {
  final VoidCallback onAddWidget;
  
  const DashboardEmptySlot({
    required this.onAddWidget,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    return DragTarget<DashboardWidgetConfig>(
      onAcceptWithDetails: (details) {
    // Use details.data here if needed
        // Handle widget being dropped here
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey.withAlpha(20),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: candidateData.isNotEmpty
                  ? AppTheme.accentColor
                  : Colors.grey.withAlpha(100),
              width: candidateData.isNotEmpty ? 2 : 1,
              // Using a dash pattern instead of BorderStyle.dashed which doesn't exist
            ),
          ),
          child: InkWell(
            onTap: onAddWidget,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: candidateData.isNotEmpty
                        ? AppTheme.accentColor
                        : Colors.grey,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    candidateData.isNotEmpty
                        ? 'Drop Here'
                        : 'Add Widget',
                    style: TextStyle(
                      color: candidateData.isNotEmpty
                          ? AppTheme.accentColor
                          : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ).animate()
          .fadeIn(duration: const Duration(milliseconds: 500))
          .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.0, 1.0));
      },
    );
  }
}

/// A dialog for editing dashboard widget settings
class WidgetSettingsDialog extends StatefulWidget {
  final DashboardWidgetConfig config;
  
  const WidgetSettingsDialog({
    required this.config,
    super.key,
  });
  
  @override
  State<WidgetSettingsDialog> createState() => _WidgetSettingsDialogState();
}

class _WidgetSettingsDialogState extends State<WidgetSettingsDialog> {
  late TextEditingController _titleController;
  late Map<String, dynamic> _settings;
  
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.config.title);
    _settings = Map.from(widget.config.settings);
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.config.title}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Widget Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Settings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            ..._buildSettingsFields(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final updatedConfig = widget.config.copyWith(
              title: _titleController.text,
              settings: _settings,
            );
            Navigator.of(context).pop(updatedConfig);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
  
  List<Widget> _buildSettingsFields() {
    final List<Widget> fields = [];
    
    // Build different settings fields based on widget type
    switch (widget.config.type) {
      case WidgetType.spendingPieChart:
        fields.add(_buildDropdownSetting(
          'Period',
          'period',
          ['day', 'week', 'month', 'year'],
          (value) => setState(() => _settings['period'] = value),
        ));
        fields.add(_buildSwitchSetting(
          'Show Legend',
          'showLegend',
          (value) => setState(() => _settings['showLegend'] = value),
        ));
        fields.add(_buildSliderSetting(
          'Max Categories',
          'maxCategories',
          3,
          10,
          (value) => setState(() => _settings['maxCategories'] = value.round()),
        ));
        break;
        
      case WidgetType.budgetProgressBar:
        fields.add(_buildDropdownSetting(
          'Period',
          'period',
          ['day', 'week', 'month', 'year'],
          (value) => setState(() => _settings['period'] = value),
        ));
        fields.add(_buildSwitchSetting(
          'Show Remaining',
          'showRemaining',
          (value) => setState(() => _settings['showRemaining'] = value),
        ));
        break;
        
      case WidgetType.savingsGoalTracker:
        fields.add(_buildSwitchSetting(
          'Show All Goals',
          'showAllGoals',
          (value) => setState(() => _settings['showAllGoals'] = value),
        ));
        fields.add(_buildDropdownSetting(
          'Sort By',
          'sortBy',
          ['progress', 'amount', 'deadline'],
          (value) => setState(() => _settings['sortBy'] = value),
        ));
        break;
        
      case WidgetType.recentTransactions:
        fields.add(_buildSliderSetting(
          'Limit',
          'limit',
          3,
          10,
          (value) => setState(() => _settings['limit'] = value.round()),
        ));
        fields.add(_buildSwitchSetting(
          'Show Amount',
          'showAmount',
          (value) => setState(() => _settings['showAmount'] = value),
        ));
        break;
        
      case WidgetType.monthlySpendingTrend:
        fields.add(_buildSliderSetting(
          'Months',
          'months',
          3,
          12,
          (value) => setState(() => _settings['months'] = value.round()),
        ));
        fields.add(_buildSwitchSetting(
          'Show Average',
          'showAverage',
          (value) => setState(() => _settings['showAverage'] = value),
        ));
        break;
        
      case WidgetType.categoryComparison:
        fields.add(_buildMultiSelectSetting(
          'Periods',
          'periods',
          ['current_month', 'previous_month', 'year_to_date', 'previous_year'],
          (value) => setState(() => _settings['periods'] = value),
        ));
        // Category selection would be implemented here
        break;
        
      case WidgetType.spendingHeatMap:
        fields.add(_buildDropdownSetting(
          'Period',
          'period',
          ['week', 'month', 'quarter', 'year'],
          (value) => setState(() => _settings['period'] = value),
        ));
        fields.add(_buildDropdownSetting(
          'Type',
          'type',
          ['category', 'date', 'location'],
          (value) => setState(() => _settings['type'] = value),
        ));
        break;
    }
    
    return fields;
  }
  
  Widget _buildDropdownSetting(
    String label,
    String key,
    List<String> options,
    Function(String) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            value: _settings[key],
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: options.map((option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option.replaceAll('_', ' ').capitalize()),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                onChanged(value);
              }
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildSwitchSetting(
    String label,
    String key,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Switch(
            value: _settings[key] ?? false,
            onChanged: onChanged,
            activeColor: AppTheme.accentColor,
          ),
        ],
      ),
    );
  }
  
  Widget _buildSliderSetting(
    String label,
    String key,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text(_settings[key].toString()),
            ],
          ),
          Slider(
            value: _settings[key].toDouble(),
            min: min,
            max: max,
            divisions: (max - min).round(),
            label: _settings[key].toString(),
            onChanged: onChanged,
            activeColor: AppTheme.accentColor,
          ),
        ],
      ),
    );
  }
  
  Widget _buildMultiSelectSetting(
    String label,
    String key,
    List<String> options,
    Function(List<String>) onChanged,
  ) {
    final List<String> selectedOptions = List<String>.from(_settings[key] ?? []);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final isSelected = selectedOptions.contains(option);
              return FilterChip(
                label: Text(option.replaceAll('_', ' ').capitalize()),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    selectedOptions.add(option);
                  } else {
                    selectedOptions.remove(option);
                  }
                  onChanged(selectedOptions);
                },
                backgroundColor: Colors.grey.withValues(alpha: 50),
                selectedColor: AppTheme.accentColor,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    return split(' ').map((word) => word.isEmpty 
        ? '' 
        : '${word[0].toUpperCase()}${word.substring(1)}').join(' ');
  }
}
