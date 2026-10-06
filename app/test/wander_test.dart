import 'package:flutter_test/flutter_test.dart';
import 'package:wander/models/place.dart';
import 'package:wander/util.dart';

void main() {
  final json = {
    'id': 'bali',
    'name': 'Bali',
    'country': 'Indonesia',
    'tagline': 't',
    'season': 'Apr to Oct',
    'flight_time': '6h 30m',
    'temp': 29,
    'per_day': 6500,
    'flight': 28000,
    'mood': 'beach',
    'peaks': false,
    'sky_top': '#3A1C71',
    'sky_bottom': '#FF6F91',
    'sun': '#FFC857',
    'layers': ['#6D2E7C', '#3B1A5A', '#1E0F36'],
    'pack': ['Sunscreen'],
  };

  test('Place parses the API JSON and estimates cost', () {
    final p = Place.fromJson(json);
    expect(p.mood, Mood.beach);
    expect(p.layers.length, 3);
    expect(p.estimate(5), 5 * 6500 + 28000);
  });

  test('inr uses Indian digit grouping', () {
    expect(inr(950), '₹950');
    expect(inr(5000), '₹5,000');
    expect(inr(150000), '₹1,50,000');
    expect(inr(1234567), '₹12,34,567');
  });
}
