import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/place.dart';
import '../services/api.dart';

/// All app data lives here. Screens read it through [AppScope].
class AppState extends ChangeNotifier {
  AppState({Api? api}) : api = api ?? Api();

  final Api api;
  late String clientId;

  List<Place> places = [];
  Map<String, Trip> trips = {};
  Mood mood = Mood.all;
  String query = '';
  bool loading = true;
  String? error;

  /// Bumps when filters are cleared so the search box resets its text.
  int filterEpoch = 0;

  List<Place> get visible {
    final q = query.trim().toLowerCase();
    return places.where((p) {
      final okMood = mood == Mood.all || p.mood == mood;
      final okQuery = q.isEmpty ||
          '${p.name} ${p.country} ${p.tagline}'.toLowerCase().contains(q);
      return okMood && okQuery;
    }).toList();
  }

  Place? placeById(String id) {
    for (final p in places) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('client_id');
    if (id == null) {
      id = _newId();
      await prefs.setString('client_id', id);
    }
    clientId = id;
    await load();
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final p = await api.places();
      final t = await api.trips(clientId);
      places = p;
      trips = {for (final x in t) x.destinationId: x};
    } on ApiException catch (e) {
      error = e.message;
    }
    loading = false;
    notifyListeners();
  }

  void setMood(Mood m) {
    mood = m;
    notifyListeners();
  }

  void setQuery(String q) {
    query = q;
    notifyListeners();
  }

  void clearFilters() {
    mood = Mood.all;
    query = '';
    filterEpoch++;
    notifyListeners();
  }

  /// Returns an error message, or null when it worked.
  Future<String?> saveTrip(Place p, int days, Set<String> packed) async {
    try {
      final t = await api.saveTrip(
        clientId: clientId,
        destinationId: p.id,
        days: days,
        packed: packed.toList(),
      );
      trips = {...trips, p.id: t};
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> removeTrip(String destinationId) async {
    try {
      await api.deleteTrip(clientId, destinationId);
      trips = {...trips}..remove(destinationId);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  static String _newId() {
    final r = Random.secure();
    return List.generate(24, (_) => r.nextInt(16).toRadixString(16)).join();
  }
}

/// Hands [AppState] to any widget below it: `AppScope.of(context)`.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({
    super.key,
    required AppState state,
    required super.child,
  }) : super(notifier: state);

  /// Rebuilds the calling widget whenever the state changes.
  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Reads the state once without subscribing (safe in initState).
  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
