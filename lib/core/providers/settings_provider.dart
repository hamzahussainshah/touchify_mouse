import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsModel {
  final bool invertScroll;
  final double pointerSpeed;
  final bool hapticFeedback;
  final bool showClickButtons;
  final bool leftHanded;
  final bool soundOnPress;
  final bool gyroMouse;
  final String theme;

  const SettingsModel({
    this.invertScroll = false,
    this.pointerSpeed = 1.0,
    this.hapticFeedback = true,
    this.showClickButtons = true,
    this.leftHanded = false,
    this.soundOnPress = true,
    this.gyroMouse = false,
    this.theme = 'amoled',
  });

  SettingsModel copyWith({
    bool? invertScroll,
    double? pointerSpeed,
    bool? hapticFeedback,
    bool? showClickButtons,
    bool? leftHanded,
    bool? soundOnPress,
    bool? gyroMouse,
    String? theme,
  }) {
    return SettingsModel(
      invertScroll: invertScroll ?? this.invertScroll,
      pointerSpeed: pointerSpeed ?? this.pointerSpeed,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      showClickButtons: showClickButtons ?? this.showClickButtons,
      leftHanded: leftHanded ?? this.leftHanded,
      soundOnPress: soundOnPress ?? this.soundOnPress,
      gyroMouse: gyroMouse ?? this.gyroMouse,
      theme: theme ?? this.theme,
    );
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsModel>((ref) {
  return SettingsNotifier(ref.watch(sharedPreferencesProvider));
});

class SettingsNotifier extends StateNotifier<SettingsModel> {
  final SharedPreferences _prefs;
  SettingsNotifier(this._prefs) : super(_loadFromPrefs(_prefs));

  static SettingsModel _loadFromPrefs(SharedPreferences p) => SettingsModel(
    invertScroll:    p.getBool('invertScroll') ?? false,
    pointerSpeed:    p.getDouble('pointerSpeed') ?? 1.0,
    hapticFeedback:  p.getBool('hapticFeedback') ?? true,
    showClickButtons:p.getBool('showClickButtons') ?? true,
    leftHanded:      p.getBool('leftHanded') ?? false,
    soundOnPress:    p.getBool('soundOnPress') ?? true,
    gyroMouse:       p.getBool('gyroMouse') ?? false,
    theme:           p.getString('theme') ?? 'amoled',
  );

  void setInvertScroll(bool v)     { _set('invertScroll', v);     state = state.copyWith(invertScroll: v); }
  void setPointerSpeed(double v)   { _prefs.setDouble('pointerSpeed', v); state = state.copyWith(pointerSpeed: v); }
  void setHapticFeedback(bool v)   { _set('hapticFeedback', v);   state = state.copyWith(hapticFeedback: v); }
  void setShowClickButtons(bool v) { _set('showClickButtons', v); state = state.copyWith(showClickButtons: v); }
  void setLeftHanded(bool v)       { _set('leftHanded', v);       state = state.copyWith(leftHanded: v); }
  void setSoundOnPress(bool v)     { _set('soundOnPress', v);     state = state.copyWith(soundOnPress: v); }
  void setGyroMouse(bool v)        { _set('gyroMouse', v);        state = state.copyWith(gyroMouse: v); }

  void _set(String key, bool v) => _prefs.setBool(key, v);
}
