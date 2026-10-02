package com.umc11th.repository;

import com.umc11th.entity.Category;
import org.springframework.data.jpa.repository.JpaRepository;

// [04_필수 미션 1] categoryId 존재 여부를 확인하기 위한 JPA Repository
public interface CategoryRepository extends JpaRepository<Category, Long> {
}
