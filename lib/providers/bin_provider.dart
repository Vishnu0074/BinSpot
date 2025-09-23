import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/bin_point.dart';

class BinProvider extends ChangeNotifier {
  final CollectionReference binsRef = FirebaseFirestore.instance.collection('bins');
  List<BinPoint> _bins = [];

  List<BinPoint> get bins => _bins;

  BinProvider() {
    _listenBins();
  }

  void _listenBins() {
    binsRef.snapshots().listen((snapshot) {
      _bins = snapshot.docs.map((d) => BinPoint.fromDoc(d)).toList();
      notifyListeners();
    });
  }

  Future<void> addBin({
    required double lat,
    required double lng,
    required String addedBy,
    String type = 'general',
  }) async {
    final doc = {
      'lat': lat,
      'lng': lng,
      'addedBy': addedBy,
      'type': type,
      'upvotes': 0,
      'createdAt': FieldValue.serverTimestamp(),
    };
    await binsRef.add(doc);
  }

  Future<void> upvote(String id) async {
    final doc = binsRef.doc(id);
    await doc.update({'upvotes': FieldValue.increment(1)});
  }
}
