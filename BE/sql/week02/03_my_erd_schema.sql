-- 확장: 1주차 내 ERD(지역별 가게 미션 리워드 서비스) 중 미션 화면 관련 테이블
-- 공통 실습 DB와 섞이지 않도록 별도 DB에서 실행
CREATE TABLE region (
    region_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name      VARCHAR(20) NOT NULL
);

CREATE TABLE food_category (
    food_category_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name             VARCHAR(20) NOT NULL
);

CREATE TABLE member (
    member_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    nickname  VARCHAR(30) NOT NULL,
    point     INT NOT NULL DEFAULT 0
);

CREATE TABLE store (
    store_id         BIGINT PRIMARY KEY AUTO_INCREMENT,
    region_id        BIGINT NOT NULL,
    food_category_id BIGINT NOT NULL,
    name             VARCHAR(50) NOT NULL,
    address          VARCHAR(100) NOT NULL,
    FOREIGN KEY (region_id) REFERENCES region (region_id),
    FOREIGN KEY (food_category_id) REFERENCES food_category (food_category_id)
);

CREATE TABLE mission (
    mission_id   BIGINT PRIMARY KEY AUTO_INCREMENT,
    store_id     BIGINT NOT NULL,
    min_price    INT NOT NULL,
    reward_point INT NOT NULL,
    deadline     DATETIME NOT NULL,
    FOREIGN KEY (store_id) REFERENCES store (store_id)
);

CREATE TABLE member_mission (
    member_mission_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    member_id         BIGINT NOT NULL,
    mission_id        BIGINT NOT NULL,
    status            VARCHAR(15) NOT NULL, -- CHALLENGING / COMPLETE
    created_at        DATETIME NOT NULL,
    FOREIGN KEY (member_id) REFERENCES member (member_id),
    FOREIGN KEY (mission_id) REFERENCES mission (mission_id)
);
