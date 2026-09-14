class Movie {
  String title;
  String? nickname; //?를 넣으면 넣어도 안넣어도 상관 x

  Movie({required this.title, this.nickname}); //required가 붙으면 필수
}