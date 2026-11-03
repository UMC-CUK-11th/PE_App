// src/main/java/com/umc/movie/repository/MemberRepository.java
package com.umc.movie.repository;

import com.umc.movie.entity.Member;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MemberRepository extends JpaRepository<Member, Long> {
    java.util.Optional<Member> findByEmail(String email);
    boolean existsByNickname(String nickname);
    boolean existsByEmail(String email);
}