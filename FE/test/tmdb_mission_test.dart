import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/models/tmdb_movie_dto.dart';
import 'package:movielog/services/tmdb_client.dart';
import 'package:movielog/services/tmdb_movie_service.dart';
import 'package:movielog/view_models/movie_home_view_model.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';

import 'support/test_tmdb_service.dart';

class JsonAdapter implements HttpClientAdapter {
  JsonAdapter(this.respond);
  final Map<String, dynamic> Function(RequestOptions) respond;
  int statusCode = 200;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode(respond(options)),
    statusCode,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
  @override
  void close({bool force = false}) {}
}

void main() {
  test('DTO가 null 포스터, 없는 날짜, 정수 평점과 TMDB id를 처리한다', () {
    final movie = TmdbMovieDto.fromJson({
      'id': 123,
      'title': '영화',
      'poster_path': null,
      'vote_average': 8,
      'genre_ids': [28],
    }).toMovie(const [TmdbGenreDto(id: 28, name: '액션')]);
    expect(movie.id, 123);
    expect(movie.posterUrl, isNull);
    expect(movie.year, 0);
    expect(movie.rating, 4.0);
    expect(movie.genres, ['액션']);
  });

  test('인기 결과는 앞 5개, 5개 미만도 안전하다', () async {
    final service = TestTmdbService();
    final vm = MovieHomeViewModel(service);
    addTearDown(vm.dispose);
    await vm.load();
    expect(vm.movies.length, 5);
    expect(vm.movies.first.id, 1);
    final short = _ShortPopular();
    final shortVm = MovieHomeViewModel(short);
    addTearDown(shortVm.dispose);
    await shortVm.load();
    expect(shortVm.movies.length, 2);
  });

  test('페이지 중복 제거 후 30개, 장르 OR 전달과 전체 요청 생략', () async {
    final requests = <RequestOptions>[];
    final client = createTmdbClient(
      token: 'test-only-token',
      logWriter: (_) {},
    );
    addTearDown(client.close);
    client.httpClientAdapter = JsonAdapter((options) {
      requests.add(options);
      if (options.path == '/genre/movie/list') {
        return {
          'genres': [
            {'id': 28, 'name': '액션'},
          ],
        };
      }
      final page = options.queryParameters['page'] as int;
      // 1페이지 1..20, 2페이지 11..30: 10개 중복을 제거해야 30개다.
      return {
        'page': page,
        'total_pages': 3,
        'results': List.generate(
          20,
          (i) => {'id': (page - 1) * 10 + i + 1, 'title': '영화 $i'},
        ),
      };
    });
    final vm = MovieListViewModel(
      TmdbMovieService(client),
      preferences: MemoryMovieListPreferences(),
    );
    addTearDown(vm.dispose);
    await vm.initialize();
    expect(vm.movies.length, 30);
    expect(vm.movies.map((m) => m.id).toSet().length, 30);
    expect(
      requests
          .where((r) => r.path == '/discover/movie')
          .map((r) => r.queryParameters['page']),
      [1, 2],
    );
    expect(requests.last.queryParameters.containsKey('with_genres'), isFalse);
    await vm.selectGenres([878, 28]);
    expect(requests.last.queryParameters['with_genres'], '28|878');
    await vm.selectGenres([]);
    expect(requests.last.queryParameters.containsKey('with_genres'), isFalse);
  });

  test('마지막 페이지가 짧거나 비어 있으면 30개 미만으로 종료한다', () async {
    final client = createTmdbClient(token: 'test', logWriter: (_) {});
    addTearDown(client.close);
    client.httpClientAdapter = JsonAdapter(
      (options) => options.path == '/genre/movie/list'
          ? {'genres': []}
          : {
              'page': 1,
              'total_pages': 1,
              'results': [
                {'id': 10, 'title': '하나'},
              ],
            },
    );
    final vm = MovieListViewModel(
      TmdbMovieService(client),
      preferences: MemoryMovieListPreferences(),
    );
    addTearDown(vm.dispose);
    await vm.initialize();
    expect(vm.movies.length, 1);
  });

  test('로딩 중 중복 호출과 장르 변경을 막고 실패 재시도에 마지막 장르를 쓴다', () async {
    final service = TestTmdbService();
    final vm = MovieListViewModel(
      service,
      preferences: MemoryMovieListPreferences(),
    );
    addTearDown(vm.dispose);
    await vm.initialize();
    service.delay = const Duration(milliseconds: 10);
    final pending = vm.selectGenres([878]);
    await vm.selectGenres([28]);
    await vm.load();
    await pending;
    expect(service.calls, 2);
    expect(vm.selectedGenreIds, [878]);
    service.fail = true;
    await vm.load();
    expect(vm.movies.single.id, 2);
    expect(vm.status, MovieLoadStatus.error);
    service.fail = false;
    await vm.load();
    expect(service.requestedGenres.last, [878]);
    expect(service.requestedPages.last, 1);
    expect(vm.status, MovieLoadStatus.success);
  });

  test('dispose 이후 늦게 온 응답은 상태를 바꾸지 않는다', () async {
    final service = TestTmdbService()..delay = const Duration(milliseconds: 10);
    final vm = MovieListViewModel(
      service,
      preferences: MemoryMovieListPreferences(),
    );
    final pending = vm.initialize();
    await Future<void>.delayed(const Duration(milliseconds: 1));
    vm.dispose();
    await pending;
    expect(vm.movies, isEmpty);
  });

  test('성공/실패 로그에 원문 토큰이 없고 로그 비활성 시 출력하지 않는다', () async {
    final logs = <String>[];
    final client = createTmdbClient(
      token: 'private-test-token',
      logWriter: logs.add,
    );
    addTearDown(client.close);
    final adapter = JsonAdapter((_) => {'status_message': 'Invalid API key'});
    client.httpClientAdapter = adapter;
    await client.get('/movie/popular');
    adapter.statusCode = 401;
    await expectLater(
      client.get('/discover/movie'),
      throwsA(isA<DioException>()),
    );
    expect(logs.join('\n'), contains('Authorization: Bearer ***'));
    expect(logs.join('\n'), contains('RESPONSE 200'));
    expect(
      logs.join('\n'),
      contains('ERROR 401 https://api.themoviedb.org/3/discover/movie'),
    );
    expect(logs.join('\n'), isNot(contains('private-test-token')));
    client.interceptors.clear();
    client.interceptors.add(
      TmdbLoggingInterceptor(writer: logs.add, enabled: false),
    );
    logs.clear();
    await expectLater(
      client.get('/discover/movie'),
      throwsA(isA<DioException>()),
    );
    expect(logs, isEmpty);
  });
}

class _ShortPopular extends TestTmdbService {
  @override
  Future<TmdbMoviePageDto> fetchPopular({CancelToken? cancelToken}) async =>
      TmdbMoviePageDto(
        page: 1,
        totalPages: 1,
        results: fixtures.take(2).toList(),
      );
}
