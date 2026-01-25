```dart
import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Contract for the Configuration Data Source.
/// This follows the Interface Segregation Principle, allowing the Domain 
/// layer (via Repository) to stay decoupled from Firebase specifics.
abstract class RemoteConfigSource {
  /// Fetches all configurations, merging Remote Config with local overrides.
  Map<String, dynamic> getAllConfigs();

  /// Gets a specific config value by key.
  T? getString<T>(String key);

  /// Sets a local override for a specific key (useful for QA/Testing).
  Future<void> setOverride(String key, dynamic value);

  /// Removes all local overrides.
  Future<void> clearOverrides();

  /// Initialized the remote config service.
  Future<void> initialize();
}

/// Production implementation of [RemoteConfigSource].
/// 
/// This implementation prioritizes "Local Overrides" stored in SharedPreferences
/// over "Firebase Remote Config" values. This is a common pattern in enterprise 
/// apps to allow developers/QA to force specific feature flags.
class RemoteConfigSourceImpl implements RemoteConfigSource {
  final FirebaseRemoteConfig _remoteConfig;
  final SharedPreferences _sharedPreferences;

  static const String _overridePrefix = 'config_override_';

  RemoteConfigSourceImpl({
    required FirebaseRemoteConfig remoteConfig,
    required SharedPreferences sharedPreferences,
  })  : _remoteConfig = remoteConfig,
        _sharedPreferences = sharedPreferences;

  @override
  Future<void> initialize() async {
    // Set settings (fetch timeout and minimum fetch interval)
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 1),
    ));

    // Fetch and activate values from the server
    await _remoteConfig.fetchAndActivate();
  }

  @override
  Map<String, dynamic> getAllConfigs() {
    final allRemote = _remoteConfig.getAll();
    final Map<String, dynamic> configs = {};

    // Map Firebase types to standard Dart types
    allRemote.forEach((key, value) {
      configs[key] = _getValueFromRemoteValue(value);
    });

    // Apply local overrides
    final keys = _sharedPreferences.getKeys();
    for (final key in keys) {
      if (key.startsWith(_overridePrefix)) {
        final configKey = key.replaceFirst(_overridePrefix, '');
        final rawValue = _sharedPreferences.get(key);
        if (rawValue != null) {
          configs[configKey] = rawValue;
        }
      }
    }

    return configs;
  }

  @override
  T? getString<T>(String key) {
    // 1. Check Local Overrides first
    final overrideKey = '$_overridePrefix$key';
    if (_sharedPreferences.containsKey(overrideKey)) {
      return _sharedPreferences.get(overrideKey) as T?;
    }

    // 2. Fallback to Remote Config
    final remoteValue = _remoteConfig.getValue(key);
    if (remoteValue.source == ValueSource.valueStatic) {
      return null; // Value doesn't exist in remote
    }

    return _getValueFromRemoteValue(remoteValue) as T?;
  }

  @override
  Future<void> setOverride(String key, dynamic value) async {
    final overrideKey = '$_overridePrefix$key';
    
    if (value is String) {
      await _sharedPreferences.setString(overrideKey, value);
    } else if (value is bool) {
      await _sharedPreferences.setBool(overrideKey, value);
    } else if (value is int) {
      await _sharedPreferences.setInt(overrideKey, value);
    } else if (value is double) {
      await _sharedPreferences.setDouble(overrideKey, value);
    } else {
      // Fallback for complex objects/JSON
      await _sharedPreferences.setString(overrideKey, jsonEncode(value));
    }
  }

  @override
  Future<void> clearOverrides() async {
    final keys = _sharedPreferences.getKeys();
    for (final key in keys) {
      if (key.startsWith(_overridePrefix)) {
        await _sharedPreferences.remove(key);
      }
    }
  }

  /// Helper to convert [RemoteConfigValue] to its primitive representation.
  dynamic _getValueFromRemoteValue(RemoteConfigValue value) {
    final strValue = value.asString();

    // Attempt to parse JSON if it looks like a collection
    if (strValue.startsWith('{') || strValue.startsWith('[')) {
      try {
        return jsonDecode(strValue);
      } catch (_) {
        return strValue;
      }
    }

    // Standard types
    if (strValue.toLowerCase() == 'true') return true;
    if (strValue.toLowerCase() == 'false') return false;
    
    final intValue = int.tryParse(strValue);
    if (intValue != null) return intValue;

    final doubleValue = double.tryParse(strValue);
    if (doubleValue != null) return doubleValue;

    return strValue;
  }
}
```