import 'package:flutter/material.dart';

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
      leading: onBack == null
          ? null
          : IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
              tooltip: '뒤로 가기',
            ),
      actions: actions,
    );
  }
}
