-- MySQL 8.0, 새 movie 스키마에 한 번 실행하는 초기 테이블 정의.
-- 실행 예: mysql -u root -p movie 접속 후 SOURCE sql/create-tables.sql;
-- 기존 테이블을 삭제하거나 덮어쓰지 않습니다.
CREATE TABLE member (
    member_id BIGINT NOT NULL AUTO_INCREMENT,
    email VARCHAR(254) NOT NULL,
    password VARCHAR(60) NOT NULL,
    nickname VARCHAR(50) NOT NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    PRIMARY KEY (member_id),
    CONSTRAINT uk_member_email UNIQUE (email),
    CONSTRAINT uk_member_nickname UNIQUE (nickname)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE rating (
    rating_id BIGINT NOT NULL AUTO_INCREMENT,
    member_id BIGINT NOT NULL,
    movie_id BIGINT NOT NULL,
    score TINYINT NOT NULL,
    comment TEXT,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    PRIMARY KEY (rating_id),
    CONSTRAINT uk_rating_member_movie UNIQUE (member_id, movie_id),
    CONSTRAINT fk_rating_member FOREIGN KEY (member_id) REFERENCES member (member_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
