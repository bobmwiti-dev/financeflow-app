import 'package:flutter/material.dart';

/// A map of string keys to Material and Cupertino icons.
/// This allows storing an icon reference as a string in a database.
const Map<String, IconData> _iconMap = {
  'savings': Icons.savings,
  'car': Icons.directions_car,
  'house': Icons.house,
  'vacation': Icons.beach_access,
  'gift': Icons.card_giftcard,
  'education': Icons.school,
  'electronics': Icons.devices,
  'emergency': Icons.emergency,
  'other': Icons.category,
};

class IconDisplay extends StatelessWidget {
  final String? iconData;
  final double size;
  final Color? color;

  const IconDisplay({
    super.key,
    required this.iconData,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Look up the icon, provide a default if not found.
    final IconData icon = _iconMap[iconData?.toLowerCase()] ?? Icons.help_outline;

    return Icon(
      icon,
      size: size,
      color: color ?? Theme.of(context).iconTheme.color,
    );
  }
}

/// Returns the full list of available icon keys for selection.
List<String> getAvailableIconKeys() {
  return _iconMap.keys.toList();
}
