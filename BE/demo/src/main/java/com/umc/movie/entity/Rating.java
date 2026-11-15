// src/main/java/com/umc/movie/entity/Rating.java
package com.umc.movie.entity;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "rating", uniqueConstraints = @UniqueConstraint(name="uk_rating_member_movie", columnNames = {"member_id", "movie_id"}))
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Rating extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "rating_id")
    private Long ratingId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "member_id", nullable = false)
    private Member member;

    @Column(name = "movie_id", nullable = false)
    private Long movieId;

    @Column(nullable = false, columnDefinition = "TINYINT")
    private Integer score;

    @Column(columnDefinition = "TEXT")
    private String comment;

    public Rating(Member member, Long movieId, Integer score, String comment) {
        this.member = member; this.movieId = movieId; this.score = score; this.comment = comment;
    }
    /**
     * 검증된 별점을 갱신하고 요청에 후기 문자열이 있는 경우에만 후기를 변경합니다.
     *
     * @param score 요청 DTO에서 1~5 범위로 검증된 별점
     * @param comment null이면 기존 후기 유지, 빈 문자열이면 비우기, 그 외에는 새 후기
     */
    public void update(Integer score, String comment) {
        this.score = score;
        // PATCH에서 생략 또는 null은 유지, 빈 문자열은 후기 비우기입니다.
        if (comment != null) this.comment = comment;
    }
}