import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/spending_challenge_model.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';

class ChallengeViewModel extends ChangeNotifier {
  final Logger _logger = Logger('ChallengeViewModel');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TransactionService _transactionService = TransactionService.instance;

  ChallengeViewModel() {
    _initializeViewModel();
  }

  List<SpendingChallenge> _challenges = [];
  List<SpendingChallenge> get challenges => _challenges;
  
  List<SpendingChallenge> get activeChallenges => 
      _challenges.where((c) => c.status == ChallengeStatus.active).toList();
  
  List<SpendingChallenge> get completedChallenges => 
      _challenges.where((c) => c.status == ChallengeStatus.completed || c.status == ChallengeStatus.failed).toList();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  final ValueNotifier<SpendingChallenge?> recentlyCompletedChallenge = ValueNotifier(null);

  StreamSubscription? _challengesSubscription;
  StreamSubscription? _transactionsSubscription;

  Future<void> _initializeViewModel() async {
    _logger.info('Initializing ChallengeViewModel');
    await _listenToChallenges();
    await _listenToTransactions();
  }

  Future<void> _listenToChallenges() async {
    _setLoading(true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _logger.warning('No authenticated user found');
        _setError('Please sign in to view challenges');
        _setLoading(false);
        return;
      }

      _logger.info('Setting up challenges listener for user: ${user.uid}');
      
      _challengesSubscription = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('challenges')
          .orderBy('start_date', descending: true)
          .snapshots()
          .listen(
        (snapshot) {
          _logger.info('Received ${snapshot.docs.length} challenges from Firestore');
          
          _challenges = snapshot.docs.map((doc) {
            try {
              final data = doc.data();
              data['id'] = doc.id; // Ensure ID is set
              return SpendingChallenge.fromMap(data);
            } catch (e) {
              _logger.warning('Error parsing challenge ${doc.id}: $e');
              return null;
            }
          }).whereType<SpendingChallenge>().toList();
          
          _setError(null);
          _setLoading(false);
          // Manually trigger an update with the latest known transactions
          if (_transactionService.lastTransactions.isNotEmpty) {
            _updateChallengesWithTransactions(_transactionService.lastTransactions);
          }
          _logger.info('Successfully loaded ${_challenges.length} challenges');
        },
        onError: (error) {
          _logger.severe('Error listening to challenges: $error');
          _setError('Failed to load challenges: $error');
          _setLoading(false);
        },
      );
    } catch (e) {
      _logger.severe('Error setting up challenge listener: $e');
      _setError('Failed to initialize challenges: $e');
      _setLoading(false);
    }
  }

  Future<void> _listenToTransactions() async {
    try {
      _logger.info('Setting up transaction listener for challenge updates');
      
      _transactionsSubscription = _transactionService.getTransactionsStream().listen(
        (transactions) {
          _logger.info('Received ${transactions.length} transactions for challenge processing');
          _updateChallengesWithTransactions(transactions);
        },
        onError: (error) {
          _logger.warning('Error listening to transactions: $error');
        },
      );
    } catch (e) {
      _logger.warning('Error setting up transaction listener: $e');
    }
  }

  void _updateChallengesWithTransactions(List<TransactionModel> transactions) {
    if (_challenges.isEmpty) return;
    
    _logger.info('Updating ${_challenges.length} challenges with transaction data');
    bool hasUpdates = false;
    
    for (int i = 0; i < _challenges.length; i++) {
      final challenge = _challenges[i];
      if (challenge.status != ChallengeStatus.active) continue;
      
      // Filter transactions relevant to this challenge
      final relevantTransactions = transactions.where((transaction) {
        return transaction.date.isAfter(challenge.startDate.subtract(const Duration(days: 1))) &&
               transaction.date.isBefore(challenge.endDate.add(const Duration(days: 1))) &&
               (challenge.categories.isEmpty || challenge.categories.contains(transaction.category));
      }).toList();
      
      // Always update challenges, even if no relevant transactions (important for noSpend challenges)
      _logger.info('Found ${relevantTransactions.length} relevant transactions for challenge: ${challenge.title}');
      
      double totalAmount = relevantTransactions.fold(0.0, (total, t) => total + t.amount.abs());

      // Calculate daily progress data
      final Map<DateTime, double> dailyTotals = {};
      for (var transaction in relevantTransactions) {
        final dateKey = DateTime(transaction.date.year, transaction.date.month, transaction.date.day);
        dailyTotals[dateKey] = (dailyTotals[dateKey] ?? 0) + transaction.amount.abs();
      }

      final dailyProgressData = dailyTotals.entries.map((entry) {
        return {'date': entry.key, 'amount': entry.value};
      }).toList();
      // Sort by date just in case
      dailyProgressData.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

      final updatedChallenge = challenge.copyWith(
        currentAmount: totalAmount,
        dailyProgressData: dailyProgressData,
      ).updateStatus();
      
      if (updatedChallenge.currentAmount != challenge.currentAmount || 
          updatedChallenge.status != challenge.status) {
        _challenges[i] = updatedChallenge;
        hasUpdates = true;
        
        // Check if the challenge was just completed to trigger animation
        if (updatedChallenge.status == ChallengeStatus.completed && challenge.status != ChallengeStatus.completed) {
          _logger.info('Challenge "${updatedChallenge.title}" completed! Triggering celebration.');
          recentlyCompletedChallenge.value = updatedChallenge;
          // Reset after a short delay so it doesn't trigger again on rebuild
          Future.delayed(const Duration(seconds: 5), () {
            if (recentlyCompletedChallenge.value?.id == updatedChallenge.id) {
                recentlyCompletedChallenge.value = null;
            }
          });
        }

        // Update in Firestore
        _updateChallengeInFirestore(updatedChallenge);
      }
    }
    
    if (hasUpdates) {
      _logger.info('Challenges updated with transaction data');
      notifyListeners();
    }
  }

  Future<void> addChallenge(SpendingChallenge challenge) async {
    try {
      _logger.info('Adding new challenge: ${challenge.title}');
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('challenges')
          .doc(challenge.id)
          .set(challenge.toMap());
      
      _logger.info('Successfully added challenge: ${challenge.title}');
    } catch (e) {
      _logger.severe('Error adding challenge: $e');
      _setError('Failed to add challenge: $e');
      rethrow;
    }
  }

  Future<void> updateChallenge(SpendingChallenge challenge) async {
    try {
      _logger.info('Updating challenge: ${challenge.title}');
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('challenges')
          .doc(challenge.id)
          .update(challenge.toMap());
      
      _logger.info('Successfully updated challenge: ${challenge.title}');
    } catch (e) {
      _logger.severe('Error updating challenge: $e');
      _setError('Failed to update challenge: $e');
      rethrow;
    }
  }

  Future<void> _updateChallengeInFirestore(SpendingChallenge challenge) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('challenges')
          .doc(challenge.id)
          .update({
        'status': challenge.status.toString().split('.').last,
      });
    } catch (e) {
      _logger.warning('Error updating challenge in Firestore: $e');
    }
  }

  Future<void> deleteChallenge(String challengeId) async {
    try {
      _logger.info('Deleting challenge: $challengeId');
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('challenges')
          .doc(challengeId)
          .delete();
      
      _logger.info('Successfully deleted challenge: $challengeId');
    } catch (e) {
      _logger.severe('Error deleting challenge: $e');
      _setError('Failed to delete challenge: $e');
      rethrow;
    }
  }

  Future<void> refreshChallenges() async {
    _logger.info('Manually refreshing challenges');
    await _listenToChallenges();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  @override
  void dispose() {
    _challengesSubscription?.cancel();
    _transactionsSubscription?.cancel();
    recentlyCompletedChallenge.dispose();
    super.dispose();
  }

  void clearCompletedChallenge() {
    recentlyCompletedChallenge.value = null;
  }
}
