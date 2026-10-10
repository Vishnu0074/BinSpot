import 'package:flutter_test/flutter_test.dart';
import 'package:binspot_app/models/bin_point.dart';

void main() {
  test('parses a bin returned by the Django REST API', () {
    final bin = BinPoint.fromMap({
      'id': 42,
      'latitude': 9.2648,
      'longitude': 76.7758,
      'description': 'Community recycling bin',
      'type': 'plastic',
      'added_by': 7,
      'added_by_email': 'tester@example.com',
      'upvotes': 3,
      'created_at': '2026-10-10T10:30:00Z',
    });

    expect(bin.id, '42');
    expect(bin.lat, 9.2648);
    expect(bin.lng, 76.7758);
    expect(bin.type, 'plastic');
    expect(bin.addedBy, 'tester@example.com');
    expect(bin.upvotes, 3);
    expect(bin.createdAt.year, 2026);
  });
}
