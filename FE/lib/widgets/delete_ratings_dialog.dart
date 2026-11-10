import 'package:flutter/material.dart';

import '../models/common_response.dart';

class DeleteRatingsDialog extends StatefulWidget {
  const DeleteRatingsDialog({
    required this.count,
    required this.onDelete,
    super.key,
  });
  final int count;
  final Future<Map<int, ApiFailure>> Function() onDelete;

  @override
  State<DeleteRatingsDialog> createState() => _DeleteRatingsDialogState();
}

class _DeleteRatingsDialogState extends State<DeleteRatingsDialog> {
  bool _deleting = false;
  String? _error;

  Future<void> _delete() async {
    if (_deleting) return;
    setState(() => _deleting = true);
    try {
      final failures = await widget.onDelete();
      if (mounted) Navigator.of(context).pop(failures);
    } catch (error) {
      if (mounted) {
        setState(() {
          _deleting = false;
          _error = ApiFailure.from(error, '평점 삭제에 실패했습니다.').message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_deleting,
    child: AlertDialog(
      title: const Text('평점 삭제'),
      content: _deleting
          ? const Row(
              children: [
                SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('평점을 삭제하고 있어요.'),
              ],
            )
          : Text(_error ?? '선택한 평점 ${widget.count}개를 삭제할까요?'),
      actions: [
        TextButton(
          onPressed: _deleting ? null : () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _deleting ? null : _delete,
          child: const Text('삭제'),
        ),
      ],
    ),
  );
}
