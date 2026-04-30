import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/models/device_model.dart';
import 'settings_provider.dart' show sharedPreferencesProvider;

/// Persists previously-connected desktops so the user can re-pair quickly.
///
/// - Up to [_maxEntries] entries, most-recent first.
/// - De-duped by `device.id` (which is `ip:port`); a re-connect bumps it to
///   the top instead of adding a duplicate.
/// - Stored in `SharedPreferences` under [_prefsKey] as a JSON list.
final connectionHistoryProvider =
    StateNotifierProvider<ConnectionHistoryNotifier, List<DeviceModel>>(
  (ref) => ConnectionHistoryNotifier(ref.watch(sharedPreferencesProvider)),
);

class ConnectionHistoryNotifier extends StateNotifier<List<DeviceModel>> {
  ConnectionHistoryNotifier(this._prefs) : super(_load(_prefs));

  static const _prefsKey = 'connection_history.v1';
  static const _maxEntries = 10;

  final SharedPreferences _prefs;

  static List<DeviceModel> _load(SharedPreferences p) {
    final raw = p.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return list.map(DeviceModel.fromJson).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> _save() async {
    await _prefs.setString(
      _prefsKey,
      jsonEncode(state.map((d) => d.toJson()).toList()),
    );
  }

  /// Record a successful connection. De-dupes by id, hoists to front.
  Future<void> recordConnection(DeviceModel device) async {
    final next = <DeviceModel>[
      device,
      ...state.where((d) => d.id != device.id),
    ];
    if (next.length > _maxEntries) {
      next.removeRange(_maxEntries, next.length);
    }
    state = List.unmodifiable(next);
    await _save();
  }

  Future<void> remove(String id) async {
    state = List.unmodifiable(state.where((d) => d.id != id));
    await _save();
  }

  Future<void> clear() async {
    state = const [];
    await _save();
  }
}
