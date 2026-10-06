import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/place.dart';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class Api {
  Api({http.Client? client}) : _c = client ?? http.Client();
  final http.Client _c;
  static const _timeout = Duration(seconds: 10);

  Uri _u(String path, [Map<String, String>? query]) =>
      Uri.parse('$apiBase$path').replace(queryParameters: query);

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    try {
      final r = await request().timeout(_timeout);
      if (r.statusCode >= 200 && r.statusCode < 300) {
        return r.body.isEmpty ? null : jsonDecode(utf8.decode(r.bodyBytes));
      }
      throw ApiException('The server answered ${r.statusCode}. Try again.');
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('The server took too long to answer.');
    } catch (_) {
      throw ApiException("Can't reach the server at $apiBase. Is it running?");
    }
  }

  Future<List<Place>> places() async {
    final d = await _send(() => _c.get(_u('/api/destinations')));
    return (d as List)
        .map((e) => Place.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Trip>> trips(String clientId) async {
    final d = await _send(
      () => _c.get(_u('/api/trips', {'client_id': clientId})),
    );
    return (d as List)
        .map((e) => Trip.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Trip> saveTrip({
    required String clientId,
    required String destinationId,
    required int days,
    required List<String> packed,
  }) async {
    final d = await _send(
      () => _c.put(
        _u('/api/trips'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'client_id': clientId,
          'destination_id': destinationId,
          'days': days,
          'packed': packed,
        }),
      ),
    );
    return Trip.fromJson(d as Map<String, dynamic>);
  }

  Future<void> deleteTrip(String clientId, String destinationId) async {
    await _send(
      () => _c.delete(_u('/api/trips/$destinationId', {'client_id': clientId})),
    );
  }
}
