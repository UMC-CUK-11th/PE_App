CREATE DATABASE IF NOT EXISTS umc_movie DEFAULT CHARACTER SET utf8mb4;
USE umc_movie;

CREATE TABLE member (
    member_id  BIGINT AUTO_INCREMENT PRIMARY KEY,
    email      VARCHAR(254) NOT NULL UNIQUE,
    password   VARCHAR(60)  NOT NULL,
    nickname   VARCHAR(50)  NOT NULL UNIQUE,
    created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE rating (
    rating_id  BIGINT AUTO_INCREMENT PRIMARY KEY,
    member_id  BIGINT   NOT NULL,
    movie_id   BIGINT   NOT NULL,
    score      TINYINT  NOT NULL,
    comment    TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (member_id) REFERENCES member (member_id),
    UNIQUE KEY uk_rating_member_movie (member_id, movie_id)
);

-- 8주차 즐겨찾기. 같은 회원이 같은 영화를 두 번 담지 못하게 (member_id, movie_id) UNIQUE.
CREATE TABLE favorite (
    favorite_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    member_id   BIGINT   NOT NULL,
    movie_id    BIGINT   NOT NULL,
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (member_id) REFERENCES member (member_id),
    UNIQUE KEY uk_favorite_member_movie (member_id, movie_id)
);
