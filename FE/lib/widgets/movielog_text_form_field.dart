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

  @override
  Widget build(BuildContext context) {
    final hasInput = controller.text.isNotEmpty;
    final hasError = hasInput && validator(controller.text) != null;
    final isValid = hasInput && !hasError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelLarge),
        const SizedBox(height: 8),
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
            hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray),
            filled: true,
            fillColor: hasError ? AppColors.errorContainer : AppColors.surfaceLow,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            errorStyle: AppTextStyles.errorCaption,
            suffixIcon: _buildSuffix(hasError: hasError, isValid: isValid),
            enabledBorder: _border(AppColors.outline),
            focusedBorder: _border(AppColors.violet, width: 2),
            errorBorder: _border(AppColors.error),
            focusedErrorBorder: _border(AppColors.error, width: 2),
          ),
        ),
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
      children: [
        ?statusIcon,
        trailing!,
      ],
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
