import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';

import '../../models/challenge_template_model.dart';
import '../../models/spending_challenge_model.dart';
import '../../viewmodels/challenge_view_model.dart';
import '../../themes/app_theme.dart';

class ChallengeTemplatesScreen extends StatefulWidget {
  const ChallengeTemplatesScreen({super.key});

  @override
  State<ChallengeTemplatesScreen> createState() => _ChallengeTemplatesScreenState();
}

class _ChallengeTemplatesScreenState extends State<ChallengeTemplatesScreen> {
  final Logger logger = Logger('ChallengeTemplatesScreen');
  
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Easy', 'Medium', 'Hard', 'No-Spend', 'Budget', 'Savings', 'Habits'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenge Templates'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filterOptions.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                        logger.info('Filter changed to: $filter');
                      },
                      selectedColor: AppTheme.primaryColor.withAlpha(50),
                      checkmarkColor: AppTheme.primaryColor,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          // Templates grid
          Expanded(
            child: _buildTemplatesGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatesGrid() {
    final filteredTemplates = _getFilteredTemplates();
    
    if (filteredTemplates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No templates found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filter',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: filteredTemplates.length,
      itemBuilder: (context, index) {
        final template = filteredTemplates[index];
        return _buildTemplateCard(template, index);
      },
    );
  }

  List<ChallengeTemplate> _getFilteredTemplates() {
    final allTemplates = ChallengeTemplates.templates;
    
    switch (_selectedFilter) {
      case 'Easy':
        return allTemplates.where((t) => t.difficulty == ChallengeDifficulty.easy).toList();
      case 'Medium':
        return allTemplates.where((t) => t.difficulty == ChallengeDifficulty.medium).toList();
      case 'Hard':
        return allTemplates.where((t) => t.difficulty == ChallengeDifficulty.hard).toList();
      case 'No-Spend':
        return allTemplates.where((t) => t.type == ChallengeType.noSpend).toList();
      case 'Budget':
        return allTemplates.where((t) => t.type == ChallengeType.budgetLimit).toList();
      case 'Savings':
        return allTemplates.where((t) => t.type == ChallengeType.savingsTarget).toList();
      case 'Habits':
        return allTemplates.where((t) => t.type == ChallengeType.habitBuilding).toList();
      default:
        return allTemplates;
    }
  }

  Widget _buildTemplateCard(ChallengeTemplate template, int index) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _showTemplateDetails(template),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                template.color.withAlpha(30),
                template.color.withAlpha(10),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon and difficulty
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: template.color.withAlpha(50),
                    child: Icon(
                      template.icon,
                      color: template.color,
                    ),
                  ),
                  _buildDifficultyChip(template.difficulty),
                ],
              ),
              const SizedBox(height: 12),
              
              // Title
              Text(
                template.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              
              // Description
              Expanded(
                child: Text(
                  template.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
              
              // Duration and type
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${template.defaultDurationDays} days',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(
                    _getTypeIcon(template.type),
                    size: 16,
                    color: template.color,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: const Duration(milliseconds: 300), delay: Duration(milliseconds: index * 100))
      .slideY(begin: 0.3, end: 0);
  }

  Widget _buildDifficultyChip(ChallengeDifficulty difficulty) {
    Color color;
    String text;
    
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        color = Colors.green;
        text = 'Easy';
        break;
      case ChallengeDifficulty.medium:
        color = Colors.orange;
        text = 'Medium';
        break;
      case ChallengeDifficulty.hard:
        color = Colors.red;
        text = 'Hard';
        break;
      case ChallengeDifficulty.expert:
        color = Colors.purple;
        text = 'Expert';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  IconData _getTypeIcon(ChallengeType type) {
    switch (type) {
      case ChallengeType.noSpend:
        return Icons.money_off;
      case ChallengeType.budgetLimit:
        return Icons.account_balance_wallet;
      case ChallengeType.savingsTarget:
        return Icons.savings;
      case ChallengeType.habitBuilding:
        return Icons.track_changes;
      case ChallengeType.custom:
        return Icons.star;
    }
  }

  void _showTemplateDetails(ChallengeTemplate template) {
    logger.info('Showing details for template: ${template.title}');
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: template.color.withAlpha(30),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: template.color.withAlpha(60),
                      child: Icon(
                        template.icon,
                        color: template.color,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            template.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildDifficultyChip(template.difficulty),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description
                      Text(
                        template.description,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Motivational quote
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: template.color.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: template.color.withAlpha(50),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.format_quote,
                              color: template.color,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                template.motivationalQuote,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  color: template.color,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Challenge details
                      _buildDetailRow('Duration', '${template.defaultDurationDays} days'),
                      if (template.suggestedTargetAmount != null)
                        _buildDetailRow('Suggested Amount', '\$${template.suggestedTargetAmount!.toStringAsFixed(2)}'),
                      if (template.categories.isNotEmpty)
                        _buildDetailRow('Categories', template.categories.join(', ')),
                      
                      const SizedBox(height: 20),
                      
                      // Tips
                      const Text(
                        'Tips for Success:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...template.tips.map((tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tip,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ),
              
              // Actions
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _useTemplate(template),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: template.color,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Use Template'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _useTemplate(ChallengeTemplate template) async {
    logger.info('Using template: ${template.title}');
    Navigator.of(context).pop(); // Close dialog
    
    try {
      // Create challenge from template
      final challenge = template.toChallenge();
      
      // Add to ViewModel
      final viewModel = Provider.of<ChallengeViewModel>(context, listen: false);
      await viewModel.addChallenge(challenge);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Challenge "${template.title}" created successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Navigate back to challenges screen
        Navigator.of(context).pop();
      }
    } catch (e) {
      logger.severe('Error creating challenge from template: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create challenge: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
