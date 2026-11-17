package com.umc11th.movie.service;

import com.umc11th.movie.dto.CreateFavoriteRequest;
import com.umc11th.movie.dto.FavoriteResponse;
import com.umc11th.movie.dto.FavoriteStatusResponse;
import com.umc11th.movie.entity.Favorite;
import com.umc11th.movie.entity.Member;
import com.umc11th.movie.exception.ApiException;
import com.umc11th.movie.repository.FavoriteRepository;
import com.umc11th.movie.repository.MemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class FavoriteService {

    private final FavoriteRepository favoriteRepository;
    private final MemberRepository memberRepository;

    @Transactional
    public FavoriteResponse create(Long memberId, CreateFavoriteRequest request) {
        Member member = findMember(memberId);
        validateNotDuplicate(memberId, request.movieId());
        Favorite favorite = favoriteRepository.save(new Favorite(member, request.movieId()));
        return FavoriteResponse.from(favorite);
    }

    @Transactional(readOnly = true)
    public List<FavoriteResponse> getMyFavorites(Long memberId) {
        return favoriteRepository.findByMemberMemberIdOrderByFavoriteIdDesc(memberId)
                .stream()
                .map(FavoriteResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public FavoriteStatusResponse getStatus(Long memberId, Long movieId) {
        return new FavoriteStatusResponse(
                favoriteRepository.existsByMemberMemberIdAndMovieId(memberId, movieId)
        );
    }

    @Transactional
    public void delete(Long memberId, Long movieId) {
        Favorite favorite = favoriteRepository
                .findByMemberMemberIdAndMovieId(memberId, movieId)
                .orElseThrow(() -> new ApiException(
                        HttpStatus.NOT_FOUND,
                        "FAVORITE404_1",
                        "즐겨찾기한 영화를 찾을 수 없습니다."
                ));
        favoriteRepository.delete(favorite);
    }

    private Member findMember(Long memberId) {
        return memberRepository.findById(memberId)
                .orElseThrow(() -> new ApiException(
                        HttpStatus.NOT_FOUND,
                        "MEMBER404_1",
                        "해당 회원을 찾을 수 없습니다."
                ));
    }

    private void validateNotDuplicate(Long memberId, Long movieId) {
        if (favoriteRepository.existsByMemberMemberIdAndMovieId(memberId, movieId)) {
            throw new ApiException(
                    HttpStatus.CONFLICT,
                    "FAVORITE409_1",
                    "이미 이 영화를 즐겨찾기하셨습니다."
            );
        }
    }
}
