import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/realtime_db_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_avatar.dart';

class PreferenceSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isActive;
  final ValueChanged<bool> onChanged;
  final bool hasBorder;

  const PreferenceSwitchTile({
    required this.icon,
    required this.title,
    required this.isActive,
    required this.onChanged,
    required this.hasBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        border: hasBorder
            ? Border(
                bottom: BorderSide(
                  color: AppTheme.surfaceContainer,
                  width: 1,
                ),
              )
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.onSurfaceVariant, size: 22),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.onSurface,
                ),
              ),
            ],
          ),
          Switch(
            value: isActive,
            onChanged: onChanged,
            activeThumbColor: AppTheme.secondary,
            activeTrackColor: AppTheme.secondary.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}
