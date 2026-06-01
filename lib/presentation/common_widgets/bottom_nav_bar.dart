import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  static const List<_NavItem> _items = [
    _NavItem(label: 'Beranda', icon: Icons.home_outlined, activeIcon: Icons.home, path: '/home'),
    _NavItem(label: 'Kabar', icon: Icons.article_outlined, activeIcon: Icons.article, path: '/stream'),
    _NavItem(label: 'Bincang', icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, path: '/talk'),
    _NavItem(label: 'Peringkat', icon: Icons.leaderboard_outlined, activeIcon: Icons.leaderboard, path: '/leaderboard'),
    _NavItem(label: 'Profil', icon: Icons.person_outline, activeIcon: Icons.person, path: '/profile'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    for (int i = 0; i < _items.length; i++) {
      if (location.startsWith(_items[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE5E5E5))),
        ),
        child: BottomNavigationBar(
          currentIndex: index,
          onTap: (i) => context.go(_items[i].path),
          items: _items.map((item) => BottomNavigationBarItem(
            icon: Icon(item.icon),
            activeIcon: Icon(item.activeIcon),
            label: item.label,
          )).toList(),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.path,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String path;
}