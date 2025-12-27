import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:financeflow_app/models/family_member_model.dart';
import 'package:financeflow_app/viewmodels/family_viewmodel.dart';

class RoleBudgetDistribution extends StatelessWidget {
  const RoleBudgetDistribution({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<FamilyViewModel>(context);
    
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final data = _calculateRoleBudgets(viewModel.familyMembers);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Role Budget Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: data.map((roleData) => PieChartSectionData(
                  title: '${roleData['name']}\n\$${roleData['budget'].toStringAsFixed(0)}',
                  value: roleData['budget'],
                  color: _getRoleColor(roleData['role']),
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  radius: 120,
                  titlePositionPercentageOffset: 0.55,
                )).toList(),
                centerSpaceRadius: 40,
                sectionsSpace: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _calculateRoleBudgets(List<FamilyMember> members) {
    final Map<FamilyRole, double> roleBudgets = {};
    
    // Calculate total budget per role
    for (final member in members) {
      roleBudgets.update(
        member.role,
        (value) => value + member.budget,
        ifAbsent: () => member.budget,
      );
    }

    // Create data objects for each role with aggregated budget
    return roleBudgets.entries.map((entry) => {
      'role': entry.key,
      'name': FamilyMember.roleDisplayNames[entry.key] ?? 'Unknown',
      'budget': entry.value,
    }).toList();
  }
  
  Color _getRoleColor(FamilyRole role) {
    switch (role) {
      case FamilyRole.parent:
        return Colors.blue;
      case FamilyRole.child:
        return Colors.orange;
      case FamilyRole.teen:
        return Colors.green;
      case FamilyRole.guardian:
        return Colors.purple;
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}
