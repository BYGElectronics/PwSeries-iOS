// lib/src/core/preferred_device_storage.dart
import 'package:shared_preferences/shared_preferences.dart';

class PreferredDeviceStorage {
  static const _kPreferredDeviceId = 'preferredDeviceId';
  static const _kHasCompletedInitialConfig = 'hasCompletedInitialConfig';


  Future<String?> getPreferredId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_kPreferredDeviceId);
    return (id != null && id.isNotEmpty) ? id : null;
  }

  Future<void> setPreferredId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPreferredDeviceId, id);
  }

  Future<void> clearPreferredId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPreferredDeviceId);
  }

  Future<bool> getHasCompletedInitialConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kHasCompletedInitialConfig) ?? false;
  }

  Future<void> setHasCompletedInitialConfig(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHasCompletedInitialConfig, value);
  }

  Future<void> clearInitialConfigFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kHasCompletedInitialConfig);
  }
}
