package com.umc.movie.repository;

import com.umc.movie.entity.Favorite;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface FavoriteRepository extends JpaRepository<Favorite, Long> {
    boolean existsByMember_MemberIdAndMovieId(Long memberId, Long movieId);

    List<Favorite> findByMember_MemberIdOrderByCreatedAtDescFavoriteIdDesc(Long memberId);

    @Modifying
    @Query("""
        delete from Favorite f where f.member.memberId = :memberId and f.movieId = :movieId
        """)
    int deleteOwnedMovie(@Param("memberId") Long memberId, @Param("movieId") Long movieId);
}
