import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../data/models/rating_request.dart';
import '../data/services/rating_api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'movie_rating_input.dart';
import 'movielog_button.dart';

/// 평점 등록·수정 공용 Dialog. 저장까지 마치면 true, 취소하면 false를 돌려줍니다.
/// 저장 중에는 PopScope로 뒤로가기를 막습니다. 바깥 탭은 showDialog의
/// barrierDismissible: false로 함께 막아야 합니다.
class RatingDialog extends StatefulWidget {
  const RatingDialog({
    super.key,
    this.initialScore = 0,
    this.initialComment,
    required this.onSubmit,
  });

  final int initialScore;
  final String? initialComment;

  /// 실패하면 예외를 던집니다. Dialog가 잡아 안내하고 다시 시도할 수 있게 둡니다.
  final Future<void> Function(int score, String? comment) onSubmit;

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  static const _maxCommentLength = 500;

  late int _score = widget.initialScore;
  // build마다 새로 만들면 별점을 고를 때 입력 중인 코멘트가 사라집니다.
  late final _commentController = TextEditingController(
    text: widget.initialComment ?? '',
  );
  int _resetCount = 0;
  bool _isSubmitting = false;
  String? _errorText;

  bool get _hasScore => _score > 0;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _score = 0;
      _resetCount += 1;
    });
  }

  Future<void> _onConfirm() async {
    final trimmed = _commentController.text.trim();
    if (trimmed.length > _maxCommentLength) {
      setState(() => _errorText = '코멘트는 500자 이하로 입력해 주세요.');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      await widget.onSubmit(_score, trimmed.isEmpty ? null : trimmed);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      // 실패해도 로딩을 풀어야 다시 시도할 수 있습니다. 입력값은 그대로 둡니다.
      setState(() {
        _isSubmitting = false;
        _errorText = switch (error) {
          DioException() => writeErrorMessage(error),
          StateError(:final message) => message,
          _ => '저장하지 못했습니다. 잠시 후 다시 시도해 주세요.',
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final errorText = _errorText;

    return PopScope(
      canPop: !_isSubmitting,
      child: Dialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '영화는 어떠셨나요?',
                style: AppTextStyles.titleMedium.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 24),
              MovieRatingInput(
                key: ValueKey(_resetCount),
                rating: _score.toDouble(),
                enabled: !_isSubmitting,
                onChanged: (value) {
                  setState(() => _score = validateServerScore(value));
                },
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: _hasScore && !_isSubmitting
                    ? TextButton(
                        onPressed: _reset,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.violet,
                        ),
                        child: const Text('다시 선택하기'),
                      )
                    : null,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                enabled: !_isSubmitting,
                maxLines: 3,
                maxLength: _maxCommentLength,
                decoration: InputDecoration(
                  hintText: '코멘트를 남겨보세요 (선택)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (errorText != null) ...[
                const SizedBox(height: 8),
                Text(
                  errorText,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: TextButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.violet,
                        ),
                        child: const Text('취소'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MovieLogButton(
                      label: '확인',
                      width: double.infinity,
                      height: 52,
                      isLoading: _isSubmitting,
                      onPressed: _hasScore ? _onConfirm : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
