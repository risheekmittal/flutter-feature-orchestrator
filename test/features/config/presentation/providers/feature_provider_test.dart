```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Assuming standard Clean Architecture paths for the feature-first structure
import 'package:feature_orchestrator/features/config/domain/entities/feature_config.dart';
import 'package:feature_orchestrator/features/config/domain/usecases/get_features_use_case.dart';
import 'package:feature_orchestrator/features/config/domain/usecases/toggle_feature_use_case.dart';
import 'package:feature_orchestrator/features/config/presentation/providers/feature_provider.dart';

/// Mocking UseCases to isolate the Provider (Presentation Logic).
/// In Clean Architecture, the Provider acts as a Controller/ViewModel
/// orchestrating domain logic into state for the UI.
class MockGetFeaturesUseCase extends Mock implements GetFeaturesUseCase {}

class MockToggleFeatureUseCase extends Mock implements ToggleFeatureUseCase {}

void main() {
  late MockGetFeaturesUseCase mockGetFeaturesUseCase;
  late MockToggleFeatureUseCase mockToggleFeatureUseCase;
  late ProviderContainer container;

  // Domain entity stubs for testing
  final tFeatureConfigs = [
    const FeatureConfig(id: '1', name: 'Dark Mode', isEnabled: true),
    const FeatureConfig(id: '2', name: 'Beta Features', isEnabled: false),
  ];

  setUp(() {
    mockGetFeaturesUseCase = MockGetFeaturesUseCase();
    mockToggleFeatureUseCase = MockToggleFeatureUseCase();

    // Container initialization with dependency overrides.
    // This allows us to inject mocks into the Riverpod graph.
    container = ProviderContainer(
      overrides: [
        getFeaturesUseCaseProvider.overrideWithValue(mockGetFeaturesUseCase),
        toggleFeatureUseCaseProvider.overrideWithValue(mockToggleFeatureUseCase),
      ],
    );

    // Registering fallback values for mocktail logic if needed for complex types
    registerFallbackValue(tFeatureConfigs.first);
  });

  tearDown(() {
    container.dispose();
  });

  group('FeatureProvider - Initialization', () {
    test('Initial state should be AsyncLoading', () {
      // The provider usually initializes by fetching data
      expect(
        container.read(featureProvider),
        isA<AsyncLoading<List<FeatureConfig>>>(),
      );
    });
  });

  group('FeatureProvider - Fetching Logic', () {
    test(
      'should update state to AsyncData when GetFeaturesUseCase returns successfully',
      () async {
        // Arrange: Setup mock to return the list of features
        when(() => mockGetFeaturesUseCase.call())
            .thenAnswer((_) async => tFeatureConfigs);

        // Act: Explicitly trigger initialization or wait for the provider to resolve
        final result = await container.read(featureProvider.future);

        // Assert: Verify state transition and usecase execution
        expect(result, tFeatureConfigs);
        verify(() => mockGetFeaturesUseCase.call()).called(1);
      },
    );

    test(
      'should update state to AsyncError when GetFeaturesUseCase fails',
      () async {
        // Arrange: Setup mock to throw an exception
        final tException = Exception('Network Failure');
        when(() => mockGetFeaturesUseCase.call()).thenThrow(tException);

        // Act: Listen to the provider
        final notifier = container.listen(featureProvider, (_, __) {});

        // Assert: Wait for the next tick to allow the async operation to complete
        await expectLater(
          container.read(featureProvider.future),
          throwsA(tException),
        );
        
        expect(notifier.read(), isA<AsyncError>());
        verify(() => mockGetFeaturesUseCase.call()).called(1);
      },
    );
  });

  group('FeatureProvider - Mutation Logic', () {
    test(
      'should optimistically update state and call ToggleFeatureUseCase',
      () async {
        // Arrange: Initial state setup
        when(() => mockGetFeaturesUseCase.call())
            .thenAnswer((_) async => tFeatureConfigs);
        when(() => mockToggleFeatureUseCase.call(any()))
            .thenAnswer((_) async => true);

        // Wait for initial load
        await container.read(featureProvider.future);

        // Act: Toggle the first feature
        final featureToToggle = tFeatureConfigs.first;
        await container.read(featureProvider.notifier).toggleFeature(featureToToggle);

        // Assert: 
        // 1. Verify the toggle use case was called with the correct entity
        verify(() => mockToggleFeatureUseCase.call(featureToToggle)).called(1);
        
        // 2. Verify state reflects the change (assuming the provider refreshes or updates local state)
        final updatedState = container.read(featureProvider).value;
        final toggledFeature = updatedState?.firstWhere((f) => f.id == featureToToggle.id);
        
        // Note: Logic here depends on whether the provider does an optimistic update
        // or re-fetches. In production-grade apps, we check if the toggle was propagated.
        expect(toggledFeature?.isEnabled, !featureToToggle.isEnabled);
      },
    );

    test(
      'should handle errors gracefully when toggle fails',
      () async {
        // Arrange
        when(() => mockGetFeaturesUseCase.call())
            .thenAnswer((_) async => tFeatureConfigs);
        when(() => mockToggleFeatureUseCase.call(any()))
            .thenThrow(Exception('Update failed'));

        await container.read(featureProvider.future);

        // Act
        await container.read(featureProvider.notifier).toggleFeature(tFeatureConfigs.first);

        // Assert: Ensure use case was called despite the failure
        verify(() => mockToggleFeatureUseCase.call(any())).called(1);
        
        // In an opinionated architecture, we might expect the provider 
        // to revert the state or set an error flag.
      },
    );
  });
}
```