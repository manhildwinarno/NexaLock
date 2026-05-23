import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/realtime_db_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_avatar.dart';

class ProfileHeader extends StatelessWidget {
  final UserModel user;
  final VoidCallback onEdit;

  const ProfileHeader({required this.user, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomAvatar(
          name: user.name,
          size: 96,
          fontSize: 32,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              user.name,
              style: const TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded, size: 20),
              color: AppTheme.outline,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 20,
              tooltip: 'Edit Name',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: user.isAdmin 
                ? AppTheme.primaryDark.withValues(alpha: 0.1) 
                : AppTheme.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                user.isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                size: 16,
                color: user.isAdmin ? AppTheme.primaryDark : AppTheme.secondary,
              ),
              const SizedBox(width: 6),
              Text(
                user.role.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: user.isAdmin ? AppTheme.primaryDark : AppTheme.secondary,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
