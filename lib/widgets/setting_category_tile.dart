import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../main.dart';

class SettingCategoryTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool hasBorder;
  final VoidCallback onTap;

  const SettingCategoryTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.hasBorder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        highlightColor: AppTheme.surfaceContainer,
        splashColor: AppTheme.surfaceContainerLow,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: hasBorder
                ? Border(
                    bottom: BorderSide(
                      color: AppTheme.outlineVariant.withValues(alpha: 0.2),
                    ),
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppTheme.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.onSurfaceVariant.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.outlineVariant,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
