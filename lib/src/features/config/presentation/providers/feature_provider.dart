```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ABSTRACT DOMAIN INTERFACES
/// These represent the contracts that the Data layer must implement.
/// In a standard Clean Architecture setup, these would reside in:
/// lib/src/features/config/domain/repositories/feature_repository.dart
/// lib/src/features/config/domain/use_cases/get_feature_flags_use_case.dart

abstract class IFeatureRepository {
  Future<Map<String, bool>> fetchFeatureFlags();
  Stream<Map<String, bool>> watchFeatureFlags();
}

class GetFeatureFlagsUseCase {
  final IFeatureRepository _repository;
  GetFeatureFlagsUseCase(this._repository);

  Future<Map<String, bool>> execute() => _repository.fetchFeatureFlags();
  Stream<Map<String, bool>> watch() => _repository.watchFeatureFlags();
}

/// DEPENDENCY INJECTION PROVIDERS
/// Logic for providing repository and use case instances.

/// To be overridden in the [ProviderScope] at the root level (main.dart)
/// with a concrete implementation (e.g., FirebaseRemoteConfigRepository).
final featureRepositoryProvider = Provider<IFeatureRepository>((ref) {
  throw UnimplementedError('IFeatureRepository has not been implemented.');
});

final getFeatureFlagsUseCaseProvider = Provider<GetFeatureFlagsUseCase>((ref) {
  final repository = ref.watch(featureRepositoryProvider);
  return GetFeatureFlagsUseCase(repository);
});

/// PRESENTATION STATE PROVIDERS
/// Reactive state management for UI consumption.

/// The primary provider for reactive feature flag consumption.
/// Uses [AsyncNotifier] to handle asynchronous initialization and manual refreshes.
final featureFlagsProvider =
    AsyncNotifierProvider<FeatureFlagsNotifier, Map<String, bool>>(
  FeatureFlagsNotifier.new,
);

class FeatureFlagsNotifier extends AsyncNotifier<Map<String, bool>> {
  @override
  Future<Map<String, bool>> build() async {
    final useCase = ref.watch(getFeatureFlagsUseCaseProvider);
    
    // Initial fetch of flags
    return useCase.execute();
  }

  /// Refreshes flags from the source (e.g., Remote Config fetch & activate).
  /// This is used for manual sync or when the app resumes.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(getFeatureFlagsUseCaseProvider);
      return useCase.execute();
    });
  }

  /// Updates a specific flag locally for testing or immediate UI feedback.
  void updateFlagLocal(String key, bool value) {
    state.whenData((currentFlags) {
      state = AsyncValue.data({
        ...currentFlags,
        key: value,
      });
    });
  }
}

/// UTILITY PROVIDER
/// A derived provider to check specific feature status without rebuilding 
/// for unrelated flag changes.
final isFeatureEnabledProvider = Provider.family<bool, String>((ref, featureKey) {
  final flagsAsync = ref.watch(featureFlagsProvider);
  return flagsAsync.maybeWhen(
    data: (flags) => flags[featureKey] ?? false,
    orElse: () => false, // Default to disabled if loading/error
  );
});

/// EXTENSIONS
/// Syntax sugar for consuming flags within the UI layer (WidgetRef).
extension FeatureFlagsX on WidgetRef {
  /// Check if a feature is enabled. 
  /// Usage: bool isChatEnabled = ref.watchFeature('enable_chat');
  bool watchFeature(String featureKey) {
    return watch(isFeatureEnabledProvider(featureKey));
  }
}
```