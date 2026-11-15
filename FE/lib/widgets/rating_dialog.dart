import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../models/common_response.dart';
import '../models/rating_request.dart';
import 'movie_rating_input.dart';

class RatingDialog extends StatefulWidget {
  const RatingDialog({
    required this.onSubmit,
    this.initialRating = 0,
    this.initialComment,
    super.key,
  });

  final double initialRating;
  final String? initialComment;
  final Future<void> Function(RatingInput) onSubmit;

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  late double _rating = widget.initialRating;
  late final _comment = TextEditingController(
    text: widget.initialComment ?? '',
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || _rating == 0) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final text = _comment.text.trim();
      final input = RatingInput(
        _rating.toInt(),
        _comment.text == (widget.initialComment ?? '') ? null : text,
      );
      await widget.onSubmit(input);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = ApiFailure.from(error, '평점을 저장하지 못했습니다.').message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: Dialog(
        backgroundColor: AppColors.warmWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
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
              IgnorePointer(
                ignoring: _saving,
                child: MovieRatingInput(
                  rating: _rating,
                  allowHalfRating: false,
                  onChanged: (value) => setState(() => _rating = value),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _rating == 0
                    ? const SizedBox(height: 36)
                    : SizedBox(
                        height: 36,
                        child: TextButton(
                          key: const ValueKey('reset-rating-button'),
                          onPressed: _saving
                              ? null
                              : () => setState(() => _rating = 0),
                          child: const Text('다시 선택하기'),
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _comment,
                readOnly: _saving,
                maxLength: 500,
                maxLines: 3,
                decoration: const InputDecoration(labelText: '코멘트 (선택)'),
              ),
              if (_error case final message?)
                Text(message, style: const TextStyle(color: AppColors.error)),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saving || _rating == 0 ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.violet,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor: AppColors.disabledButton,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('확인'),
                ),
              ),
              TextButton(
                onPressed: _saving
                    ? null
                    : () => Navigator.of(context).pop(false),
                child: const Text('취소'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
