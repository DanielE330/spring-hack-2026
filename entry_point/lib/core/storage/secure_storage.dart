import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/app_logger.dart';

class SecureStorage {
  static const _tag = 'SecureStorage';

  SecureStorage._() : _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static final SecureStorage instance = SecureStorage._();

  final FlutterSecureStorage _storage;

  static const _keyDeviceCode = 'device_code';
  static const _keyIsAdmin    = 'is_admin';

  // ── device code ──────────────────────────────────────────────────────────

  Future<void> saveDeviceCode(String code) async {
    AppLogger.d(_tag, 'saveDeviceCode len=${code.length}');
    await _storage.write(key: _keyDeviceCode, value: code);
  }

  Future<String?> getDeviceCode() async {
    final c = await _storage.read(key: _keyDeviceCode);
    AppLogger.d(_tag, 'getDeviceCode → ${c != null ? "found" : "null"}');
    return c;
  }

  // ── meta ─────────────────────────────────────────────────────────────────

  Future<void> saveIsAdmin(bool v) =>
      _storage.write(key: _keyIsAdmin, value: v ? '1' : '0');

  Future<bool> getIsAdmin() async {
    final v = await _storage.read(key: _keyIsAdmin);
    return v == '1';
  }

  // ── clear ─────────────────────────────────────────────────────────────────

  Future<void> clearAll() async {
    AppLogger.w(_tag, '🗑️  clearAll()');
    await _storage.deleteAll();
    AppLogger.i(_tag, '✅ Storage cleared');
  }

  // backwards compat
  Future<void> clearTokens() => clearAll();
}

