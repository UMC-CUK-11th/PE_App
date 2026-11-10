import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../theme/app_colors.dart';

class MovieRatingInput extends StatelessWidget {
  const MovieRatingInput({
    required this.rating,
    required this.onChanged,
    this.allowHalfRating = true,
    super.key,
  });

  final double rating;
  final ValueChanged<double> onChanged;
  final bool allowHalfRating;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: ValueKey(rating),
      child: RatingBar.builder(
        initialRating: rating,
        minRating: allowHalfRating ? 0.5 : 1,
        allowHalfRating: allowHalfRating,
        itemCount: 5,
        itemSize: 40,
        glow: false,
        unratedColor: AppColors.outlineVariant,
        itemPadding: const EdgeInsets.symmetric(horizontal: 4),
        itemBuilder: (context, index) =>
            const Icon(Icons.star, color: AppColors.violet),
        onRatingUpdate: onChanged,
      ),
    );
  }
}
