# 6주차 — 중복 확인과 평점 조회

## 실행
- 실제 앱: flutter run -d web-server --release --web-port 6176
- 검증 전용 합성 응답 화면: flutter run -d web-server -t tool/week06_preview.dart --release --web-port 6177
- 검증 화면은 실제 API 결과가 아니며 main.dart 앱에 등록되지 않습니다.

## 역할
- models/check_result.dart, rating_dto.dart: v5의 wrapper 없는 JSON 응답 모델. null 후기 처리.
- services/movie_log_client.dart: workbook.devnoco.com 전용 Dio. TMDB Bearer 토큰을 전달하지 않음.
- member_check_service.dart / rating_api_service.dart: 같은 워크북 클라이언트 공유.
- view_models/signup_view_model.dart: 입력별 독립 요청 버전, 중복값 기억, 입력 변경 무효화, 늦은 응답 무시.
- widgets/movielog_button.dart: 기본/회색 로딩/비활성 및 가변/전체/고정 너비.
- sign_up_screen.dart: 기존 2주차 Form 보존, 필드 밖 8px 간격의 중복 확인 버튼, 서버 오류 연결.
- view_models/my_ratings_view_model.dart: memberId=1, Loading/Empty/Error/Success, 영화 ID 중복 조회 방지·캐시.
- screens/my_ratings_screen.dart: TMDB 제목·포스터와 점수·후기·등록일. null 후기는 대체 문구.
- profile_screen.dart / router/app_router.dart: context.push('/my/ratings'), 뒤로 복귀, 하단 탭 없는 평점 화면.

## 범위
이름이 회원가입이더라도 v5에서는 POST 요청을 보내지 않습니다. 모든 Form 입력과 약관, 두 중복 확인이 유효할 때 홈으로 이동합니다. 평점은 로그인한 본인이 아닌 공개 학습용 회원 1번입니다.

## 검증 결과 (2026-11-03)
- flutter test --no-pub: 기존 40개 + PR 피드백 회귀 테스트 14개 = 54개 통과.
- flutter analyze --no-pub: No issues found.
- 실제 브라우저: 수현·홀란드 닉네임과 테스트 이메일 사용 가능 응답, 입력 변경 무효화, Form 완료 후 홈 이동.
- 실제 브라우저: 마이 → 평점 → 뒤로 복귀, 평점 3건, 포레스트 검프/펄프 픽션/파이트 클럽 제목·포스터 확인.
- 합성 응답: 제임스 및 test@example.com 중복, 중복 재입력 즉시 에러, 2초 로딩, 통신 실패, 평점 Loading/Empty/Error, 버튼 너비 비교.
- 자동 테스트: 중복 재입력 시 추가 요청 없음, 이전 요청 및 dispose 이후 응답 무시, 영화 상세 일부 실패 시 평점 유지, 오류 후 재시도 성공.

소스 수정 전 백업은 ChatGPT 작업 폴더의 week06-work/before에 보관했습니다. 코드 저장소: https://github.com/leejeonghwan9920/PE_App/tree/week06/FE (week06 브랜치). PR: https://github.com/UMC-CUK-11th/PE_App/pull/18. 현재 제출 범위는 FE·BE이며, FE는 v5 워크북 API, BE는 별도 로컬 Spring Boot API로 실습합니다.


## PR 18 피드백 반영 (2026-11-03)
- 장르 URL 쿼리 변경에 맞춰 Provider를 다시 생성해 브라우저 경로 복원 시 목록을 동기화합니다. 쿼리가 없으면 저장된 설정을 복원합니다.
- 이전 버전에서 저장한 장르 이름을 TMDB ID로 변환하며 URL에 명시한 장르를 우선합니다.
- 목록 데이터의 상영 시간이 0이면 상세 API를 조회합니다. TMDB 404는 영화 없음 안내로 표시합니다.
- 인기 영화의 배지를 ‘추천 영화’로 바꾸고 장르 API만 실패하면 기타 장르로 인기 목록을 계속 표시합니다.
- 평점 새로고침 중 기존 목록과 RefreshIndicator를 유지합니다. 영화 상세는 중복·캐시를 제외하고 최대 5개씩 조회하며, 화면 폐기 시 CancelToken을 취소하고 다음 묶음을 시작하지 않습니다.
- 닉네임·이메일에서 앞뒤 공백만 바뀌면 진행 중 요청과 기존 중복 확인 결과를 유지합니다.
- macOS Debug/Profile에도 아웃바운드 네트워크 entitlement를 추가했습니다. Windows 환경이므로 macOS 실행 검증은 수행하지 않았습니다.
- 합성 응답 프리뷰에 GoRouter와 검증 완료 화면을 제공해 회원가입 폼 완료 후 이동을 확인할 수 있습니다.
- 실제 MemberCheckService 이메일 경로·인코딩·응답, RatingApiService 회원별 경로·목록 디코딩을 Dio 어댑터로 검증합니다.
- 자동 검증: 전체 flutter test 54개 통과. URL 경로 복원, 상세 재조회, 새로고침 목록 유지, 요청 묶음·취소, 프리뷰 폼 완료까지 회귀 테스트로 확인했습니다.
