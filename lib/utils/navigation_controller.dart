import 'package:flutter/material.dart';
import '../utils/page_transitions.dart';
import '../utils/flip_page_transition.dart' as flip;
import '../utils/bouncy_page_transition.dart';
import '../utils/smooth_slide_transition.dart';

/// A controller class to handle app navigation with enhanced transitions
class NavigationController {
  /// Navigate with a fade scale transition
  static Future<T?> navigateWithFadeScale<T>(BuildContext context, Widget page) {
    return Navigator.of(context).push<T>(
      PageTransitions.fadeScaleTransition<T>(page),
    );
  }

  /// Navigate with a vertical slide transition
  static Future<T?> navigateWithVerticalSlide<T>(BuildContext context, Widget page) {
    return Navigator.of(context).push<T>(
      PageTransitions.slideUpTransition<T>(page),
    );
  }

  /// Navigate with a slide transition
  static Future<T?> navigateWithSlide<T>(BuildContext context, Widget page) {
    return Navigator.of(context).push<T>(
      PageTransitions.slideTransition<T>(page),
    );
  }

  /// Navigate with a circular reveal transition
  static Future<T?> navigateWithCircularReveal<T>(
    BuildContext context, 
    Widget page, {
    Alignment alignment = Alignment.center,
  }) {
    return Navigator.of(context).push<T>(
      PageTransitions.circularRevealTransition<T>(
        page,
        alignment: alignment,
      ),
    );
  }

  /// Navigate with a 3D flip transition
  static Future<T?> navigateWithFlip<T>(
    BuildContext context, 
    Widget page, {
    flip.FlipDirection direction = flip.FlipDirection.horizontal,
  }) {
    return Navigator.of(context).push<T>(
      flip.FlipPageTransition<T>(
        page: page,
        direction: direction,
      ),
    );
  }

  /// Navigate with a bouncy transition
  static Future<T?> navigateWithBouncy<T>(BuildContext context, Widget page) {
    return Navigator.of(context).push<T>(
      BouncyPageTransition<T>(
        page: page,
      ),
    );
  }
  
  /// Navigate with a smooth slide transition
  static Future<T?> navigateWithSmoothSlide<T>(
    BuildContext context, 
    Widget page, {
    SlideDirection direction = SlideDirection.rightToLeft,
  }) {
    return Navigator.of(context).push<T>(
      SmoothSlideTransition<T>(
        page: page,
        direction: direction,
      ),
    );
  }

  /// Create a named route with transition based on route settings
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Extract route name
    final routeName = settings.name;

    // Define transitions for different routes
    // Add case statements for each route in your app
    switch (routeName) {
      // Actual routes for FinanceFlow app:
      case '/dashboard':
        return PageTransitions.fadeScaleTransition(
          const DashboardScreenPlaceholder(),
        );
      case '/insights':
        return PageTransitions.circularRevealTransition(
          const InsightsScreenPlaceholder(),
        );
      case '/settings':
        return PageTransitions.slideUpTransition(
          const SettingsScreenPlaceholder(),
        );
      case '/accounts':
        return BouncyPageTransition<dynamic>(
          page: const AccountsScreenPlaceholder(),
        );
      case '/transactions':
        return SmoothSlideTransition<dynamic>(
          page: const TransactionsScreenPlaceholder(),
          direction: SlideDirection.rightToLeft,
        );
      default:
        // Default transition for unknown routes
        return PageTransitions.fadeScaleTransition(
          const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }
}

// These are placeholder classes - in a real implementation, these
// would be replaced with imports to your actual screen widgets
class DashboardScreenPlaceholder extends StatelessWidget {
  const DashboardScreenPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Dashboard')));
}

class InsightsScreenPlaceholder extends StatelessWidget {
  const InsightsScreenPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Insights')));
}

class SettingsScreenPlaceholder extends StatelessWidget {
  const SettingsScreenPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Settings')));
}

class AccountsScreenPlaceholder extends StatelessWidget {
  const AccountsScreenPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Accounts')));
}

class TransactionsScreenPlaceholder extends StatelessWidget {
  const TransactionsScreenPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Transactions')));
}

/// Usage example:
/// ```dart
/// ElevatedButton(
///   onPressed: () {
///     NavigationController.navigateWithFlip(
///       context, 
///       const SettingsScreen(),
///       direction: FlipDirection.vertical,
///     );
///   },
///   child: const Text('Go to Settings'),
/// )
/// ```
