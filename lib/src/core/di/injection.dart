```dart
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global instance of the Service Locator.
/// Using GetIt for dependency injection facilitates testability and 
/// decoupling across Clean Architecture layers.
final sl = GetIt.instance;

/// Initializes the dependency injection container.
/// This method should be called in the main.dart file before [runApp].
Future<void> init() async {
  // ===========================================================================
  // EXTERNAL DEPENDENCIES
  // ===========================================================================
  
  // Shared Preferences for local persistence (Feature Flag caching)
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // ===========================================================================
  // CORE / INFRASTRUCTURE
  // ===========================================================================
  
  // Core Network/API Client would be registered here.
  // Example: sl.registerLazySingleton(() => Dio());

  // ===========================================================================
  // FEATURES - FLAG MANAGEMENT
  // ===========================================================================

  /**
   * DATA LAYER
   * Registering DataSources and Repository implementations.
   * RemoteFlagDataSource: Fetches from Firebase Remote Config or custom API.
   * LocalFlagDataSource: Handles persistence for offline-first capabilities.
   */
  // sl.registerLazySingleton<FlagRemoteDataSource>(() => FlagRemoteDataSourceImpl(client: sl()));
  // sl.registerLazySingleton<FlagLocalDataSource>(() => FlagLocalDataSourceImpl(sharedPreferences: sl()));
  
  // sl.registerLazySingleton<FlagRepository>(
  //   () => FlagRepositoryImpl(
  //     remoteDataSource: sl(),
  //     localDataSource: sl(),
  //     networkInfo: sl(),
  //   ),
  // );

  /**
   * DOMAIN LAYER
   * Usecases are registered as LazySingletons as they are stateless logic units.
   */
  // sl.registerLazySingleton(() => GetFeatureFlagsUseCase(sl()));
  // sl.registerLazySingleton(() => ObserveFlagChangesUseCase(sl()));

  /**
   * PRESENTATION / APPLICATION LAYER
   * Using 'registerFactory' for State Management (Bloc/Notifier)
   * to ensure a new instance is created per view lifecycle where necessary.
   * 
   * For reactive flags, we register a FlagController or FlagCubit that 
   * listens to a Stream provided by the Domain layer.
   */
  // sl.registerFactory(() => FlagController(getFlags: sl(), observeFlags: sl()));
}

/**
 * ARCHITECTURAL NOTE:
 * We use 'registerLazySingleton' for services and repositories to maintain 
 * a single source of truth for the application state (especially important for reactive flags).
 * 
 * We use 'registerFactory' for UI-related controllers to prevent state 
 * leakage between different parts of the navigation stack.
 */
```