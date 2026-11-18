-- Run on the movie schema after the member table exists.
CREATE TABLE IF NOT EXISTS favorite (
    favorite_id BIGINT NOT NULL AUTO_INCREMENT,
    member_id BIGINT NOT NULL,
    movie_id BIGINT NOT NULL,
    created_at DATETIME(6) NOT NULL,
    PRIMARY KEY (favorite_id),
    CONSTRAINT uk_favorite_member_movie UNIQUE (member_id, movie_id),
    CONSTRAINT fk_favorite_member FOREIGN KEY (member_id) REFERENCES member (member_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
