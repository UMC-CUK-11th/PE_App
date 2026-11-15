import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class MovieLogTextFormField extends StatelessWidget {
  const MovieLogTextFormField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    required this.validator,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.onChanged,
    this.onFieldSubmitted,
    this.trailing,
    this.errorText,
    this.helperText,
    this.action,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final String? Function(String value) validator;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final Widget? trailing;

  /// 서버 응답처럼 로컬 validator 밖에서 정해지는 에러 문구입니다.
  final String? errorText;

  /// 에러가 아닐 때 입력창 아래 보여 줄 안내 문구입니다.
  final String? helperText;

  /// 입력창 바깥 오른쪽에 8px 간격으로 붙는 위젯(예: 중복 확인 버튼)입니다.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final hasInput = controller.text.isNotEmpty;
    final hasError =
        (hasInput && validator(controller.text) != null) || errorText != null;
    final isValid = hasInput && !hasError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelLarge),
        const SizedBox(height: 8),
        _withAction(
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            obscureText: obscureText,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            style: AppTextStyles.bodyMedium,
            validator: (value) => validator(value ?? ''),
            onChanged: onChanged,
            onFieldSubmitted: onFieldSubmitted,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.gray,
              ),
              filled: true,
              fillColor: hasError
                  ? AppColors.errorContainer
                  : AppColors.surfaceLow,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              errorStyle: AppTextStyles.errorCaption,
              errorText: errorText,
              helperText: helperText,
              helperStyle: AppTextStyles.bodySmall.copyWith(
                color: AppColors.violet,
              ),
              suffixIcon: _buildSuffix(hasError: hasError, isValid: isValid),
              enabledBorder: _border(AppColors.outline),
              focusedBorder: _border(AppColors.violet, width: 2),
              errorBorder: _border(AppColors.error),
              focusedErrorBorder: _border(AppColors.error, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  // TextFormField와 action은 Row의 형제로 두어 체크 표시(입력창 안)와 버튼(바깥)이 겹치지 않게 합니다.
  Widget _withAction(Widget field) {
    final action = this.action;
    if (action == null) return field;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: field),
        const SizedBox(width: 8),
        Padding(padding: const EdgeInsets.only(top: 2), child: action),
      ],
    );
  }

  Widget? _buildSuffix({required bool hasError, required bool isValid}) {
    final Widget? statusIcon = hasError
        ? const Icon(Icons.error_outline, color: AppColors.error)
        : isValid
        ? const Icon(Icons.check_circle, color: AppColors.violet)
        : null;

    if (trailing == null) return statusIcon;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [?statusIcon, trailing!],
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
