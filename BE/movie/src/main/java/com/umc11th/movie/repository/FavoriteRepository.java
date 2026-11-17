package com.umc11th.movie.repository;

import com.umc11th.movie.entity.Favorite;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface FavoriteRepository extends JpaRepository<Favorite, Long> {

    List<Favorite> findByMemberMemberIdOrderByFavoriteIdDesc(Long memberId);

    Optional<Favorite> findByMemberMemberIdAndMovieId(Long memberId, Long movieId);

    boolean existsByMemberMemberIdAndMovieId(Long memberId, Long movieId);
}
