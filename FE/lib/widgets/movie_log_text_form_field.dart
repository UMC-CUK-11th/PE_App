import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class MovieLogTextFormField extends StatelessWidget {
  const MovieLogTextFormField({
    required this.label,
    required this.hintText,
    required this.controller,
    required this.focusNode,
    required this.validator,
    required this.onChanged,
    required this.textInputAction,
    this.keyboardType,
    this.onFieldSubmitted,
    this.isCompact = false,
    this.isValid = false,
    this.showError = false,
    this.obscureText = false,
    this.onToggleObscure,
    this.inputFontWeight = FontWeight.w400,
    this.hintFontWeight = FontWeight.w500,
    super.key,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final FocusNode focusNode;
  final FormFieldValidator<String> validator;
  final ValueChanged<String> onChanged;
  final TextInputAction textInputAction;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onFieldSubmitted;
  final bool isCompact;
  final bool isValid;
  final bool showError;
  final bool obscureText;
  final VoidCallback? onToggleObscure;
  final FontWeight inputFontWeight;
  final FontWeight hintFontWeight;

  @override
  Widget build(BuildContext context) {
    final validationMessage = showError ? validator(controller.text) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: isCompact
              ? AppTextStyles.fieldLabelCompact
              : AppTextStyles.fieldLabel,
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          validator: validator,
          errorBuilder: isCompact
              ? (context, errorText) => const SizedBox.shrink()
              : null,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          textAlignVertical: TextAlignVertical.center,
          style:
              (isCompact
                      ? AppTextStyles.inputTextCompact
                      : AppTextStyles.inputText)
                  .copyWith(fontWeight: inputFontWeight),
          cursorColor: AppColors.violet,
          decoration: InputDecoration(
            constraints: isCompact
                ? const BoxConstraints.tightFor(height: 42)
                : const BoxConstraints(minHeight: 42),
            isDense: true,
            hintText: hintText,
            hintStyle:
                (isCompact
                        ? AppTextStyles.inputHintCompact
                        : AppTextStyles.inputHint)
                    .copyWith(fontWeight: hintFontWeight),
            filled: true,
            fillColor: showError
                ? AppColors.errorContainer
                : AppColors.statBackground,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            suffixIcon: _buildSuffixIcon(),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 52,
              minHeight: 42,
            ),
            enabledBorder: _border(
              isCompact
                  ? AppColors.compactFieldOutline
                  : AppColors.fieldOutline,
            ),
            focusedBorder: _border(AppColors.violet),
            errorBorder: _border(AppColors.error),
            focusedErrorBorder: _border(AppColors.error),
            errorStyle: AppTextStyles.errorText,
            errorMaxLines: 2,
          ),
        ),
        if (isCompact)
          SizedBox(
            height: 20,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                validationMessage ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.errorText,
              ),
            ),
          ),
      ],
    );
  }

  OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color),
    );
  }

  Widget? _buildSuffixIcon() {
    if (showError) {
      return _StatusIcon(
        assetPath: 'assets/icons/error.svg',
        color: AppColors.error,
        semanticsLabel: '$label 입력 오류',
      );
    }

    if (onToggleObscure != null) {
      return ListenableBuilder(
        listenable: focusNode,
        builder: (context, child) {
          if (isValid && !focusNode.hasFocus) {
            return _StatusIcon(
              key: const ValueKey('password-valid-icon'),
              assetPath: 'assets/icons/check_circle.svg',
              color: AppColors.violet,
              semanticsLabel: '$label 입력 완료',
            );
          }

          return _buildObscureToggle();
        },
      );
    }

    if (isValid) {
      return _StatusIcon(
        assetPath: 'assets/icons/check_circle.svg',
        color: AppColors.violet,
        semanticsLabel: '$label 입력 완료',
      );
    }

    // Keep compact fields the same visual height before a status icon appears.
    // Without this placeholder, Flutter paints fields without a suffix icon
    // shorter than the password field, whose visibility icon is 42px high.
    if (isCompact) {
      return const SizedBox(width: 52, height: 42);
    }

    return null;
  }

  Widget _buildObscureToggle() {
    final tooltip = obscureText ? '비밀번호 표시' : '비밀번호 숨기기';

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: InkWell(
          onTap: onToggleObscure,
          child: SizedBox(
            width: 52,
            height: 42,
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: SvgPicture.asset(
                  obscureText
                      ? 'assets/icons/visibility_off.svg'
                      : 'assets/icons/visibility.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    AppColors.onSurfaceVariant,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({
    super.key,
    required this.assetPath,
    required this.color,
    required this.semanticsLabel,
  });

  final String assetPath;
  final Color color;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 42,
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: SvgPicture.asset(
            assetPath,
            width: 18,
            height: 18,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            semanticsLabel: semanticsLabel,
          ),
        ),
      ),
    );
  }
}
