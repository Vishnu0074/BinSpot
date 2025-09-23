import 'package:cloud_firestore/cloud_firestore.dart';

class BinPoint {
  final String id;
  final double lat;
  final double lng;
  final String addedBy;
  final String type; // general/recycle/compost etc.
  final int upvotes;
  final Timestamp createdAt;

  BinPoint({
    required this.id,
    required this.lat,
    required this.lng,
    required this.addedBy,
    required this.type,
    required this.upvotes,
    required this.createdAt,
  });

  factory BinPoint.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return BinPoint(
      id: doc.id,
      lat: (d['lat'] ?? 0.0) * 1.0,
      lng: (d['lng'] ?? 0.0) * 1.0,
      addedBy: d['addedBy'] ?? 'unknown',
      type: d['type'] ?? 'general',
      upvotes: (d['upvotes'] ?? 0) as int,
      createdAt: d['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lat': lat,
      'lng': lng,
      'addedBy': addedBy,
      'type': type,
      'upvotes': upvotes,
      'createdAt': createdAt,
    };
  }
}
