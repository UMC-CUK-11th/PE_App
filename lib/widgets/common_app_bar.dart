import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CommonAppBar({
    required this.title,
    this.onBack,
    this.actions,
    this.centerTitle = false,
    this.titleStyle,
    super.key,
  });

  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final bool centerTitle;
  final TextStyle? titleStyle;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: preferredSize.height,
      titleSpacing: 16,
      title: Text(title, style: titleStyle ?? AppTextStyles.profileTitle),
      centerTitle: centerTitle,
      leadingWidth: onBack == null ? null : 56,
      leading: onBack == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox.square(
                  dimension: 40,
                  child: IconButton(
                    onPressed: onBack,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 40,
                      height: 40,
                    ),
                    icon: Transform.translate(
                      offset: const Offset(0, -2),
                      child: SvgPicture.asset(
                        'assets/icons/arrow_back.svg',
                        key: const ValueKey('common-app-bar-back-icon'),
                        width: 16,
                        height: 16,
                        colorFilter: const ColorFilter.mode(
                          AppColors.onSurfaceVariant,
                          BlendMode.srcIn,
                        ),
                        semanticsLabel: '뒤로 가기',
                      ),
                    ),
                    tooltip: '뒤로 가기',
                  ),
                ),
              ),
            ),
      actions: actions,
    );
  }
}
