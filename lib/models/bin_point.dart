class BinPoint {
  final String id;
  final double lat;
  final double lng;
  final String addedBy;
  final String type;
  final int upvotes;
  final DateTime createdAt;

  const BinPoint({
    required this.id,
    required this.lat,
    required this.lng,
    required this.addedBy,
    required this.type,
    required this.upvotes,
    required this.createdAt,
  });

  factory BinPoint.fromMap(Map<String, dynamic> data) {
    final latitude = data['latitude'] ?? data['lat'] ?? 0;
    final longitude = data['longitude'] ?? data['lng'] ?? 0;
    final description = data['description']?.toString();
    final type = data['type']?.toString() ?? description ?? 'bio';
    return BinPoint(
      id: data['id']?.toString() ?? '',
      lat: (latitude as num).toDouble(),
      lng: (longitude as num).toDouble(),
      addedBy: data['added_by_email']?.toString() ??
          data['added_by']?.toString() ??
          data['addedBy']?.toString() ??
          'community',
      type: type,
      upvotes: (data['upvotes'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(
            data['timestamp']?.toString() ??
            data['created_at']?.toString() ??
            data['createdAt']?.toString() ??
            '',
          ) ??
          DateTime.now(),
    );
  }
}
