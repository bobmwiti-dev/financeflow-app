import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/enhanced_animations.dart';
import '../themes/app_theme.dart';

/// A beautiful animated card for displaying financial information
/// with modern animations and interactive effects
class AnimatedFinancialCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String amount;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool isImportant;
  final int animationIndex;

  const AnimatedFinancialCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.amount,
    required this.icon,
    required this.color,
    this.onTap,
    this.isImportant = false,
    this.animationIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final Widget cardContent = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).cardColor,
            color.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle != null) ...[  
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
            ],
          ),
        ],
      ),
    );

    Widget animatedCard = EnhancedAnimations.cardEntrance(
      cardContent,
      index: animationIndex,
    );

    // Apply breathing effect for important cards
    if (isImportant) {
      animatedCard = EnhancedAnimations.breathingAnimation(
        animatedCard,
        glowColor: color,
      );
    }

    // Apply tap/hover effects if the card is interactive
    return onTap != null
        ? EnhancedAnimations.scaleOnTap(
            child: animatedCard,
            onTap: onTap!,
          )
        : animatedCard;
  }
}

/// A grid of animated financial cards
class AnimatedFinancialCardGrid extends StatelessWidget {
  final List<AnimatedFinancialCard> cards;
  final int crossAxisCount;
  final double spacing;

  const AnimatedFinancialCardGrid({
    super.key,
    required this.cards,
    this.crossAxisCount = 2,
    this.spacing = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: 1.4,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) => cards[index],
    );
  }
}

/// A premium financial summary card with animated elements
class PremiumFinancialSummaryCard extends StatelessWidget {
  final String title;
  final String totalAmount;
  final String periodText;
  final List<FinancialDataPoint> dataPoints;
  final VoidCallback? onViewDetails;
  final int animationDelay;

  const PremiumFinancialSummaryCard({
    super.key,
    required this.title,
    required this.totalAmount,
    required this.periodText,
    required this.dataPoints,
    this.onViewDetails,
    this.animationDelay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                periodText,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            totalAmount,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          )
              .animate(delay: Duration(milliseconds: 100 + animationDelay))
              .fadeIn(duration: const Duration(milliseconds: 600))
              .slideY(begin: 0.2, end: 0),
          const SizedBox(height: 24),
          ...List.generate(
            dataPoints.length,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: dataPoints[index].color,
                      shape: BoxShape.circle,
                    ),
                  )
                      .animate(
                        delay: Duration(
                          milliseconds: 200 + animationDelay + (index * 100),
                        ),
                      )
                      .scale(
                        begin: const Offset(0, 0),
                        end: const Offset(1, 1),
                        curve: Curves.elasticOut
                      ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dataPoints[index].label,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dataPoints[index].value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
                  .animate(
                    delay: Duration(
                      milliseconds: 300 + animationDelay + (index * 100),
                    ),
                  )
                  .fadeIn()
                  .slideX(begin: 0.2, end: 0),
            ),
          ),
          if (onViewDetails != null) ...[  
            const SizedBox(height: 16),
            TextButton(
              onPressed: onViewDetails,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View Details',
                    style: TextStyle(color: AppTheme.accentColor),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: AppTheme.accentColor,
                  ),
                ],
              ),
            )
                .animate(
                  delay: Duration(
                    milliseconds: 400 + animationDelay + (dataPoints.length * 100),
                  ),
                )
                .fadeIn()
                .slideY(begin: 0.5, end: 0),
          ],
        ],
      ),
    );
  }
}

/// Data point for financial summary cards
class FinancialDataPoint {
  final String label;
  final String value;
  final Color color;

  FinancialDataPoint({
    required this.label,
    required this.value,
    required this.color,
  });
}
