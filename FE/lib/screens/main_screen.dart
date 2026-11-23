import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../view_models/auth_session.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  StatefulNavigationShell get navigationShell => widget.navigationShell;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final session = context.read<AuthSession?>();
      if (session?.memberStatus == MemberLoadStatus.idle) session!.loadMember();
    });
  }

  void _changeBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        height: 80,
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _changeBranch,
        destinations: const [
          NavigationDestination(
            icon: _NavigationIcon(
              assetPath: 'assets/icons/home.svg',
              selected: false,
            ),
            selectedIcon: _NavigationIcon(
              assetPath: 'assets/icons/home.svg',
              selected: true,
            ),
            label: '홈',
          ),
          NavigationDestination(
            icon: _NavigationIcon(
              assetPath: 'assets/icons/movie.svg',
              selected: false,
            ),
            selectedIcon: _NavigationIcon(
              assetPath: 'assets/icons/movie.svg',
              selected: true,
            ),
            label: '영화',
          ),
          NavigationDestination(
            icon: _NavigationIcon(
              assetPath: 'assets/icons/person.svg',
              selected: false,
            ),
            selectedIcon: _NavigationIcon(
              assetPath: 'assets/icons/person.svg',
              selected: true,
            ),
            label: '마이',
          ),
        ],
      ),
    );
  }
}

class _NavigationIcon extends StatelessWidget {
  const _NavigationIcon({required this.assetPath, required this.selected});

  final String assetPath;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: 20,
      height: 20,
      colorFilter: ColorFilter.mode(
        selected ? AppColors.onPrimaryContainer : AppColors.onSurfaceVariant,
        BlendMode.srcIn,
      ),
    );
  }
}
