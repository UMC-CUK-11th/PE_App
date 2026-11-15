import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class TmdbConfig {
  // 실패 재현용으로 `--dart-define=TMDB_ACCESS_TOKEN=invalid`를 주면 .env보다 우선합니다.
  static const _override = String.fromEnvironment('TMDB_ACCESS_TOKEN');

  static String get accessToken =>
      _override.isNotEmpty ? _override : dotenv.env['TMDB_ACCESS_TOKEN'] ?? '';
}
