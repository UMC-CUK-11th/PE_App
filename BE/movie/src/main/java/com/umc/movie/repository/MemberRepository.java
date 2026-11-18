package com.umc.movie.repository;

import com.umc.movie.entity.Member;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface MemberRepository extends JpaRepository<Member, Long> {

    boolean existsByNickname(String nickname);

    boolean existsByEmail(String email);

    Optional<Member> findByEmail(String email);

    // 내 정보 수정: 다른 회원이 이미 쓰는 닉네임인지(자기 자신 제외)
    boolean existsByNicknameAndMemberIdNot(String nickname, Long memberId);
}
