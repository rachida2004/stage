import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'storage_keys.dart';

class StorageService {
  final FlutterSecureStorage? _secure;
  SharedPreferences? _prefs;

  // Cache synchrone — mis à jour à chaque saveSession / clearSession
  String? _cachedUserId;
  String? _cachedUserNom;
  String? _cachedUserRole;
  String? _cachedInitiales;

  /// Accès synchrone à l'userId (disponible dès après le login)
  String? get cachedUserId => _cachedUserId;

  StorageService({FlutterSecureStorage? secure}) : _secure = kIsWeb ? null : secure;

  Future<SharedPreferences> get _p async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> _write(String key, String value) async {
    if (kIsWeb) {
      await (await _p).setString(key, value);
    } else {
      await _secure!.write(key: key, value: value);
    }
  }

  Future<String?> _read(String key) async {
    if (kIsWeb) return (await _p).getString(key);
    return await _secure!.read(key: key);
  }

  Future<void> _deleteAll() async {
    if (kIsWeb) {
      await (await _p).clear();
    } else {
      await _secure!.deleteAll();
    }
  }

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String userNom,
    required String userRole,
    String initiales = '',
  }) async {
    // Mise à jour du cache synchrone avant l'écriture async
    _cachedUserId    = userId;
    _cachedUserNom   = userNom;
    _cachedUserRole  = userRole;
    _cachedInitiales = initiales;

    await Future.wait([
      _write(StorageKeys.accessToken, accessToken),
      _write(StorageKeys.refreshToken, refreshToken),
      _write(StorageKeys.userId, userId),
      _write(StorageKeys.userNom, userNom),
      _write(StorageKeys.userRole, userRole),
      _write(StorageKeys.initiales, initiales),
    ]);
  }

  Future<void> clearSession() async {
    _cachedUserId    = null;
    _cachedUserNom   = null;
    _cachedUserRole  = null;
    _cachedInitiales = null;
    await _deleteAll();
  }

  Future<bool> isLoggedIn() async {
    final token = await _read(StorageKeys.accessToken);
    return token != null && token.isNotEmpty;
  }

  Future<String?> get userId    => _read(StorageKeys.userId);
  Future<String?> get userNom   => _read(StorageKeys.userNom);
  Future<String?> get userRole  => _read(StorageKeys.userRole);
  Future<String?> get initiales => _read(StorageKeys.initiales);
  Future<String?> get token     => _read(StorageKeys.accessToken);
}