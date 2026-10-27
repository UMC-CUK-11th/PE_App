import '../models/movie.dart';

const mockMovies = [
  Movie(
    id: 1,
    title: '별빛 아래 우리',
    genres: ['로맨스', '드라마'],
    year: 2024,
    durationMinutes: 124,
    posterAsset: 'assets/images/posters/hero_under_the_starlight.jpg',
    rating: 4.5,
    synopsis: '바쁜 일상 속에서 서로의 존재를 잊고 살아가던 두 남녀가 우연한 계기로 작은 천문대에서 만나게 됩니다. 매일 밤 별을 관측하며 서로의 상처를 치유하고, 잊고 있던 꿈과 사랑을 다시금 발견하게 되는 이야기입니다.',
  ),
  Movie(
    id: 2,
    title: '우주의 끝에서',
    genres: ['SF'],
    year: 2024,
    durationMinutes: 110,
    posterAsset: 'assets/images/posters/poster_echoes_of_the_void.jpg',
    rating: 4.2,
    synopsis: '미지의 신호를 따라 우주의 끝으로 향한 탐사대가 발견한 선택과 고독에 관한 이야기입니다.',
  ),
  Movie(
    id: 3,
    title: '기억의 숲',
    genres: ['애니메이션'],
    year: 2022,
    durationMinutes: 102,
    posterAsset: 'assets/images/posters/poster_whispering_woods.jpg',
    rating: 4.9,
    synopsis: '잊힌 기억이 나무가 되어 자라는 숲에서 작은 정령과 아이가 함께 길을 찾습니다.',
  ),
  Movie(
    id: 4,
    title: '밤의 그림자',
    genres: ['스릴러'],
    year: 2024,
    durationMinutes: 118,
    posterAsset: 'assets/images/posters/poster_night_shadows.jpg',
    rating: 3.8,
    synopsis: '비가 내리는 밤, 사라진 단서를 쫓는 형사가 도시의 오래된 비밀과 마주합니다.',
  ),
  Movie(
    id: 5,
    title: '네 번째 오후',
    genres: ['로맨스'],
    year: 2021,
    durationMinutes: 115,
    posterAsset: 'assets/images/posters/poster_fourth_afternoon.jpg',
    rating: 4.5,
    synopsis: '매주 같은 오후 카페에서 만나는 두 사람이 천천히 서로의 계절이 되어갑니다.',
  ),
  Movie(
    id: 6,
    title: '스파이 코드',
    genres: ['액션'],
    year: 2023,
    durationMinutes: 121,
    posterAsset: 'assets/images/posters/poster_abyss_walker.jpg',
    rating: 4.1,
    synopsis: '도시를 뒤흔든 암호를 풀기 위해 은퇴한 요원이 마지막 임무에 뛰어듭니다.',
  ),
];

const movieGenres = ['드라마', 'SF', '애니메이션', '스릴러', '로맨스', '다큐멘터리', '액션'];

Movie? findMovieById(int? id) {
  for (final movie in mockMovies) {
    if (movie.id == id) return movie;
  }
  return null;
}
