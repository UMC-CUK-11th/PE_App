import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../theme/app_colors.dart';

/// 서버 평점은 1~5 정수라 반 점 없이 한 칸 단위로만 고릅니다.
class MovieRatingInput extends StatelessWidget {
  const MovieRatingInput({
    super.key,
    required this.rating,
    required this.onChanged,
    this.enabled = true,
  });

  final double rating;
  final ValueChanged<double> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return RatingBar.builder(
      initialRating: rating,
      minRating: 1,
      allowHalfRating: false,
      ignoreGestures: !enabled,
      itemCount: 5,
      itemSize: 40,
      glow: false,
      unratedColor: AppColors.violetDisabled,
      itemBuilder: (context, index) {
        return const Icon(Icons.star, color: AppColors.violet);
      },
      onRatingUpdate: onChanged,
    );
  }
}
