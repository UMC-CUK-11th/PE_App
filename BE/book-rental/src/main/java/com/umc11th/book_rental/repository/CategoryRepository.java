package com.umc11th.book_rental.repository;

import com.umc11th.book_rental.entity.Category;
import org.springframework.data.jpa.repository.JpaRepository;

// [04_필수 미션 1] categoryId 존재 여부를 확인하기 위한 JPA Repository
public interface CategoryRepository extends JpaRepository<Category, Long> {
}
