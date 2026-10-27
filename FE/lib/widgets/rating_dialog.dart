import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'movie_rating_input.dart';

class RatingDialog extends StatefulWidget {
  const RatingDialog({this.initialRating = 0, super.key});

  final double initialRating;

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  late double _rating = widget.initialRating;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.warmWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '영화는 어떠셨나요?',
              style: TextStyle(
                color: AppColors.onSurface,
                fontSize: 20,
                height: 28 / 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            MovieRatingInput(
              rating: _rating,
              onChanged: (value) => setState(() => _rating = value),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _rating == 0
                  ? const SizedBox(height: 36)
                  : SizedBox(
                      height: 36,
                      child: TextButton(
                        key: const ValueKey('reset-rating-button'),
                        onPressed: () => setState(() => _rating = 0),
                        child: const Text('다시 선택하기'),
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _rating == 0
                    ? null
                    : () => Navigator.of(context).pop(_rating),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.violet,
                  foregroundColor: AppColors.white,
                  disabledBackgroundColor: AppColors.disabledButton,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('확인'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
