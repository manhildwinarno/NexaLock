import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomAvatar extends StatelessWidget {
  final String name;
  final double size;
  final double fontSize;

  const CustomAvatar({
    super.key,
    required this.name,
    this.size = 40,
    this.fontSize = 16,
  });

  String _getInitials(String name) {
    if (name.isEmpty) return '??';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.primaryDark,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.secondary.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        _getInitials(name),
        style: TextStyle(
          fontFamily: 'Hanken Grotesk',
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: AppTheme.secondary,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
