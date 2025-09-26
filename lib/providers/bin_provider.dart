import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/bin_point.dart';
import '../utils/location_utils.dart';

class BinProvider extends ChangeNotifier {
  final CollectionReference binsRef = FirebaseFirestore.instance.collection('bins');
  List<BinPoint> _bins = [];
  List<BinPoint> _allBins = [];
  LatLng? _currentLocation;
  static const double _searchRadiusMeters = 5000.0; // 5km radius

  List<BinPoint> get bins => _bins;
  List<BinPoint> get allBins => _allBins;

  BinProvider() {
    _listenBins();
  }

  void _listenBins() {
    binsRef.snapshots().listen((snapshot) {
      print('Firestore snapshot received: ${snapshot.docs.length} bins');
      _allBins = snapshot.docs.map((d) => BinPoint.fromDoc(d)).toList();
      _filterBinsByLocation();
      print('Loaded ${_allBins.length} total bins, ${_bins.length} within range');
      notifyListeners();
    }, onError: (error) {
      print('Error listening to bins: $error');
    });
  }

  void updateCurrentLocation(LatLng location) {
    _currentLocation = location;
    _filterBinsByLocation();
    notifyListeners();
  }

  void _filterBinsByLocation() {
    if (_currentLocation == null) {
      _bins = _allBins; // Show all bins if no current location
      return;
    }

    // Show all bins within radius, but if none are found, still show all bins
    final filteredBins = _allBins.where((bin) {
      final binLocation = LatLng(bin.lat, bin.lng);
      return LocationUtils.isWithinRadius(
        _currentLocation!,
        binLocation,
        _searchRadiusMeters,
      );
    }).toList();
    
    _bins = filteredBins.isNotEmpty ? filteredBins : _allBins;
  }

  Future<void> addBin({
    required double lat,
    required double lng,
    required String addedBy,
    String type = 'bio',
  }) async {
    try {
      final doc = {
        'lat': lat,
        'lng': lng,
        'addedBy': addedBy,
        'type': type,
        'upvotes': 0,
        'createdAt': FieldValue.serverTimestamp(),
      };
      print('Adding bin: $doc');
      final docRef = await binsRef.add(doc);
      print('Bin added successfully with ID: ${docRef.id}');
    } catch (e) {
      print('Error adding bin: $e');
      rethrow;
    }
  }

  Future<void> upvote(String id) async {
    final doc = binsRef.doc(id);
    await doc.update({'upvotes': FieldValue.increment(1)});
  }

  Future<void> deleteBin(String id) async {
    try {
      await binsRef.doc(id).delete();
      print('Bin deleted successfully: $id');
    } catch (e) {
      print('Error deleting bin: $e');
      rethrow;
    }
  }

  /// Get bins sorted by distance from current location
  List<BinPoint> getNearbyBinsSorted() {
    if (_currentLocation == null) return _allBins;
    
    final binsWithDistance = _allBins.map((bin) {
      final distance = LocationUtils.calculateDistance(
        _currentLocation!,
        LatLng(bin.lat, bin.lng),
      );
      return {'bin': bin, 'distance': distance};
    }).toList();
    
    // Sort by distance
    binsWithDistance.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
    
    // Return only bins within reasonable range (10km)
    return binsWithDistance
        .where((item) => (item['distance'] as double) <= 10000)
        .map((item) => item['bin'] as BinPoint)
        .toList();
  }
  
  /// Get distance to a specific bin from current location
  double? getDistanceToBin(BinPoint bin) {
    if (_currentLocation == null) return null;
    return LocationUtils.calculateDistance(
      _currentLocation!,
      LatLng(bin.lat, bin.lng),
    );
  }
}
