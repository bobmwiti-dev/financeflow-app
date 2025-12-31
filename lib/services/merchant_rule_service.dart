import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';

class MerchantRuleService {
  static final MerchantRuleService _instance = MerchantRuleService._internal();
  static MerchantRuleService get instance => _instance;
  factory MerchantRuleService() => _instance;

  MerchantRuleService._internal();

  final Logger _logger = Logger('MerchantRuleService');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _rulesCollection {
    final userId = _userId;
    return _firestore
        .collection('users')
        .doc(userId ?? 'unknown')
        .collection('merchant_rules');
  }

  String normalizeKey(String raw) {
    return raw
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<void> setCategoryRule({
    required String merchantKey,
    required String category,
  }) async {
    final userId = _userId;
    if (userId == null) {
      _logger.warning('No authenticated user; cannot save merchant rule');
      return;
    }

    final key = normalizeKey(merchantKey);
    if (key.isEmpty) return;

    try {
      await _rulesCollection.doc(key).set({
        'merchantKey': key,
        'category': category,
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));
    } catch (e) {
      _logger.warning('Failed to save merchant rule: $e');
    }
  }

  Future<String?> findCategoryForText(String text) async {
    final userId = _userId;
    if (userId == null) return null;

    final normalized = normalizeKey(text);
    if (normalized.isEmpty) return null;

    try {
      // Fast path: exact key match
      final exact = await _rulesCollection.doc(normalized).get();
      if (exact.exists) {
        final data = exact.data();
        final category = data?['category']?.toString();
        if (category != null && category.isNotEmpty) return category;
      }

      // Fallback: scan user rules (kept small) and do substring matching.
      final snapshot = await _rulesCollection.get();
      for (final doc in snapshot.docs) {
        final key = doc.id;
        if (key.isNotEmpty && normalized.contains(key)) {
          final category = doc.data()['category']?.toString();
          if (category != null && category.isNotEmpty) {
            return category;
          }
        }
      }

      return null;
    } catch (e) {
      _logger.warning('Failed to match merchant rule: $e');
      return null;
    }
  }
}
