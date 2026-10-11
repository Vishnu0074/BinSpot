class BinPoint {
  final String id;
  final double lat;
  final double lng;
  final String addedBy;
  final String type;
  final String accessLevel;
  final String description;
  final int upvotes;
  final DateTime createdAt;

  const BinPoint({
    required this.id,
    required this.lat,
    required this.lng,
    required this.addedBy,
    required this.type,
    this.accessLevel = 'public',
    this.description = '',
    required this.upvotes,
    required this.createdAt,
  });

  bool get isRestricted => accessLevel == 'limited' || accessLevel == 'private';

  factory BinPoint.fromMap(Map<String, dynamic> data) {
    final latitude = data['latitude'] ?? data['lat'] ?? 0;
    final longitude = data['longitude'] ?? data['lng'] ?? 0;
    return BinPoint(
      id: data['id']?.toString() ?? '',
      lat: (latitude as num).toDouble(),
      lng: (longitude as num).toDouble(),
      addedBy: data['added_by_email']?.toString() ??
          data['added_by']?.toString() ??
          data['addedBy']?.toString() ?? 'community',
      type: data['type']?.toString() ?? 'bio',
      accessLevel: data['access_level']?.toString() ?? 'public',
      description: data['description']?.toString() ?? '',
      upvotes: (data['upvotes'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(
        data['created_at']?.toString() ??
        data['timestamp']?.toString() ??
        data['createdAt']?.toString() ?? '',
      ) ?? DateTime.now(),
    );
  }
}
