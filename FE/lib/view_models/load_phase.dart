/// idle: 요청 전 / loading: 첫 page(또는 새 조건) 로딩 / ready: 표시할 목록 있음
/// empty: 성공했지만 결과 없음 / error: 첫 조회 실패.
/// 다음 page 로딩은 목록을 지우지 않고 isLoadingMore로 따로 구분합니다.
enum LoadPhase { idle, loading, ready, empty, error }
