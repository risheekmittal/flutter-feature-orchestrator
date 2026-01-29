```dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Assuming standard Clean Architecture structure based on project context
// Since I cannot create new files, I assume these imports align with the existing project layout.
import 'package:feature_orchestrator/core/error/exceptions.dart';
import 'package:feature_orchestrator/core/error/failures.dart';
import 'package:feature_orchestrator/features/config/data/datasources/config_local_datasource.dart';
import 'package:feature_orchestrator/features/config/data/datasources/config_remote_datasource.dart';
import 'package:feature_orchestrator/features/config/data/models/config_model.dart';
import 'package:feature_orchestrator/features/config/data/repositories/config_repository_impl.dart';
import 'package:feature_orchestrator/features/config/domain/entities/config_entity.dart';

class MockConfigRemoteDataSource extends Mock implements ConfigRemoteDataSource {}

class MockConfigLocalDataSource extends Mock implements ConfigLocalDataSource {}

void main() {
  late ConfigRepositoryImpl repository;
  late MockConfigRemoteDataSource mockRemoteDataSource;
  late MockConfigLocalDataSource mockLocalDataSource;

  setUp(() {
    mockRemoteDataSource = MockConfigRemoteDataSource();
    mockLocalDataSource = MockConfigLocalDataSource();
    repository = ConfigRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
    );
  });

  const tConfigModel = ConfigModel(
    environment: 'production',
    apiBaseUrl: 'https://api.example.com',
    featureFlags: {'enable_new_ui': true},
  );

  const ConfigEntity tConfigEntity = tConfigModel;

  group('getConfig', () {
    test(
      'should return remote data when the call to remote data source is successful',
      () async {
        // arrange
        when(() => mockRemoteDataSource.getRemoteConfig())
            .thenAnswer((_) async => tConfigModel);
        when(() => mockLocalDataSource.cacheConfig(any()))
            .thenAnswer((_) async => true);

        // act
        final result = await repository.getConfig();

        // assert
        verify(() => mockRemoteDataSource.getRemoteConfig());
        verify(() => mockLocalDataSource.cacheConfig(tConfigModel));
        expect(result, equals(const Right(tConfigEntity)));
      },
    );

    test(
      'should cache the data locally when the call to remote data source is successful',
      () async {
        // arrange
        when(() => mockRemoteDataSource.getRemoteConfig())
            .thenAnswer((_) async => tConfigModel);
        when(() => mockLocalDataSource.cacheConfig(any()))
            .thenAnswer((_) async => true);

        // act
        await repository.getConfig();

        // assert
        verify(() => mockRemoteDataSource.getRemoteConfig());
        verify(() => mockLocalDataSource.cacheConfig(tConfigModel));
      },
    );

    test(
      'should return local data when the call to remote data source is unsuccessful',
      () async {
        // arrange
        when(() => mockRemoteDataSource.getRemoteConfig())
            .thenThrow(ServerException());
        when(() => mockLocalDataSource.getLastConfig())
            .thenAnswer((_) async => tConfigModel);

        // act
        final result = await repository.getConfig();

        // assert
        verify(() => mockRemoteDataSource.getRemoteConfig());
        verify(() => mockLocalDataSource.getLastConfig());
        expect(result, equals(const Right(tConfigEntity)));
      },
    );

    test(
      'should return CacheFailure when remote call fails and there is no cached data present',
      () async {
        // arrange
        when(() => mockRemoteDataSource.getRemoteConfig())
            .thenThrow(ServerException());
        when(() => mockLocalDataSource.getLastConfig())
            .thenThrow(CacheException());

        // act
        final result = await repository.getConfig();

        // assert
        verify(() => mockRemoteDataSource.getRemoteConfig());
        verify(() => mockLocalDataSource.getLastConfig());
        expect(result, equals(Left(CacheFailure())));
      },
    );
  });

  group('updateConfig', () {
    test(
      'should call remote data source to update config and return updated entity',
      () async {
        // arrange
        when(() => mockRemoteDataSource.updateRemoteConfig(any()))
            .thenAnswer((_) async => tConfigModel);
        when(() => mockLocalDataSource.cacheConfig(any()))
            .thenAnswer((_) async => true);

        // act
        final result = await repository.updateConfig(tConfigEntity);

        // assert
        verify(() => mockRemoteDataSource.updateRemoteConfig(tConfigModel));
        expect(result, equals(const Right(tConfigEntity)));
      },
    );

    test(
      'should return ServerFailure when remote update fails',
      () async {
        // arrange
        when(() => mockRemoteDataSource.updateRemoteConfig(any()))
            .thenThrow(ServerException());

        // act
        final result = await repository.updateConfig(tConfigEntity);

        // assert
        expect(result, equals(Left(ServerFailure())));
      },
    );
  });
}
```