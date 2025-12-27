import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/brand_logo.dart';

class CategoryIcons {
  // Helper method to detect brand names from bill titles
  static String _detectBrandFromTitle(String title) {
    final titleLower = title.toLowerCase();
    
    // Streaming services
    if (titleLower.contains('netflix')) return 'netflix';
    if (titleLower.contains('spotify')) return 'spotify';
    if (titleLower.contains('apple music') || titleLower.contains('apple tv') || titleLower.contains('apple')) return 'apple';
    if (titleLower.contains('youtube premium') || titleLower.contains('youtube music')) return 'youtube';
    if (titleLower.contains('disney+') || titleLower.contains('disney plus')) return 'disney';
    if (titleLower.contains('hulu')) return 'hulu';
    if (titleLower.contains('amazon prime')) return 'amazon';
    if (titleLower.contains('hbo max') || titleLower.contains('hbo')) return 'hbo';
    if (titleLower.contains('twitch')) return 'twitch';
    if (titleLower.contains('paramount+') || titleLower.contains('paramount plus')) return 'paramount';
    if (titleLower.contains('peacock')) return 'peacock';
    if (titleLower.contains('discovery+')) return 'discovery';
    if (titleLower.contains('tiktok')) return 'tiktok';
    if (titleLower.contains('instagram') || titleLower.contains('facebook') || titleLower.contains('meta')) return 'meta';
    
    // Cloud & productivity
    if (titleLower.contains('google drive') || titleLower.contains('google one')) return 'google';
    if (titleLower.contains('dropbox')) return 'dropbox';
    if (titleLower.contains('icloud')) return 'icloud';
    if (titleLower.contains('microsoft 365') || titleLower.contains('office 365')) return 'microsoft';
    if (titleLower.contains('adobe')) return 'adobe';
    if (titleLower.contains('zoom')) return 'zoom';
    if (titleLower.contains('slack')) return 'slack';
    if (titleLower.contains('notion')) return 'notion';
    if (titleLower.contains('figma')) return 'figma';
    
    // Utilities & ISPs
    if (titleLower.contains('comcast') || titleLower.contains('xfinity')) return 'comcast';
    if (titleLower.contains('verizon')) return 'verizon';
    if (titleLower.contains('at&t') || titleLower.contains('att')) return 'att';
    if (titleLower.contains('t-mobile')) return 't_mobile';
    if (titleLower.contains('sprint')) return 'sprint';
    
    // Food delivery
    if (titleLower.contains('uber eats')) return 'uber_eats';
    if (titleLower.contains('doordash')) return 'doordash';
    if (titleLower.contains('grubhub')) return 'grubhub';
    if (titleLower.contains('postmates')) return 'postmates';
    if (titleLower.contains('starbucks')) return 'starbucks';
    if (titleLower.contains('dunkin')) return 'dunkin';
    
    // Financial services
    if (titleLower.contains('paypal')) return 'paypal';
    if (titleLower.contains('venmo')) return 'venmo';
    if (titleLower.contains('cash app') || titleLower.contains('cashapp')) return 'cashapp';
    
    // Fitness
    if (titleLower.contains('planet fitness')) return 'planet_fitness';
    if (titleLower.contains('la fitness')) return 'la_fitness';
    if (titleLower.contains('24 hour fitness')) return '24_hour_fitness';
    
    return 'unknown';
  }

  // Get brand logo widget for bills and subscriptions
  static Widget getBrandWidget(String title, {double size = 24.0}) {
    final brand = _detectBrandFromTitle(title);
    
    // List of brands that have actual SVG logos
    const availableLogos = {
      'netflix', 'spotify', 'apple', 'youtube', 'google', 
      'amazon', 'paypal', 'starbucks'
    };
    
    if (availableLogos.contains(brand)) {
      return BrandLogo(
        brand: brand,
        size: size,
        fallbackIcon: getBrandIcon(title),
        fallbackColor: getBrandColor(title),
      );
    } else {
      // Fallback to icon for brands without SVG logos
      return Icon(
        getBrandIcon(title),
        size: size,
        color: getBrandColor(title),
      );
    }
  }

  // Get brand logo widget in a circle avatar
  static Widget getBrandCircleWidget(String title, {double size = 40.0}) {
    final brand = _detectBrandFromTitle(title);
    const availableLogos = {'netflix', 'spotify', 'apple', 'youtube', 'google', 'amazon', 'paypal', 'starbucks'};
    
    // Force brand detection for testing
    if (title.toLowerCase().contains('netflix')) {
      return BrandLogoCircle(
        brand: 'netflix',
        size: size,
        backgroundColor: const Color(0xFFE50914).withValues(alpha: 0.1),
        fallbackIcon: Bootstrap.play_circle_fill,
        fallbackColor: const Color(0xFFE50914),
      );
    }
    
    if (title.toLowerCase().contains('spotify')) {
      return BrandLogoCircle(
        brand: 'spotify',
        size: size,
        backgroundColor: const Color(0xFF1DB954).withValues(alpha: 0.1),
        fallbackIcon: Bootstrap.music_note_beamed,
        fallbackColor: const Color(0xFF1DB954),
      );
    }
    
    if (title.toLowerCase().contains('apple')) {
      return BrandLogoCircle(
        brand: 'apple',
        size: size,
        backgroundColor: const Color(0xFF007AFF).withValues(alpha: 0.1),
        fallbackIcon: Bootstrap.apple,
        fallbackColor: const Color(0xFF007AFF),
      );
    }
    
    if (availableLogos.contains(brand)) {
      return BrandLogoCircle(
        brand: brand,
        size: size,
        backgroundColor: getBrandColor(title).withValues(alpha:0.1),
        fallbackIcon: getBrandIcon(title),
        fallbackColor: getBrandColor(title),
      );
    } else {
      // Fallback to circle avatar with icon
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: getBrandColor(title).withValues(alpha:0.1),
        child: Icon(
          getBrandIcon(title),
          size: size * 0.6,
          color: getBrandColor(title),
        ),
      );
    }
  }

  // Get brand-specific icon for bills and subscriptions (fallback)
  static IconData getBrandIcon(String title) {
    final brand = _detectBrandFromTitle(title);
    
    switch (brand) {
      // Streaming Services - Real Brand Icons
      case 'netflix': return Bootstrap.play_circle_fill; // Netflix-style icon
      case 'spotify': return Bootstrap.music_note_beamed; // Spotify-style music icon
      case 'apple': return Bootstrap.apple; // Apple icon
      case 'youtube': return Bootstrap.play_btn_fill; // YouTube-style play icon
      case 'disney': return Bootstrap.play_circle; // Disney+ style
      case 'hulu': return Bootstrap.play_btn; // Hulu style
      case 'amazon': return Bootstrap.cart3; // Amazon shopping icon
      case 'hbo': return Bootstrap.film; // HBO style
      case 'twitch': return Bootstrap.camera_video; // Gaming/streaming icon
      case 'tiktok': return Bootstrap.camera_reels; // TikTok-style reels icon
      case 'meta': return Bootstrap.facebook; // Meta/Facebook icon
      case 'paramount': return Bootstrap.play_circle;
      case 'peacock': return Bootstrap.play_circle;
      case 'discovery': return Bootstrap.play_circle;
      
      // Cloud & Productivity
      case 'google': return Bootstrap.google; // Google icon
      case 'dropbox': return Bootstrap.dropbox; // Dropbox icon
      case 'icloud': return Bootstrap.cloud; // iCloud icon
      case 'microsoft': return Bootstrap.microsoft; // Microsoft icon
      case 'adobe': return Bootstrap.palette; // Adobe Creative icon
      case 'zoom': return Bootstrap.camera_video; // Zoom icon
      case 'slack': return Bootstrap.slack; // Slack icon
      case 'notion': return Bootstrap.journal_text; // Notion-style icon
      case 'figma': return Bootstrap.palette;
      
      // Utilities & ISPs
      case 'comcast': return Bootstrap.wifi;
      case 'verizon': return Bootstrap.phone;
      case 'att': return Bootstrap.phone;
      case 't_mobile': return Bootstrap.phone;
      case 'sprint': return Bootstrap.phone;
      
      // Food Delivery
      case 'uber_eats': return Bootstrap.car_front; // Uber delivery
      case 'doordash': return Bootstrap.bag; // DoorDash delivery
      case 'grubhub': return Bootstrap.bag;
      case 'postmates': return Bootstrap.bag;
      case 'starbucks': return Bootstrap.cup_hot; // Starbucks coffee
      case 'dunkin': return Bootstrap.cup_hot;
      
      // Financial Services
      case 'paypal': return Bootstrap.paypal; // PayPal icon
      case 'venmo': return Bootstrap.credit_card; // Venmo payment
      case 'cashapp': return Bootstrap.cash_stack;
      
      // Fitness
      case 'planet_fitness': return Bootstrap.heart_pulse; // Fitness icon
      case 'la_fitness': return Bootstrap.heart_pulse;
      case '24_hour_fitness': return Bootstrap.heart_pulse;
      
      default: return getIconForCategory(title); // Fallback to category-based
    }
  }

  // Get brand-specific color for bills and subscriptions
  static Color getBrandColor(String title) {
    final brand = _detectBrandFromTitle(title);
    
    switch (brand) {
      // Streaming Services
      case 'netflix': return const Color(0xFFE50914); // Netflix red
      case 'spotify': return const Color(0xFF1DB954); // Spotify green
      case 'apple': return const Color(0xFF007AFF); // Apple blue
      case 'youtube': return const Color(0xFFFF0000); // YouTube red
      case 'disney': return const Color(0xFF113CCF); // Disney blue
      case 'hulu': return const Color(0xFF1CE783); // Hulu green
      case 'amazon': return const Color(0xFFFF9900); // Amazon orange
      case 'hbo': return const Color(0xFF7B2CBF); // HBO purple
      case 'twitch': return const Color(0xFF9146FF); // Twitch purple
      case 'tiktok': return const Color(0xFF000000); // TikTok black
      case 'meta': return const Color(0xFF1877F2); // Meta blue
      case 'paramount': return const Color(0xFF0064FF); // Paramount blue
      case 'peacock': return const Color(0xFF000000); // Peacock black
      case 'discovery': return const Color(0xFF0077C8); // Discovery blue
      
      // Cloud & Productivity
      case 'google': return const Color(0xFF4285F4); // Google blue
      case 'dropbox': return const Color(0xFF0061FF); // Dropbox blue
      case 'icloud': return const Color(0xFF007AFF); // Apple blue
      case 'microsoft': return const Color(0xFF00BCF2); // Microsoft blue
      case 'adobe': return const Color(0xFFFF0000); // Adobe red
      case 'zoom': return const Color(0xFF2D8CFF); // Zoom blue
      case 'slack': return const Color(0xFF4A154B); // Slack purple
      case 'notion': return const Color(0xFF000000); // Notion black
      case 'figma': return const Color(0xFFF24E1E); // Figma orange
      
      // Utilities & ISPs
      case 'comcast': return const Color(0xFF000000); // Comcast black
      case 'verizon': return const Color(0xFFCD040B); // Verizon red
      case 'att': return const Color(0xFF00A8E0); // AT&T blue
      case 't_mobile': return const Color(0xFFE20074); // T-Mobile magenta
      case 'sprint': return const Color(0xFFFFD100); // Sprint yellow
      
      // Food Delivery
      case 'uber_eats': return const Color(0xFF000000); // Uber black
      case 'doordash': return const Color(0xFFFF3008); // DoorDash red
      case 'grubhub': return const Color(0xFFF63440); // GrubHub red
      case 'postmates': return const Color(0xFF000000); // Postmates black
      case 'starbucks': return const Color(0xFF00704A); // Starbucks green
      case 'dunkin': return const Color(0xFFFF6600); // Dunkin orange
      
      // Financial Services
      case 'paypal': return const Color(0xFF003087); // PayPal blue
      case 'venmo': return const Color(0xFF3D95CE); // Venmo blue
      case 'cashapp': return const Color(0xFF00D632); // Cash App green
      
      // Fitness
      case 'planet_fitness': return const Color(0xFF7B2CBF); // Planet Fitness purple
      case 'la_fitness': return const Color(0xFF0066CC); // LA Fitness blue
      case '24_hour_fitness': return const Color(0xFFFF6600); // 24 Hour Fitness orange
      
      default: return getColorForCategory(title); // Fallback to category-based
    }
  }

  static IconData getIconForCategory(String category) {
    final categoryLower = category.toLowerCase();
    final titleLower = category.toLowerCase();
    
    // === STREAMING SERVICES ===
    if (titleLower.contains('netflix')) {
      return Icons.play_circle_filled; // Netflix-style play icon
    }
    if (titleLower.contains('spotify') || titleLower.contains('apple music') || 
        titleLower.contains('youtube music') || titleLower.contains('amazon music')) {
      return Icons.music_note; // Music streaming
    }
    if (titleLower.contains('youtube') && titleLower.contains('premium')) {
      return Icons.play_arrow; // YouTube Premium
    }
    if (titleLower.contains('disney') || titleLower.contains('hulu') || 
        titleLower.contains('amazon prime') || titleLower.contains('hbo')) {
      return Icons.tv; // Video streaming
    }
    if (titleLower.contains('twitch')) {
      return Icons.videogame_asset; // Gaming/streaming
    }
    
    // === CLOUD & PRODUCTIVITY ===
    if (titleLower.contains('google') && (titleLower.contains('drive') || 
        titleLower.contains('storage') || titleLower.contains('one'))) {
      return Icons.cloud; // Google Drive/One
    }
    if (titleLower.contains('dropbox') || titleLower.contains('icloud')) {
      return Icons.cloud_upload; // Cloud storage
    }
    if (titleLower.contains('microsoft') && titleLower.contains('365')) {
      return Icons.work_outline; // Office 365
    }
    if (titleLower.contains('adobe') || titleLower.contains('photoshop') || 
        titleLower.contains('creative')) {
      return Icons.design_services; // Adobe Creative
    }
    if (titleLower.contains('zoom') || titleLower.contains('teams') || 
        titleLower.contains('slack')) {
      return Icons.video_call; // Communication tools
    }
    
    // === UTILITIES & SERVICES ===
    if (titleLower.contains('electric') || titleLower.contains('power') || 
        titleLower.contains('energy')) {
      return Icons.flash_on; // Electricity
    }
    if (titleLower.contains('water') || titleLower.contains('sewer')) {
      return Icons.water_drop; // Water utility
    }
    if (titleLower.contains('gas') && (titleLower.contains('natural') || 
        titleLower.contains('heating'))) {
      return Icons.local_fire_department; // Natural gas
    }
    if (titleLower.contains('internet') || titleLower.contains('wifi') || 
        titleLower.contains('broadband') || titleLower.contains('comcast') || 
        titleLower.contains('verizon') || titleLower.contains('att')) {
      return Icons.wifi; // Internet/WiFi
    }
    if (titleLower.contains('phone') || titleLower.contains('mobile') || 
        titleLower.contains('cellular') || titleLower.contains('t-mobile')) {
      return Icons.phone_android; // Mobile phone
    }
    if (titleLower.contains('insurance') && titleLower.contains('car')) {
      return Icons.car_crash; // Car insurance
    }
    if (titleLower.contains('insurance') && (titleLower.contains('health') || 
        titleLower.contains('medical'))) {
      return Icons.health_and_safety; // Health insurance
    }
    if (titleLower.contains('insurance')) {
      return Icons.security; // General insurance
    }
    
    // === FINANCIAL SERVICES ===
    if (titleLower.contains('bank') || titleLower.contains('credit card') || 
        titleLower.contains('loan') || titleLower.contains('mortgage')) {
      return Icons.account_balance; // Banking
    }
    if (titleLower.contains('paypal') || titleLower.contains('venmo') || 
        titleLower.contains('cashapp')) {
      return Icons.payment; // Payment services
    }
    
    // === FOOD DELIVERY & SERVICES ===
    if (titleLower.contains('uber eats') || titleLower.contains('doordash') || 
        titleLower.contains('grubhub') || titleLower.contains('postmates')) {
      return Icons.delivery_dining; // Food delivery
    }
    if (titleLower.contains('starbucks') || titleLower.contains('dunkin')) {
      return Icons.local_cafe; // Coffee shops
    }
    
    // === FITNESS & WELLNESS ===
    if (titleLower.contains('gym') || titleLower.contains('fitness') || 
        titleLower.contains('planet fitness') || titleLower.contains('la fitness')) {
      return Icons.fitness_center; // Gym membership
    }
    if (titleLower.contains('yoga') || titleLower.contains('meditation') || 
        titleLower.contains('headspace') || titleLower.contains('calm')) {
      return Icons.self_improvement; // Wellness apps
    }
    
    // === TRANSPORTATION SERVICES ===
    if (titleLower.contains('uber') && !titleLower.contains('eats')) {
      return Icons.local_taxi; // Uber rides
    }
    if (titleLower.contains('lyft')) {
      return Icons.local_taxi; // Lyft
    }
    if (titleLower.contains('parking')) {
      return Icons.local_parking; // Parking
    }
    
    // === GENERAL CATEGORIES (Enhanced with Modern Icons) ===
    
    // Food & Dining - Using FontAwesome for modern look
    if (categoryLower.contains('food') || 
        categoryLower.contains('restaurant') || 
        categoryLower.contains('dining') ||
        categoryLower.contains('lunch') ||
        categoryLower.contains('dinner') ||
        categoryLower.contains('breakfast')) {
      return FontAwesomeIcons.utensils; // Modern restaurant icon
    }
    
    // Coffee & Cafe - Special coffee icon
    if (categoryLower.contains('coffee') ||
        categoryLower.contains('cafe') ||
        categoryLower.contains('starbucks') ||
        categoryLower.contains('dunkin')) {
      return FontAwesomeIcons.mugHot; // Dedicated coffee icon
    }
    
    // Transportation - Using FontAwesome for clean look
    if (categoryLower.contains('transport') || 
        categoryLower.contains('bus') ||
        categoryLower.contains('train') ||
        categoryLower.contains('car')) {
      return FontAwesomeIcons.car; // Modern transport icon
    }
    
    // Gas & Fuel - Special fuel icon
    if (categoryLower.contains('gas') || 
        categoryLower.contains('fuel')) {
      return FontAwesomeIcons.gasPump; // Dedicated fuel icon
    }
    
    // Shopping - Enhanced shopping icons
    if (categoryLower.contains('shopping') || 
        categoryLower.contains('retail') || 
        categoryLower.contains('store') ||
        categoryLower.contains('amazon') ||
        categoryLower.contains('walmart') ||
        categoryLower.contains('target')) {
      return FontAwesomeIcons.bagShopping; // Modern shopping bag
    }
    
    // Groceries - Dedicated grocery icon
    if (categoryLower.contains('grocery') || 
        categoryLower.contains('groceries') || 
        categoryLower.contains('supermarket')) {
      return FontAwesomeIcons.cartShopping; // Shopping cart for groceries
    }
    
    // Entertainment - Modern entertainment icons
    if (categoryLower.contains('entertainment') || 
        categoryLower.contains('movie') || 
        categoryLower.contains('cinema')) {
      return FontAwesomeIcons.film; // Modern film icon
    }
    
    // Gaming
    if (categoryLower.contains('game') ||
        categoryLower.contains('gaming')) {
      return FontAwesomeIcons.gamepad; // Gaming controller
    }
    
    // Health & Medical - Enhanced medical icons
    if (categoryLower.contains('health') || 
        categoryLower.contains('medical') || 
        categoryLower.contains('doctor') ||
        categoryLower.contains('hospital')) {
      return FontAwesomeIcons.heartPulse; // Heart for health
    }
    
    // Pharmacy
    if (categoryLower.contains('pharmacy') ||
        categoryLower.contains('medicine') ||
        categoryLower.contains('drug')) {
      return FontAwesomeIcons.pills; // Pill icon for pharmacy
    }
    
    // Bills & Utilities - Modern utility icons
    if (categoryLower.contains('bill') || 
        categoryLower.contains('utility')) {
      return FontAwesomeIcons.receipt; // Clean receipt icon
    }
    
    // Education - Enhanced education icons
    if (categoryLower.contains('education') || 
        categoryLower.contains('school') || 
        categoryLower.contains('tuition') ||
        categoryLower.contains('course')) {
      return FontAwesomeIcons.graduationCap; // Graduation cap
    }
    
    // Books
    if (categoryLower.contains('book') ||
        categoryLower.contains('library')) {
      return FontAwesomeIcons.book; // Book icon
    }
    
    // Travel - Modern travel icons
    if (categoryLower.contains('travel') || 
        categoryLower.contains('vacation')) {
      return FontAwesomeIcons.plane; // Airplane for travel
    }
    
    // Hotel
    if (categoryLower.contains('hotel') ||
        categoryLower.contains('accommodation')) {
      return FontAwesomeIcons.bed; // Bed for hotels
    }
    
    // Income - Professional work icons
    if (categoryLower.contains('salary') || 
        categoryLower.contains('income') || 
        categoryLower.contains('wage') ||
        categoryLower.contains('bonus')) {
      return FontAwesomeIcons.briefcase; // Briefcase for work
    }
    
    // Freelance
    if (categoryLower.contains('freelance') ||
        categoryLower.contains('contract')) {
      return FontAwesomeIcons.laptop; // Laptop for freelance
    }
    
    // Investment - Modern finance icons
    if (categoryLower.contains('investment') || 
        categoryLower.contains('stock') || 
        categoryLower.contains('dividend')) {
      return FontAwesomeIcons.chartLine; // Trending up for investments
    }
    
    // Crypto
    if (categoryLower.contains('crypto') ||
        categoryLower.contains('bitcoin') ||
        categoryLower.contains('ethereum')) {
      return FontAwesomeIcons.bitcoin; // Bitcoin icon
    }
    
    // Subscription - Modern subscription icon
    if (categoryLower.contains('subscription') || 
        categoryLower.contains('monthly') || 
        categoryLower.contains('recurring')) {
      return FontAwesomeIcons.repeat; // Repeat for recurring
    }
    
    // Personal Care
    if (categoryLower.contains('personal care') ||
        categoryLower.contains('beauty') ||
        categoryLower.contains('salon')) {
      return FontAwesomeIcons.scissors; // Scissors for salon/beauty
    }
    
    // Fitness & Gym
    if (categoryLower.contains('fitness') ||
        categoryLower.contains('gym') ||
        categoryLower.contains('workout')) {
      return FontAwesomeIcons.dumbbell; // Dumbbell for fitness
    }
    
    // Pet Care
    if (categoryLower.contains('pet') ||
        categoryLower.contains('veterinary') ||
        categoryLower.contains('animal')) {
      return FontAwesomeIcons.paw; // Paw for pet care
    }
    
    // Home & Garden
    if (categoryLower.contains('home') ||
        categoryLower.contains('garden') ||
        categoryLower.contains('hardware')) {
      return FontAwesomeIcons.house; // Home icon
    }
    
    // Default icon - Modern wallet
    return FontAwesomeIcons.wallet;
  }
  
  static Color getColorForCategory(String category) {
    final categoryLower = category.toLowerCase();
    final titleLower = category.toLowerCase();
    
    // === BRAND-SPECIFIC COLORS ===
    
    // Streaming Services
    if (titleLower.contains('netflix')) {
      return const Color(0xFFE50914); // Netflix red
    }
    if (titleLower.contains('spotify')) {
      return const Color(0xFF1DB954); // Spotify green
    }
    if (titleLower.contains('apple music')) {
      return const Color(0xFFFA233B); // Apple red
    }
    if (titleLower.contains('youtube')) {
      return const Color(0xFFFF0000); // YouTube red
    }
    if (titleLower.contains('disney')) {
      return const Color(0xFF113CCF); // Disney blue
    }
    if (titleLower.contains('hulu')) {
      return const Color(0xFF1CE783); // Hulu green
    }
    if (titleLower.contains('amazon prime')) {
      return const Color(0xFF00A8E1); // Amazon blue
    }
    if (titleLower.contains('hbo')) {
      return const Color(0xFF7B2CBF); // HBO purple
    }
    if (titleLower.contains('twitch')) {
      return const Color(0xFF9146FF); // Twitch purple
    }
    
    // Cloud & Productivity
    if (titleLower.contains('google')) {
      return const Color(0xFF4285F4); // Google blue
    }
    if (titleLower.contains('dropbox')) {
      return const Color(0xFF0061FF); // Dropbox blue
    }
    if (titleLower.contains('icloud')) {
      return const Color(0xFF007AFF); // Apple blue
    }
    if (titleLower.contains('microsoft')) {
      return const Color(0xFF00BCF2); // Microsoft blue
    }
    if (titleLower.contains('adobe')) {
      return const Color(0xFFFF0000); // Adobe red
    }
    if (titleLower.contains('zoom')) {
      return const Color(0xFF2D8CFF); // Zoom blue
    }
    if (titleLower.contains('slack')) {
      return const Color(0xFF4A154B); // Slack purple
    }
    
    // Utilities & ISPs
    if (titleLower.contains('comcast') || titleLower.contains('xfinity')) {
      return const Color(0xFF000000); // Comcast black
    }
    if (titleLower.contains('verizon')) {
      return const Color(0xFFCD040B); // Verizon red
    }
    if (titleLower.contains('att')) {
      return const Color(0xFF00A8E0); // AT&T blue
    }
    if (titleLower.contains('t-mobile')) {
      return const Color(0xFFE20074); // T-Mobile magenta
    }
    
    // Food Delivery
    if (titleLower.contains('uber eats')) {
      return const Color(0xFF000000); // Uber black
    }
    if (titleLower.contains('doordash')) {
      return const Color(0xFFFF3008); // DoorDash red
    }
    if (titleLower.contains('grubhub')) {
      return const Color(0xFFF63440); // GrubHub red
    }
    if (titleLower.contains('starbucks')) {
      return const Color(0xFF00704A); // Starbucks green
    }
    
    // Financial Services
    if (titleLower.contains('paypal')) {
      return const Color(0xFF003087); // PayPal blue
    }
    if (titleLower.contains('venmo')) {
      return const Color(0xFF3D95CE); // Venmo blue
    }
    if (titleLower.contains('cashapp')) {
      return const Color(0xFF00D632); // Cash App green
    }
    
    // Fitness
    if (titleLower.contains('planet fitness')) {
      return const Color(0xFF7B2CBF); // Planet Fitness purple
    }
    
    // === CATEGORY-BASED COLORS (FALLBACK) ===
    
    // Food & Dining - Orange
    if (categoryLower.contains('food') || 
        categoryLower.contains('restaurant') || 
        categoryLower.contains('dining') ||
        categoryLower.contains('coffee') ||
        categoryLower.contains('cafe')) {
      return Colors.orange;
    }
    
    // Transportation - Blue
    if (categoryLower.contains('transport') || 
        categoryLower.contains('gas') || 
        categoryLower.contains('fuel') ||
        categoryLower.contains('uber') ||
        categoryLower.contains('taxi')) {
      return Colors.blue;
    }
    
    // Shopping - Purple
    if (categoryLower.contains('shopping') || 
        categoryLower.contains('retail') || 
        categoryLower.contains('store')) {
      return Colors.purple;
    }
    
    // Groceries - Green
    if (categoryLower.contains('grocery') || 
        categoryLower.contains('groceries')) {
      return Colors.green;
    }
    
    // Entertainment - Pink
    if (categoryLower.contains('entertainment') || 
        categoryLower.contains('movie') || 
        categoryLower.contains('cinema') ||
        categoryLower.contains('game')) {
      return Colors.pink;
    }
    
    // Health - Red
    if (categoryLower.contains('health') || 
        categoryLower.contains('medical')) {
      return Colors.red;
    }
    
    // Bills - Brown
    if (categoryLower.contains('bill') || 
        categoryLower.contains('utility')) {
      return Colors.brown;
    }
    
    // Income - Green
    if (categoryLower.contains('salary') || 
        categoryLower.contains('income')) {
      return Colors.green;
    }
    
    // Default color
    return Colors.grey;
  }
}
