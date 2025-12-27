/// Enum defining the various chart types available for financial data visualization
enum ChartType {
  pie,
  bar,
  line,
  area,
  donut,
  scatter,
  radar,
  heatmap,
  candlestick;
  
  /// Returns a user-friendly name for the chart type
  String get displayName {
    switch (this) {
      case ChartType.pie:
        return 'Pie Chart';
      case ChartType.bar:
        return 'Bar Chart';
      case ChartType.line:
        return 'Line Chart';
      case ChartType.area:
        return 'Area Chart';
      case ChartType.donut:
        return 'Donut Chart';
      case ChartType.scatter:
        return 'Scatter Plot';
      case ChartType.radar:
        return 'Radar Chart';
      case ChartType.heatmap:
        return 'Heat Map';
      case ChartType.candlestick:
        return 'Candlestick Chart';
    }
  }
}
