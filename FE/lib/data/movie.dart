class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.genre,
    required this.year,
    required this.posterAsset,
    required this.runtimeMinutes,
    required this.rating,
    required this.ratingCount,
    required this.tags,
    required this.synopsis,
  });

  final int id;
  final String title;
  final String genre;
  final int year;
  final String posterAsset;
  final int runtimeMinutes;
  final double rating;
  final int ratingCount;
  final List<String> tags;
  final String synopsis;
}

const allGenres = ['드라마', 'SF', '애니메이션', '스릴러', '로맨스', '코미디', '판타지', '다큐멘터리'];

const movies = [
  Movie(
    id: 1,
    title: '별빛 아래 우리',
    genre: '드라마',
    year: 2024,
    posterAsset: 'assets/images/posters/hero_under_the_starlight.jpg',
    runtimeMinutes: 124,
    rating: 4.5,
    ratingCount: 1245,
    tags: ['로맨스', '드라마', '감동적인'],
    synopsis:
        '별이 쏟아지는 산마을에서 다시 만난 두 사람이 서로에게 남긴 약속을 되짚어 가는 이야기입니다. '
        '하룻밤 동안 이어지는 대화 속에서 오래 묻어 둔 마음이 조금씩 모습을 드러냅니다.',
  ),
  Movie(
    id: 2,
    title: '우주의 끝에서',
    genre: 'SF',
    year: 2024,
    posterAsset: 'assets/images/posters/poster_echoes_of_the_void.jpg',
    runtimeMinutes: 138,
    rating: 4.2,
    ratingCount: 982,
    tags: ['SF', '모험', '웅장한'],
    synopsis:
        '마지막 탐사선에 홀로 남은 항해사가 정체를 알 수 없는 신호를 따라 미지의 행성으로 향합니다. '
        '고요한 우주 한가운데서 그는 인류가 잊고 있던 질문과 마주합니다.',
  ),
  Movie(
    id: 3,
    title: '기억의 숲',
    genre: '애니메이션',
    year: 2022,
    posterAsset: 'assets/images/posters/poster_whispering_woods.jpg',
    runtimeMinutes: 102,
    rating: 4.9,
    ratingCount: 2310,
    tags: ['애니메이션', '가족', '따뜻한'],
    synopsis:
        '속삭이는 나무들이 사는 숲에 길을 잃은 소녀가 들어서며 시작되는 모험입니다. '
        '숲의 친구들과 함께 잃어버린 기억의 조각을 하나씩 찾아 나섭니다.',
  ),
  Movie(
    id: 4,
    title: '밤의 그림자',
    genre: '스릴러',
    year: 2023,
    posterAsset: 'assets/images/posters/poster_night_shadows.jpg',
    runtimeMinutes: 116,
    rating: 3.8,
    ratingCount: 754,
    tags: ['스릴러', '미스터리', '긴장감'],
    synopsis:
        '비가 그치지 않는 도시에서 연이어 사라지는 사람들을 쫓는 형사의 이야기입니다. '
        '골목마다 드리운 그림자 속에서 진실은 점점 더 가까워집니다.',
  ),
  Movie(
    id: 5,
    title: '봄날의 커피',
    genre: '로맨스',
    year: 2021,
    posterAsset: 'assets/images/posters/poster_fourth_afternoon.jpg',
    runtimeMinutes: 108,
    rating: 4.3,
    ratingCount: 1102,
    tags: ['로맨스', '일상', '잔잔한'],
    synopsis:
        '매주 네 번째 오후마다 같은 카페에 들르는 두 사람이 조금씩 가까워지는 이야기입니다. '
        '커피 한 잔의 시간이 쌓여 계절이 바뀌어 갑니다.',
  ),
  Movie(
    id: 6,
    title: '어비스 워커',
    genre: '판타지',
    year: 2024,
    posterAsset: 'assets/images/posters/poster_abyss_walker.jpg',
    runtimeMinutes: 131,
    rating: 4.6,
    ratingCount: 1530,
    tags: ['판타지', '액션', '모험'],
    synopsis:
        '심연의 문을 지키는 마지막 수호자가 무너져 가는 세계를 구하기 위해 금지된 길을 걷습니다. '
        '빛이 닿지 않는 곳에서 그는 자신의 운명과 맞서야 합니다.',
  ),
];

Movie? findMovieById(int? id) {
  for (final movie in movies) {
    if (movie.id == id) return movie;
  }
  return null;
}
