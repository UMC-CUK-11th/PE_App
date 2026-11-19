package com.umc.movie.service;

import com.umc.movie.dto.FavoriteResponse;
import com.umc.movie.entity.Favorite;
import com.umc.movie.exception.ApiException;
import com.umc.movie.repository.FavoriteRepository;
import com.umc.movie.repository.MemberRepository;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class FavoriteService {
    private final FavoriteRepository favorites;
    private final MemberRepository members;

    @Transactional
    public FavoriteResponse create(Long memberId, Long movieId) {
        var member = members.findById(memberId).orElseThrow(FavoriteService::memberNotFound);
        if (favorites.existsByMember_MemberIdAndMovieId(memberId, movieId)) {
            throw new ApiException(HttpStatus.CONFLICT, "FAVORITE409_1", "이미 이 영화를 즐겨찾기하셨습니다.");
        }
        return FavoriteResponse.from(favorites.saveAndFlush(new Favorite(member, movieId)));
    }

    @Transactional(readOnly = true)
    public List<FavoriteResponse> list(Long memberId) {
        verifyMember(memberId);
        return favorites.findByMember_MemberIdOrderByCreatedAtDescFavoriteIdDesc(memberId)
            .stream().map(FavoriteResponse::from).toList();
    }

    @Transactional(readOnly = true)
    public boolean isFavorite(Long memberId, Long movieId) {
        verifyMember(memberId);
        return favorites.existsByMember_MemberIdAndMovieId(memberId, movieId);
    }

    @Transactional
    public void delete(Long memberId, Long movieId) {
        verifyMember(memberId);
        if (favorites.deleteOwnedMovie(memberId, movieId) == 0) {
            throw new ApiException(HttpStatus.NOT_FOUND, "FAVORITE404_1", "해당 즐겨찾기를 찾을 수 없습니다.");
        }
    }

    private void verifyMember(Long memberId) {
        if (!members.existsById(memberId)) throw memberNotFound();
    }

    private static ApiException memberNotFound() {
        return new ApiException(HttpStatus.NOT_FOUND, "MEMBER404_1", "해당 회원을 찾을 수 없습니다.");
    }
}
