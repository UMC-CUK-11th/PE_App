import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 토큰 저장·조회·삭제 규칙을 인증 흐름에서 분리합니다. 테스트에서는 메모리 구현으로 바꿉니다.
abstract interface class TokenStorage {
  Future<void> saveAccessToken(String token);

  Future<String?> readAccessToken();

  Future<void> deleteAccessToken();
}

/// iOS Keychain·Android Keystore에 암호화해 보관합니다.
/// SharedPreferences는 평문이라 토큰·비밀번호를 넣지 않습니다.
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage(this._storage);

  static const _accessTokenKey = 'movielog.access_token';

  final FlutterSecureStorage _storage;

  @override
  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  @override
  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  @override
  Future<void> deleteAccessToken() => _storage.delete(key: _accessTokenKey);
}
