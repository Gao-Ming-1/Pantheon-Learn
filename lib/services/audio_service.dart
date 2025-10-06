import 'package:shared_preferences/shared_preferences.dart';

class AudioService {
  AudioService._internal();
  static final AudioService instance = AudioService._internal();

  static const String _kVolumeKey = 'app_volume_0_100';
  double _volume01 = 1.0; // 0.0 ~ 1.0

  double get volume01 => _volume01;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getInt(_kVolumeKey);
    if (v != null) {
      _volume01 = (v.clamp(0, 100)) / 100.0;
    }
  }

  Future<void> setVolumePercent(int percent) async {
    final p = percent.clamp(0, 100);
    _volume01 = p / 100.0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kVolumeKey, p);
  }

  int getVolumePercent() => (_volume01 * 100).round();
}


