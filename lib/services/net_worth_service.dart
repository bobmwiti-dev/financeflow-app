import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import '../models/asset_model.dart';
import '../models/liability_model.dart';

class NetWorthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get _currentUser => _auth.currentUser;

  // Stream of total assets value
  Stream<double> get totalAssetsStream {
    if (_currentUser == null) return Stream.value(0.0);
    return _firestore
        .collection('assets')
        .where('userId', isEqualTo: _currentUser!.uid)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return 0.0;
      return snapshot.docs
          .map((doc) => Asset.fromFirestore(doc).value)
          .fold(0.0, (prev, element) => prev + element);
    });
  }

  // Stream of total liabilities value
  Stream<double> get totalLiabilitiesStream {
    if (_currentUser == null) return Stream.value(0.0);
    return _firestore
        .collection('liabilities')
        .where('userId', isEqualTo: _currentUser!.uid)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return 0.0;
      return snapshot.docs
          .map((doc) => Liability.fromFirestore(doc).amount)
          .fold(0.0, (prev, element) => prev + element);
    });
  }

  // Combined stream for Net Worth
  Stream<double> get netWorthStream {
    return CombineLatestStream.combine2(
      totalAssetsStream,
      totalLiabilitiesStream,
      (assets, liabilities) => assets - liabilities,
    ).asBroadcastStream();
  }

  // Stream for list of assets
  Stream<List<Asset>> get assetsStream {
    if (_currentUser == null) return Stream.value([]);
    return _firestore
        .collection('assets')
        .where('userId', isEqualTo: _currentUser!.uid)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Asset.fromFirestore(doc)).toList());
  }

  // Stream for list of liabilities
  Stream<List<Liability>> get liabilitiesStream {
    if (_currentUser == null) return Stream.value([]);
    return _firestore
        .collection('liabilities')
        .where('userId', isEqualTo: _currentUser!.uid)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Liability.fromFirestore(doc)).toList());
  }

  // --- CRUD Operations ---

  Future<void> addAsset(Asset asset) async {
    if (_currentUser == null) throw Exception('User not logged in');
    await _firestore.collection('assets').add(asset.toFirestore());
  }

  Future<void> updateAsset(String id, Asset asset) async {
    if (_currentUser == null) throw Exception('User not logged in');
    await _firestore.collection('assets').doc(id).update(asset.toFirestore());
  }

  Future<void> deleteAsset(String id) async {
    if (_currentUser == null) throw Exception('User not logged in');
    await _firestore.collection('assets').doc(id).delete();
  }

  Future<void> addLiability(Liability liability) async {
    if (_currentUser == null) throw Exception('User not logged in');
    await _firestore.collection('liabilities').add(liability.toFirestore());
  }

  Future<void> updateLiability(String id, Liability liability) async {
    if (_currentUser == null) throw Exception('User not logged in');
    await _firestore.collection('liabilities').doc(id).update(liability.toFirestore());
  }

  Future<void> deleteLiability(String id) async {
    if (_currentUser == null) throw Exception('User not logged in');
    await _firestore.collection('liabilities').doc(id).delete();
  }
}
