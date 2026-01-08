import 'package:flutter/material.dart';

class ReportPeriodSelector extends StatelessWidget {
  final String selectedPeriod;
  final Function(String) onPeriodChanged;

  static const Color _accentColor = Color(0xFF6366F1);

  const ReportPeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Text(
              'Period:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPeriodButton('Weekly', context),
                    _buildPeriodButton('Monthly', context),
                    _buildPeriodButton('Quarterly', context),
                    _buildPeriodButton('Yearly', context),
                    _buildPeriodButton('Custom', context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String period, BuildContext context) {
    final isSelected = selectedPeriod == period;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(period),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            onPeriodChanged(period);
          }
        },
        backgroundColor: Colors.grey.shade200,
        selectedColor: _accentColor.withValues(alpha: 0.2),
        labelStyle: TextStyle(
          color: isSelected ? _accentColor : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
