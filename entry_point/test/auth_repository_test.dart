import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:entry_point/data/repositories/auth_repository_impl.dart';
import 'package:entry_point/data/sources/auth_remote_data_source.dart';
import 'package:entry_point/core/storage/secure_storage.dart';
import 'package:entry_point/data/models/user_model.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockSecureStorage extends Mock implements SecureStorage {}

void main() {
  late MockAuthRemoteDataSource mockRemote;
  late MockSecureStorage mockStorage;
  late AuthRepositoryImpl repo;

  setUp(() {
    mockRemote = MockAuthRemoteDataSource();
    mockStorage = MockSecureStorage();
    repo = AuthRepositoryImpl(mockRemote, mockStorage);
  });

  group('AuthRepositoryImpl.login', () {
    const tEmail = 'user@test.com';
    const tPassword = 'password';
    const tDeviceName = 'Linux';
    const tDeviceCode = 'device_abc123';

    // Backend returns flat object with device_code
    final tResponseData = <String, dynamic>{
      'id': 1,
      'name': 'Test',
      'surname': 'User',
      'email': tEmail,
      'device_code': tDeviceCode,
      'is_admin': false,
    };

    test('saves device_code and returns User on success', () async {
      when(() => mockRemote.login(
            email: tEmail,
            password: tPassword,
            deviceName: tDeviceName,
          )).thenAnswer((_) async => tResponseData);
      when(() => mockStorage.saveDeviceCode(any()))
          .thenAnswer((_) async {});
      when(() => mockStorage.saveIsAdmin(any()))
          .thenAnswer((_) async {});

      final user = await repo.login(
        email: tEmail,
        password: tPassword,
        deviceName: tDeviceName,
      );

      expect(user.email, tEmail);
      expect(user.isAdmin, false);
    });

    test('propagates exception from remote', () async {
      when(() => mockRemote.login(
            email: tEmail,
            password: tPassword,
            deviceName: tDeviceName,
          )).thenThrow(Exception('Network error'));

      expect(
        () => repo.login(
            email: tEmail, password: tPassword, deviceName: tDeviceName),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('AuthRepositoryImpl.logout', () {
    test('clears storage even when remote fails', () async {
      when(() => mockStorage.getDeviceCode())
          .thenAnswer((_) async => 'dc');
      when(() => mockRemote.logout(
            deviceCode: any(named: 'deviceCode'),
          )).thenThrow(Exception('Remote error'));
      when(() => mockStorage.clearAll()).thenAnswer((_) async {});

      await repo.logout();

      verify(() => mockStorage.clearAll()).called(1);
    });
  });

  group('AuthRepositoryImpl.getMe', () {
    test('returns User from remote', () async {
      final model = UserModel(
        id: 42,
        name: 'John',
        surname: 'Doe',
        email: 'john@example.com',
        isAdmin: true,
      );
      when(() => mockRemote.getMe()).thenAnswer((_) async => model);

      final user = await repo.getMe();

      expect(user.id, 42);
      expect(user.isAdmin, true);
    });
  });
}

