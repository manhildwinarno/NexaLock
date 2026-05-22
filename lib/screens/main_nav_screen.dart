import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'users_screen.dart';
import 'profile_screen.dart';

class MainNavScreen extends StatefulWidget {
  final UserModel user;

  const MainNavScreen({super.key, required this.user});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens;
    final List<Map<String, dynamic>> navItems;

    if (widget.user.isAdmin) {
      screens = [
        HomeScreen(user: widget.user),
        HistoryScreen(user: widget.user),
        const UsersScreen(),
        ProfileScreen(user: widget.user),
      ];
      navItems = [
        {'icon': Icons.home_outlined, 'activeIcon': Icons.home, 'label': 'Home'},
        {'icon': Icons.history_outlined, 'activeIcon': Icons.history, 'label': 'History'},
        {'icon': Icons.people_outline, 'activeIcon': Icons.people, 'label': 'Users'},
        {'icon': Icons.person_outline, 'activeIcon': Icons.person, 'label': 'Profile'},
      ];
    } else {
      screens = [
        HomeScreen(user: widget.user),
        HistoryScreen(user: widget.user),
        ProfileScreen(user: widget.user),
      ];
      navItems = [
        {'icon': Icons.home_outlined, 'activeIcon': Icons.home, 'label': 'Home'},
        {'icon': Icons.history_outlined, 'activeIcon': Icons.history, 'label': 'History'},
        {'icon': Icons.person_outline, 'activeIcon': Icons.person, 'label': 'Profile'},
      ];
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(bottom: 16, top: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          border: Border(
            top: BorderSide(
              color: AppTheme.outlineVariant.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF001A41).withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(navItems.length, (index) {
              final item = navItems[index];
              return _NavItem(
                icon: item['icon'] as IconData,
                activeIcon: item['activeIcon'] as IconData,
                label: item['label'] as String,
                isSelected: _selectedIndex == index,
                onTap: () => _onItemTapped(index),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isSelected ? AppTheme.secondaryContainer : AppTheme.outline;
    final icon = widget.isSelected ? widget.activeIcon : widget.icon;
    
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: AppTheme.durationFast,
        curve: AppTheme.curveStandard,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: AppTheme.durationFast,
              curve: AppTheme.curveStandard,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              decoration: BoxDecoration(
                color: widget.isSelected ? const Color(0xFFE0F7FA) : Colors.transparent,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
