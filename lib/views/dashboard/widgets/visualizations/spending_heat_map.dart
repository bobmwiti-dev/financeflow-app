import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../services/spending_analytics_service.dart';
import '../../../../themes/app_theme.dart';

/// Types of heat maps available
enum HeatMapType {
  category,
  date,
  location,
}

/// A heat map visualization for spending data
class SpendingHeatMap extends StatefulWidget {
  final DateTimeRange period;
  final HeatMapType type;
  final String title;
  final Color baseColor;
  
  const SpendingHeatMap({
    required this.period,
    this.type = HeatMapType.category,
    this.title = 'Spending Heat Map',
    this.baseColor = AppTheme.accentColor,
    super.key,
  });
  
  @override
  State<SpendingHeatMap> createState() => _SpendingHeatMapState();
}

class _SpendingHeatMapState extends State<SpendingHeatMap> {
  late Future<Map<String, double>> _dataFuture;
  final SpendingAnalyticsService _service = SpendingAnalyticsService();
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  @override
  void didUpdateWidget(SpendingHeatMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.period != oldWidget.period || widget.type != oldWidget.type) {
      _loadData();
    }
  }
  
  void _loadData() {
    switch (widget.type) {
      case HeatMapType.category:
        _dataFuture = _service.getSpendingByCategory(widget.period);
        break;
      case HeatMapType.date:
        _dataFuture = _service.getSpendingByDate(widget.period)
            .then((data) => data.map((key, value) => MapEntry(key.toString(), value)));
        break;
      case HeatMapType.location:
        _dataFuture = _service.getSpendingByLocation();
        break;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            widget.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ).animate()
            .fadeIn(duration: const Duration(milliseconds: 700))
            .slideX(begin: -0.2, end: 0),
        ),
        FutureBuilder<Map<String, double>>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: SizedBox(
                  height: 200,
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }
            
            final data = snapshot.data!;
            if (data.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No data available for this period.'),
                ),
              );
            }
            
            final heatMapData = HeatMapData.fromMap(data);
            
            return _buildHeatMap(heatMapData);
          },
        ),
      ],
    );
  }
  
  Widget _buildHeatMap(HeatMapData data) {
    switch (widget.type) {
      case HeatMapType.category:
        return _buildCategoryHeatMap(data);
      case HeatMapType.date:
        return _buildDateHeatMap(data);
      case HeatMapType.location:
        return _buildLocationHeatMap(data);
    }
  }
  
  Widget _buildCategoryHeatMap(HeatMapData data) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
      itemCount: data.data.length,
      itemBuilder: (context, index) {
        final key = data.data.keys.elementAt(index);
        final value = data.data[key]!;
        final intensity = data.getIntensity(key);
        return GestureDetector(
          onTap: () {},
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: _buildHeatMapTile(key, value.toStringAsFixed(0), intensity),
            ),
          ),
        ).animate(delay: Duration(milliseconds: 80 * index))
          .fadeIn(duration: const Duration(milliseconds: 400))
          .slideY(begin: 0.2, end: 0);
      },
    );
  }
  
  Widget _buildDateHeatMap(HeatMapData data) {
    // Convert string dates back to DateTime for sorting
    final Map<DateTime, double> dateData = {};
    data.data.forEach((key, value) {
      try {
        final date = DateTime.parse(key);
        dateData[date] = value;
      } catch (e) {
        // Skip invalid dates
      }
    });
    
    // Sort dates
    final sortedDates = dateData.keys.toList()..sort();
    
    // Group by week for calendar-like view
    final List<List<DateTime?>> weeks = [];
    List<DateTime?> currentWeek = [];
    
    if (sortedDates.isEmpty) {
      return Center(
        child: Text('No date data available'),
      );
    }
    
    // Find the first day of the week for the first date
    final firstDate = sortedDates.first;
    final daysToSubtract = firstDate.weekday % 7; // 0 = Sunday, 6 = Saturday
    
    // Fill in nulls for days before the first date
    for (int i = 0; i < daysToSubtract; i++) {
      currentWeek.add(null);
    }
    
    // Add all dates, creating new weeks as needed
    for (final date in sortedDates) {
      int daysSinceWeekStart = (date.weekday % 7);
      if (currentWeek.length == 7) {
        weeks.add(currentWeek);
        currentWeek = [];
      }
      // If there are skipped days, fill with nulls
      if (currentWeek.isEmpty && daysSinceWeekStart > 0) {
        for (int i = 0; i < daysSinceWeekStart; i++) {
          currentWeek.add(null);
        }
      }
      currentWeek.add(date);
    }
    
    // Add the last week
    while (currentWeek.length < 7) {
      currentWeek.add(null);
    }
    if (currentWeek.isNotEmpty) {
      weeks.add(currentWeek);
    }
    
    return Column(
      children: [
        // Day labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const [
            Text('Sun', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            Text('Mon', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            Text('Tue', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            Text('Wed', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            Text('Thu', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            Text('Fri', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            Text('Sat', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        // Calendar grid
        Column(
          children: weeks.map((week) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: week.map((date) {
                if (date == null) {
                  return const SizedBox(
                    width: 40,
                    height: 40,
                  );
                }
                
                final dateStr = date.toString();
                final value = data.data[dateStr] ?? 0;
                final intensity = data.getIntensity(dateStr);
                
                return Tooltip(
                  message: '${date.month}/${date.day}: \$${value.toStringAsFixed(0)}',
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getHeatMapColor(intensity),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      date.day.toString(),
                      style: TextStyle(
                        color: intensity > 0.5 ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.0,
                      ),
                    ),
                  ),
                ).animate(delay: Duration(milliseconds: 30 * (week.indexOf(date) + weeks.indexOf(week) * 7)))
                  .fadeIn(duration: const Duration(milliseconds: 300));
              }).toList(),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: _getHeatMapColor(0),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Low', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 16),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: _getHeatMapColor(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Medium', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 16),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: _getHeatMapColor(1.0),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            const Text('High', style: TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }
  
  Widget _buildLocationHeatMap(HeatMapData data) {
    // For location, we'll use a simple list with color-coded bars
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.data.length,
      itemBuilder: (context, index) {
        final location = data.data.keys.elementAt(index);
        final value = data.data[location]!;
        final intensity = data.getIntensity(location);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  location,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                flex: 7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: intensity.toDouble(),
                        backgroundColor: Colors.grey.withValues(alpha: 30),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getHeatMapColor(intensity),
                        ),
                        minHeight: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${value.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate(delay: Duration(milliseconds: 50 * index))
          .fadeIn(duration: const Duration(milliseconds: 400))
          .slideX(begin: 0.1, end: 0);
      },
    );
  }
  
  Widget _buildHeatMapTile(String title, String value, double intensity) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getHeatMapColor(intensity),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 10),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              color: intensity > 0.5 ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '\$$value',
            style: TextStyle(
              color: intensity > 0.5 ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getHeatMapColor(double intensity) {
    // Create a color gradient from light to dark
    if (intensity <= 0) return Colors.grey.withAlpha(30);
    
    final Color baseColor = widget.baseColor;
    
    // For very low intensity, use a lighter version of the base color
    if (intensity < 0.2) {
      return baseColor.withAlpha((50 + intensity * 200).round());
    }
    
    // For medium to high intensity, adjust the color's brightness
    final HSLColor hsl = HSLColor.fromColor(baseColor);
    return hsl
        .withLightness((1 - intensity) * 0.6 + 0.2) // 0.8 to 0.2
        .withSaturation(0.5 + intensity * 0.5) // 0.5 to 1.0
        .toColor();
  }
}
