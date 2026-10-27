// 실행: flutter test tool/tmdb_live_probe.dart --reporter expanded
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/services/tmdb_client.dart';
import 'package:movielog/services/tmdb_movie_service.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';

import '../test/support/test_tmdb_service.dart' show MemoryMovieListPreferences;

void main() {
  test('실제 TMDB Popular·Genre·Discover·다중 장르 요청', () async {
    dotenv.loadFromString(envString: File('.env').readAsStringSync());
    expect(
      (dotenv.env['TMDB_READ_ACCESS_TOKEN'] ?? '').trim().isNotEmpty,
      isTrue,
      reason: '.env에 TMDB Read Access Token을 먼저 입력하세요.',
    );
    final client = createTmdbClient();
    addTearDown(client.close);
    final service = TmdbMovieService(client);
    final popular = await service.fetchPopular();
    expect(popular.results, isNotEmpty);
    expect(popular.results.take(5).length, lessThanOrEqualTo(5));
    final genres = await service.fetchGenres();
    expect(genres, isNotEmpty);
    final vm = MovieListViewModel(
      service,
      preferences: MemoryMovieListPreferences(),
    );
    addTearDown(vm.dispose);
    await vm.initialize();
    expect(vm.errorMessage, isNull);
    expect(vm.movies.length, inInclusiveRange(1, 30));
    expect(vm.movies.map((m) => m.id).toSet().length, vm.movies.length);
    final selected = genres.take(2).map((g) => g.id).toList();
    await vm.selectGenres(selected);
    expect(vm.errorMessage, isNull);
    expect(vm.movies.every((m) => m.genreIds.any(selected.contains)), isTrue);
    await vm.selectGenres(null);
    expect(vm.errorMessage, isNull);
    // ignore: avoid_print
    print(
      'LIVE CHECK OK: popular=${popular.results.take(5).length}, genres=${genres.length}, discover=${vm.movies.length}',
    );
  });
}
