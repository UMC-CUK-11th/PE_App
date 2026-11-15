import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'movie_rating_input.dart';
import 'app_button.dart';

typedef RatingSubmitCallback = Future<void> Function(
  int score,
  String? comment,
);

class RatingDialog extends StatefulWidget {
  const RatingDialog({
    required this.movieId,
    required this.onSubmit,
    this.initialScore = 0,
    this.initialComment,
    super.key,
  });

  final int movieId;
  final RatingSubmitCallback onSubmit;
  final int initialScore;
  final String? initialComment;

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  late int _score = widget.initialScore;
  late final TextEditingController _commentController = TextEditingController(
    text: widget.initialComment ?? '',
  );
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_score == 0 || _isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await widget.onSubmit(_score, _commentController.text);
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = error is StateError
            ? error.message.toString()
            : '요청에 실패했습니다. 다시 시도해 주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSubmitting,
      child: Dialog(
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
                rating: _score.toDouble(),
                onChanged: (value) => setState(() => _score = value.round()),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _score == 0
                    ? const SizedBox(height: 36)
                    : SizedBox(
                        height: 36,
                        child: TextButton(
                          key: const ValueKey('reset-rating-button'),
                          onPressed: _isSubmitting
                              ? null
                              : () => setState(() => _score = 0),
                          child: const Text('다시 선택하기'),
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('rating-comment-field'),
                controller: _commentController,
                enabled: !_isSubmitting,
                maxLength: 500,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: '영화에 대한 한줄평을 남겨주세요. (선택)',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
              const SizedBox(height: 12),
              AppButton(
                label: '확인',
                isLoading: _isSubmitting,
                onPressed: _score == 0 || _isSubmitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
