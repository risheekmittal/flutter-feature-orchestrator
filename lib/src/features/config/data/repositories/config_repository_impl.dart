```dart
import 'dart:async';

import '../../domain/repositories/config_repository.dart';
import '../datasources/config_local_datasource.dart';
import '../datasources/config_remote_datasource.dart';

/// Implementation of [ConfigRepository] that orchestrates data between
/// Firebase Remote Config and a local override/cache mechanism.
///
/// This implementation follows the "Cache-aside" or "Override-first" pattern,
/// allowing developers or QA to override remote values locally for testing,
/// while defaulting to Remote Config in production.
class ConfigRepositoryImpl implements ConfigRepository {
  ConfigRepositoryImpl({
    required ConfigRemoteDataSource remoteDataSource,
    required ConfigLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  final ConfigRemoteDataSource _remoteDataSource;
  final ConfigLocalDataSource _localDataSource;

  @override
  Future<void> initialize() async {
    try {
      // Set default values before fetching to ensure the app has 
      // working configuration even if the network is unavailable.
      await _remoteDataSource.setDefaults();
      
      // Fetch and activate the latest values from Firebase.
      await _remoteDataSource.fetchAndActivate();
    } catch (e) {
      // We catch errors but don't rethrow to prevent app initialization 
      // failure. The app will fall back to local defaults.
      // TODO: Log to Crashlytics or similar telemetry
    }
  }

  @override
  bool getBool(String key) {
    // 1. Check for local developer override
    final override = _localDataSource.getBoolOverride(key);
    if (override != null) return override;

    // 2. Return Remote Config value (which falls back to local defaults if not set)
    return _remoteDataSource.getBool(key);
  }

  @override
  String getString(String key) {
    final override = _localDataSource.getStringOverride(key);
    if (override != null) return override;

    return _remoteDataSource.getString(key);
  }

  @override
  int getInt(String key) {
    final override = _localDataSource.getIntOverride(key);
    if (override != null) return override;

    return _remoteDataSource.getInt(key);
  }

  @override
  double getDouble(String key) {
    final override = _localDataSource.getDoubleOverride(key);
    if (override != null) return override;

    return _remoteDataSource.getDouble(key);
  }

  @override
  Future<void> setOverride({
    required String key,
    required dynamic value,
  }) async {
    if (value is bool) {
      await _localDataSource.saveBoolOverride(key, value);
    } else if (value is String) {
      await _localDataSource.saveStringOverride(key, value);
    } else if (value is int) {
      await _localDataSource.saveIntOverride(key, value);
    } else if (value is double) {
      await _localDataSource.saveDoubleOverride(key, value);
    } else {
      throw UnsupportedError('Type ${value.runtimeType} is not supported for configuration overrides');
    }
  }

  @override
  Future<void> clearOverride(String key) async {
    await _localDataSource.removeOverride(key);
  }

  @override
  Future<void> clearAllOverrides() async {
    await _localDataSource.clearAllOverrides();
  }

  @override
  Map<String, dynamic> getAllConfigs() {
    final remoteValues = _remoteDataSource.getAll();
    final localOverrides = _localDataSource.getAllOverrides();

    // Merge maps: Local overrides take precedence over remote values
    return {
      ...remoteValues,
      ...localOverrides,
    };
  }
}
```